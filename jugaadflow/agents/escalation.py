import asyncio
import json
import logging
import os
import time
from xml.sax.saxutils import escape as xml_escape

from jugaadflow.agents import get_client, MODEL
from jugaadflow.agents.state import AgentState, capture_snapshot
from jugaadflow.pipeline.thresholds import Thresholds
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.pipeline.queues import Queues
from jugaadflow.metrics.store import Metrics
from jugaadflow.pipeline.decision_engine import LEVEL_NAMES

logger = logging.getLogger("jugaadflow.escalation")

TWILIO_SID = os.environ.get("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH = os.environ.get("TWILIO_AUTH_TOKEN", "")
TWILIO_FROM = os.environ.get("TWILIO_FROM_NUMBER", "")
ALERT_PHONE = os.environ.get("ALERT_PHONE_NUMBER", "")

CALL_PROMPT = """You are a pipeline alert system for JugaadFlow. Generate a brief spoken message (under 30 seconds when read aloud) for a phone call to the on-call operator.

The message must:
1. State that this is a JugaadFlow automated alert
2. Describe the specific problem that triggered the alert
3. Give key metrics (current level, latencies, queue depths, shed counts)
4. Suggest what the operator should do

Be concise and clear — this will be read by text-to-speech over a phone call.

Return ONLY valid JSON:
{"message": "the spoken message text"}"""

STATIC_FALLBACK = (
    "This is a JugaadFlow automated alert. "
    "The pipeline requires human intervention. "
    "{reason}. "
    "Current escalation level is {level}. "
    "Please check the dashboard immediately at localhost port 8000."
)


def _check_triggers(agent_state: AgentState, metrics: Metrics) -> str | None:
    if metrics.shed_count.get("payment", 0) > 0:
        return "CRITICAL: Payment events are being shed. The hard invariant has been violated."

    if agent_state.optimizer_consecutive_failures >= 5:
        return "AI agent LLM is unreachable. 5 or more consecutive failures. The optimizer cannot function."

    if agent_state.consecutive_reverts >= 3:
        return f"AI agents failing repeatedly. {agent_state.consecutive_reverts} consecutive reverts. The optimizer keeps making things worse."

    if metrics.emergency_since > 0 and (time.time() - metrics.emergency_since) >= 60:
        duration = int(time.time() - metrics.emergency_since)
        return f"Pipeline stuck at EMERGENCY level for {duration} seconds. AI agents have not resolved the situation."

    return None


async def _generate_call_message(client, reason: str, metrics: Metrics, queues: Queues) -> str:
    if not client:
        return STATIC_FALLBACK.format(reason=reason, level=LEVEL_NAMES.get(metrics.current_level, "UNKNOWN"))

    snapshot = capture_snapshot(metrics, queues)
    user_msg = json.dumps({
        "trigger_reason": reason,
        "metrics": snapshot.to_dict(),
        "counters": {
            "processed": dict(metrics.processed_count),
            "shed": dict(metrics.shed_count),
            "deferred": dict(metrics.deferred_count),
        },
        "current_level": LEVEL_NAMES.get(metrics.current_level, "UNKNOWN"),
    }, indent=2, default=str)

    try:
        from google.genai import types
        response = await asyncio.wait_for(
            client.aio.models.generate_content(
                model=MODEL,
                contents=user_msg,
                config=types.GenerateContentConfig(
                    system_instruction=CALL_PROMPT,
                    max_output_tokens=512,
                    response_mime_type="application/json",
                ),
            ),
            timeout=10.0,
        )
        result = json.loads(response.text)
        return result.get("message", STATIC_FALLBACK.format(reason=reason, level=LEVEL_NAMES.get(metrics.current_level, "UNKNOWN")))
    except Exception as e:
        logger.warning("Failed to generate call message via LLM: %s", e)
        return STATIC_FALLBACK.format(reason=reason, level=LEVEL_NAMES.get(metrics.current_level, "UNKNOWN"))


def _make_twilio_call(message: str):
    from twilio.rest import Client
    client = Client(TWILIO_SID, TWILIO_AUTH)
    safe_msg = xml_escape(message)
    twiml = f'<Response><Say voice="Polly.Amy">{safe_msg}</Say></Response>'
    call = client.calls.create(
        twiml=twiml,
        to=ALERT_PHONE,
        from_=TWILIO_FROM,
    )
    return call.sid


def _log_action(agent_state: AgentState, action: str, summary: str):
    ts = time.strftime("%H:%M:%S", time.localtime())
    entry = {
        "time": ts,
        "agent": "escalation",
        "action": action,
        "summary": summary,
        "confidence": None,
        "verdict": None,
        "details": {},
    }
    agent_state.recent_actions.appendleft(entry)


async def escalation_monitor_loop(
    thresholds: Thresholds,
    strategy: Strategy,
    queues: Queues,
    metrics: Metrics,
    agent_state: AgentState,
    poll_interval: float = 5.0,
):
    if not all([TWILIO_SID, TWILIO_AUTH, TWILIO_FROM, ALERT_PHONE]):
        logger.warning("Twilio credentials incomplete — escalation monitor disabled")
        return

    llm_client = get_client()
    logger.info("Escalation monitor starting (poll=%ds, startup delay=30s)", poll_interval)
    await asyncio.sleep(30.0)

    while True:
        await asyncio.sleep(poll_interval)

        if not agent_state.agents_enabled:
            continue

        if agent_state.human_alert_active:
            continue

        if time.time() - agent_state.last_alert_at < agent_state.alert_cooldown:
            continue

        reason = _check_triggers(agent_state, metrics)
        if reason is None:
            continue

        logger.warning("HUMAN ESCALATION TRIGGERED: %s", reason)
        agent_state.alert_reason = reason

        message = await _generate_call_message(llm_client, reason, metrics, queues)
        logger.info("Call message: %s", message[:200])

        try:
            call_sid = await asyncio.to_thread(_make_twilio_call, message)
            logger.info("Twilio call initiated: %s", call_sid)
            _log_action(agent_state, "human_call", f"Called operator: {reason[:100]}")
        except Exception as e:
            logger.error("Twilio call failed: %s", e)
            _log_action(agent_state, "call_failed", f"Call failed ({e}): {reason[:100]}")

        agent_state.human_alert_active = True
        agent_state.last_alert_at = time.time()
