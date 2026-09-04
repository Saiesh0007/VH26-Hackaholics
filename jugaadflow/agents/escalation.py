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
TWILIO_API_KEY = os.environ.get("TWILIO_API_KEY_SID", "")
TWILIO_API_SECRET = os.environ.get("TWILIO_API_KEY_SECRET", "")
TWILIO_FROM = os.environ.get("TWILIO_FROM_NUMBER", "")
ALERT_PHONE = os.environ.get("ALERT_PHONE_NUMBER", "")

CALL_PROMPT = """You are a pipeline alert system for JugaadFlow. Generate a brief spoken message (under 30 seconds when read aloud) for a phone call to the on-call operator.

The message must:
1. State that this is a JugaadFlow automated alert
2. Describe the specific problem that triggered the alert
3. Give key metrics (current level, latencies, queue depths, shed counts)
4. Suggest what the operator should do
5. End by asking "What would you like me to do?"

Be concise and clear — this will be read by text-to-speech over a phone call.

Return ONLY valid JSON:
{"message": "the spoken message text"}"""

CONVERSATION_PROMPT = """You are JugaadFlow's AI operations assistant, currently on a live phone call with the on-call admin. You are having a back-and-forth troubleshooting conversation.

You called because: {reason}

Current pipeline state:
{metrics}

Rules for this conversation:
- This is a live phone call — keep each reply to 2-3 sentences max
- Have a real conversation: listen to the admin's suggestions, discuss trade-offs, ask clarifying questions
- When the admin asks about metrics or system state, give specific numbers from the data above
- When the admin suggests a fix (e.g. "shed tier 4", "increase workers", "lower thresholds"), discuss it — confirm you understand, explain what effect it would have, ask if they want to proceed
- When the admin asks you to do something, confirm and explain what you will do
- Ask follow-up questions to keep the conversation going — "Would you also like me to...", "Should I also check...", "What about the deferred queues?"
- NEVER end the call on your own. Only set end_call to true if the admin explicitly says "goodbye", "hang up", "end call", "that's all", or similar
- If you are unsure what the admin said, ask them to repeat

Return ONLY valid JSON:
{{"reply": "your spoken response", "end_call": false}}
Set end_call to true ONLY when the admin explicitly asks to end the call."""

STATIC_FALLBACK = (
    "This is a JugaadFlow automated alert. "
    "The pipeline requires human intervention. "
    "{reason}. "
    "Current escalation level is {level}. "
    "Please check the dashboard immediately at localhost port 8000."
)

_ngrok_url: str | None = None


def _get_public_url() -> str:
    global _ngrok_url
    if _ngrok_url:
        return _ngrok_url

    # Patch pyngrok's installer to skip SSL verification (expired CDN cert workaround)
    try:
        import ssl
        import urllib.request
        from pyngrok import installer as _pyngrok_installer
        _orig_urlretrieve = getattr(_pyngrok_installer, "_urlretrieve", None)
        _ctx = ssl.create_default_context()
        _ctx.check_hostname = False
        _ctx.verify_mode = ssl.CERT_NONE

        def _ssl_urlretrieve(url, path, *args, **kwargs):
            with urllib.request.urlopen(url, context=_ctx) as response:
                with open(path, "wb") as f:
                    f.write(response.read())
            return path, {}

        _pyngrok_installer._urlretrieve = _ssl_urlretrieve
    except Exception as patch_err:
        logger.warning("Could not patch pyngrok SSL: %s", patch_err)

    from pyngrok import ngrok
    # Kill any stale tunnels from previous runs
    try:
        for t in ngrok.get_tunnels():
            ngrok.disconnect(t.public_url)
    except Exception:
        pass

    try:
        tunnel = ngrok.connect(8000)
    except Exception as e1:
        logger.warning("ngrok first attempt failed: %s — retrying after kill", e1)
        try:
            ngrok.kill()
            tunnel = ngrok.connect(8000)
        except Exception as e2:
            logger.error("ngrok failed to start: %s — falling back to localhost URL", e2)
            _ngrok_url = "http://localhost:8000"
            return _ngrok_url

    url = tunnel.public_url
    if url.startswith("http://"):
        url = "https://" + url[7:]
    _ngrok_url = url
    logger.info("ngrok tunnel opened: %s", url)
    return _ngrok_url


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
        def _call():
            return client.models.generate_content(
                model=MODEL,
                contents=user_msg,
                config=types.GenerateContentConfig(
                    system_instruction=CALL_PROMPT,
                    max_output_tokens=512,
                    response_mime_type="application/json",
                ),
            )
        response = await asyncio.wait_for(asyncio.to_thread(_call), timeout=15.0)
        result = json.loads(response.text)
        return result.get("message", STATIC_FALLBACK.format(reason=reason, level=LEVEL_NAMES.get(metrics.current_level, "UNKNOWN")))
    except Exception as e:
        logger.warning("Failed to generate call message via LLM: %s", e)
        return STATIC_FALLBACK.format(reason=reason, level=LEVEL_NAMES.get(metrics.current_level, "UNKNOWN"))


