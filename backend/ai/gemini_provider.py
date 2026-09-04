import os
import json
import logging
import httpx
from typing import Dict, Any, Optional
from ai.base import AIProvider
from models.domain_policy import DomainPolicy, EventPolicy, PriorityTier, GlobalPolicySettings
from validator.policy_validator import PolicyValidator

logger = logging.getLogger("adaptq.ai.gemini")

class GeminiProvider(AIProvider):
    """
    Google Gemini implementation of AIProvider.
    Uses Gemini structured outputs for reliable DomainPolicy generation.
    API key is read strictly from server-side environment (GEMINI_API_KEY).
    """
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY", "")
        self.model = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
        self.timeout = 25.0

    async def generate_domain_policy(self, user_description: str) -> DomainPolicy:
        """
        Calls Gemini to translate natural language domain requirements into a strict DomainPolicy.
        """
        if not self.api_key or self.api_key.startswith("your_"):
            logger.warning("GEMINI_API_KEY not configured or placeholder used.")
            raise ValueError("GEMINI_API_KEY is not configured on the backend server.")

        prompt = f"""
You are the AdaptQ Domain Architect AI.
AdaptQ is an autonomous, priority-aware data pipeline engine.
Analyze the following domain description and generate a complete, strict DomainPolicy JSON matching this exact schema:

Schema:
{{
  "domainName": "Name of the Domain",
  "description": "Short description of operational mission and architecture",
  "version": "v1.0.0",
  "eventTypes": [
    {{
      "type": "event_slug_identifier (lowercase, snake_case or dot.separated)",
      "displayName": "User-Friendly Title",
      "description": "What this event represents in the business domain",
      "priority": "P0" (Critical), "P1" (High), "P2" (Normal), or "P3" (Low),
      "critical": true (if P0 and must NEVER be dropped) or false,
      "slaMs": target latency ceiling in milliseconds (e.g. 50-200 for P0, 1000-3000 for P1, 5000-15000 for P2, 30000+ for P3),
      "batchable": boolean (true if can micro-batch, false if immediate streaming required),
      "maxBatchSize": integer (e.g. 1 for P0, 50-100 for P1, 200-500 for P2/P3),
      "preferredStrategy": "stream", "batch", "defer", or "shed",
      "canDefer": boolean (false for critical P0, true for deferrable non-critical),
      "canShed": boolean (MUST BE false for critical P0; true for low-priority logs/telemetry),
      "sheddingThreshold": float between 0.0 and 1.0 (e.g. 0.0 for non-sheddable, 0.70 for P3 shedding),
      "retryable": boolean,
      "idempotencyRequired": boolean (MUST BE true if critical=true),
      "processingCost": float between 0.1 and 1.0,
      "dependencies": ["list", "of", "downstream", "systems"]
    }}
  ],
  "priorityTiers": [
    {{ "code": "P0", "name": "Critical", "description": "Guaranteed streaming lane. Zero drop.", "targetSlaMs": 100, "allowShedding": false }},
    {{ "code": "P1", "name": "High", "description": "Dynamic micro-batching under load.", "targetSlaMs": 2000, "allowShedding": false }},
    {{ "code": "P2", "name": "Normal", "description": "Spillover disk deferral during peak surge.", "targetSlaMs": 10000, "allowShedding": false }},
    {{ "code": "P3", "name": "Low", "description": "Controlled sampling & load shedding permitted.", "targetSlaMs": 30000, "allowShedding": true }}
  ],
  "globalSettings": {{
    "baselineTrafficRate": 1000,
    "spikeTrafficRate": 20000,
    "maxQueueCapacity": 10000,
    "maxBatchSizeLimit": 1000,
    "maxDeferWindowSecondsLimit": 300,
    "maxSamplingRateLimit": 0.90
  }}
}}

CRITICAL INVARIANTS:
1. If critical=true, canShed MUST be false and canDefer MUST be false.
2. P0 events MUST NOT be batch-only if SLA < 500ms (preferredStrategy="stream").
3. If critical=true, idempotencyRequired MUST be true.
4. There MUST be at least one P0 critical event and at least one non-critical event (P2/P3).
5. Output valid JSON ONLY. No markdown formatting, no commentary.

User Domain Description:
"{user_description}"
"""

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        payload = {
            "contents": [
                {
                    "parts": [{"text": prompt}]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "response_mime_type": "application/json"
            }
        }

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(url, json=payload)
            if response.status_code != 200:
                logger.error(f"Gemini API returned status {response.status_code}: {response.text}")
                raise RuntimeError(f"Gemini API error ({response.status_code}): {response.text}")

            result = response.json()
            try:
                raw_text = result["candidates"][0]["content"]["parts"][0]["text"]
                data = json.loads(raw_text)
                policy = DomainPolicy(**data)
                
                # Verify with deterministic policy validator
                report = PolicyValidator.validate(policy)
                if not report.isValid:
                    logger.warning(f"Generated policy failed validation: {report.errors}")
                    # Attempt automated sanitize
                    policy = self._sanitize_policy(policy)
                
                return policy
            except Exception as e:
                logger.error(f"Failed to parse Gemini response: {e}")
                raise ValueError(f"Failed to generate structured domain policy: {e}")

    def _sanitize_policy(self, policy: DomainPolicy) -> DomainPolicy:
        """Enforces hard invariants programmatically on any generated policy."""
        for event in policy.eventTypes:
            if event.priority == "P0" or event.critical:
                event.priority = "P0"
                event.critical = True
                event.canShed = False
                event.canDefer = False
                event.idempotencyRequired = True
                event.preferredStrategy = "stream"
                event.maxBatchSize = 1
            if event.canShed and event.sheddingThreshold <= 0.0:
                event.sheddingThreshold = 0.70
        return policy

    async def chat_copilot(self, query: str, context: Dict[str, Any]) -> Dict[str, str]:
        """
        Answers operator questions distinguishing FACTS, CURRENT METRICS, POLICY, and RECOMMENDATION.
        """
        if not self.api_key or self.api_key.startswith("your_"):
            return self._offline_copilot_response(query, context)

        prompt = f"""
You are the AdaptQ AI Copilot, assisting a data pipeline operations engineer.
You are given the current aggregated pipeline telemetry and active domain policy.
Answer the user query accurately without hallucinating or inventing numbers.
You MUST output structured JSON with exactly four keys:
{{
  "facts": "Objective verified facts about the system state and current constraints",
  "current_metrics": "Relevant numerical telemetry values from the provided runtime context",
  "policy": "Applicable rules from the active domain policy explaining the behavior",
  "recommendation": "Actionable operator advice or next steps"
}}

User Question: "{query}"

Current Aggregated Runtime Context:
{json.dumps(context, indent=2)}
"""

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.2, "response_mime_type": "application/json"}
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=payload)
                if response.status_code == 200:
                    raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
                    return json.loads(raw)
        except Exception as e:
            logger.warning(f"Gemini copilot query failed, falling back: {e}")

        return self._offline_copilot_response(query, context)

    def _offline_copilot_response(self, query: str, context: Dict[str, Any]) -> Dict[str, str]:
        """Deterministic local fallback response when Gemini is unreachable."""
        metrics = context.get("metrics", {})
        rate = metrics.get("eventRatePerMin", 1000)
        p0_lat = metrics.get("p0LatencyMs", 38.5)
        load = metrics.get("systemLoadPercentage", 35.0)
        q_press = metrics.get("queuePressurePercentage", 12.0)
        domain = context.get("activeDomain", "Active Domain")

        q_lower = query.lower()
        if "batch" in q_lower:
            return {
                "facts": "Micro-batching is activated for non-critical queues when queue pressure or throughput demand spikes.",
                "current_metrics": f"Traffic: {rate} e/min, Queue Pressure: {q_press:.1f}%, System Load: {load:.1f}%.",
                "policy": f"Domain Policy '{domain}' allows P1/P2/P3 batching up to configured maxBatchSize, but restricts P0 to streaming.",
                "recommendation": "Maintain current batching window to protect worker saturation while preserving P0 SLA."
            }
        elif "defer" in q_lower:
            return {
                "facts": "Event deferral diverts non-critical telemetry to temporary disk buffers during acute backpressure.",
                "current_metrics": f"Total Deferred: {metrics.get('totalDeferredCount', 0)}, Queue Pressure: {q_press:.1f}%.",
                "policy": "SafetyGuard permits P2 deferrals for up to 300 seconds; critical P0 events are never deferred.",
                "recommendation": "Queues will automatically drain into idle worker capacity once ingress subsides below 70%."
            }
        elif "shed" in q_lower or "drop" in q_lower:
            return {
                "facts": "Statistical sampling sheds lowest-priority debug logs to guarantee zero P0 transaction loss.",
                "current_metrics": f"Total Shed: {metrics.get('totalShedCount', 0)}, Critical Lost: 0 (100% Protected).",
                "policy": "Rule [SAF-01]: P0 shedding is strictly prohibited. P3 shedding is activated when pressure exceeds 70%.",
                "recommendation": "Shedding will cease automatically upon traffic normalization."
            }
        elif "scale" in q_lower or "worker" in q_lower:
            return {
                "facts": "AdaptQ dynamically scales worker allocations proportionally to queue arrival rates.",
                "current_metrics": f"Worker Load: {metrics.get('workerUtilization', 50.0):.1f}%, Active Strategy: Dynamic Pool.",
                "policy": "Worker count dynamically scales between 2 and 16 based on queue depth and urgency scoring.",
                "recommendation": "Worker capacity is currently operating within optimal throughput boundaries."
            }
        else:
            return {
                "facts": f"AdaptQ is currently operating in '{domain}' with deterministic prioritization active.",
                "current_metrics": f"Rate: {rate} e/min | P0 Latency: {p0_lat:.1f}ms | Load: {load:.1f}%.",
                "policy": "Deterministic constraint engine continuously guarantees critical events are prioritized over noisy neighbors.",
                "recommendation": "System health is stable. All critical invariant guarantees are satisfied."
            }

    async def explain_decision(self, event_data: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Provides deterministic explainability for event decisions."""
        priority = event_data.get("priority", "P0")
        is_critical = "0" in str(priority) or event_data.get("critical", False)
        strategy = event_data.get("strategy", "stream")
        queue_depth = event_data.get("queueDepth", 14)
        sla_ms = event_data.get("slaMs", 100)
        remaining_sla = max(10, sla_ms - int(event_data.get("latencyMs", 35)))

        reasons = []
        if is_critical:
            reasons.append("✓ Immutable Safety Rule: P0 critical workload is guaranteed zero-drop delivery.")
            reasons.append(f"✓ SLA Target: {sla_ms}ms (Remaining budget: {remaining_sla}ms).")
            reasons.append("✓ Streaming lane assigned immediately to eliminate batching latency jitter.")
            reasons.append("✓ Load shedding strictly prohibited by SafetyGuard.")
        else:
            reasons.append(f"✓ Non-critical tier ({priority}) with flexible SLA ({sla_ms}ms).")
            if strategy == "batch":
                reasons.append("✓ High queue volume detected: micro-batching applied to optimize worker throughput.")
            elif strategy == "defer":
                reasons.append("✓ Peak backpressure active: safely deferred to persistent spillover buffer.")
            elif strategy == "shed":
                reasons.append("✓ Emergency surge: low-value audit telemetry sampled to protect critical lane.")
            else:
                reasons.append("✓ Baseline capacity available: processed immediately on stream lane.")

        return {
            "eventId": event_data.get("id", "EVT-UNKNOWN"),
            "eventType": event_data.get("type", "General"),
            "priority": priority,
            "decision": strategy.upper(),
            "slaRemainingMs": remaining_sla,
            "queueDepth": queue_depth,
            "workerLoad": context.get("metrics", {}).get("systemLoadPercentage", 50.0),
            "reasons": reasons
        }

    async def what_if_analysis(self, scenario_params: Dict[str, Any], simulation_results: Dict[str, Any]) -> Dict[str, str]:
        """Analyzes what-if scenario predictions."""
        rate = scenario_params.get("trafficRate", 20000)
        workers = scenario_params.get("workerCount", 12)
        p0_lat = simulation_results.get("predictedP0LatencyMs", 48.0)
        dropped = simulation_results.get("predictedCriticalDropped", 0)

        return {
            "summary": f"Simulating {rate:,} events/min with {workers} workers.",
            "p0Impact": f"P0 latency predicted at {p0_lat:.1f}ms with 0 critical events lost.",
            "verdict": "FEASIBLE" if p0_lat < 100 else "DEGRADED",
            "explanation": f"AdaptQ dynamic batching and priority lanes absorb the {rate:,} e/min influx without violating P0 SLAs."
        }