pending_call_message: str = ""
pending_call_reason: str = ""

_call_conversations: dict[str, list[dict]] = {}


def init_call_conversation(call_sid: str, opening_message: str, reason: str):
    _call_conversations[call_sid] = [
        {"role": "model", "text": opening_message},
    ]
    import jugaadflow.agents.escalation as _self
    _self.pending_call_reason = reason


def cleanup_call(call_sid: str):
    _call_conversations.pop(call_sid, None)


async def generate_conversation_reply(
    call_sid: str, admin_speech: str, metrics: Metrics, queues: Queues,
) -> tuple[str, bool]:
    history = _call_conversations.get(call_sid, [])
    history.append({"role": "user", "text": admin_speech})

    client = get_client()
    if not client:
        reply = "I'm sorry, I'm having trouble connecting to my language model. Please check the dashboard directly."
        history.append({"role": "model", "text": reply})
        return reply, False

    snapshot = capture_snapshot(metrics, queues)
    metrics_str = json.dumps({
        "counters": {
            "processed": dict(metrics.processed_count),
            "shed": dict(metrics.shed_count),
            "deferred": dict(metrics.deferred_count),
        },
        "current_level": LEVEL_NAMES.get(metrics.current_level, "UNKNOWN"),
        "queue_depths": snapshot.to_dict(),
    }, indent=2, default=str)

    prompt = CONVERSATION_PROMPT.format(
        reason=pending_call_reason or "Pipeline alert",
        metrics=metrics_str,
    )

    contents = []
    for msg in history:
        contents.append({"role": msg["role"], "parts": [{"text": msg["text"]}]})

    try:
        from google.genai import types
        def _call():
            return client.models.generate_content(
                model=MODEL,
                contents=contents,
                config=types.GenerateContentConfig(
                    system_instruction=prompt,
                    max_output_tokens=256,
                    response_mime_type="application/json",
                ),
            )
        response = await asyncio.wait_for(asyncio.to_thread(_call), timeout=15.0)
        result = json.loads(response.text)
        reply = result.get("reply", "I didn't catch that. Could you repeat?")
        end_call = result.get("end_call", False)
    except Exception as e:
        logger.warning("Conversation LLM call failed: %s", e)
        reply = "I'm having trouble processing that. Could you repeat?"
        end_call = False

    history.append({"role": "model", "text": reply})
    _call_conversations[call_sid] = history
    return reply, end_call


def _make_twilio_call(message: str):
    import jugaadflow.agents.escalation as _self
    _self.pending_call_message = message

    public_url = _get_public_url()
    twiml_url = f"{public_url}/api/twiml/alert"

    from twilio.rest import Client
    client = Client(TWILIO_API_KEY, TWILIO_API_SECRET, TWILIO_SID)
    call = client.calls.create(
        url=twiml_url,
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
    if not all([TWILIO_SID, TWILIO_API_KEY, TWILIO_API_SECRET, TWILIO_FROM, ALERT_PHONE]):
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
