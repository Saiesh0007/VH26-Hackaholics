# AdaptQ: Domain-Agnostic Adaptive Data Pipeline Platform

> *"Process what matters. Defer what can wait. Synthesize policies with AI; process at wire speed deterministically."*

AdaptQ is an intelligent, high-throughput, **domain-agnostic adaptive data-processing platform** with an AI-powered control plane and a deterministic, ultra-low latency data plane.

---

## 1. What is AdaptQ?

Modern stream architectures break during sudden traffic spikes because they treat every incoming event uniformly or require engineers to manually write custom pipeline logic for every distinct domain (e.g., E-Commerce vs. Hospital Disaster Management vs. University Result Publishing).

**AdaptQ solves this with two foundational innovations:**
1. **Domain-Agnostic Adaptive Engine (Data Plane)**: A single, shared runtime engine capable of processing 20,000+ events/minute with sub-50ms critical latency and a **mathematically verified Zero-Loss Guarantee (0 critical events dropped)**.
2. **Gemini Domain Architect (Control Plane)**: An AI copilot that synthesizes strongly-typed `DomainPolicy` configurations from natural language descriptions, validates them deterministically, and presents them for **explicit human approval** before deployment.

---

## 2. Why the LLM Exists & Why It Is NOT in the Hot Path

### The High-Throughput Fallacy
```
BAD ARCHITECTURE (Do NOT implement):
20,000 events/min  ───►  [ LLM API Call ]  ───►  Classify Every Event  ───►  AdaptQ
Latency: 800ms - 2,500ms per event | Cost: $1,200/hour | Availability: Single point of failure!
```

Putting an LLM directly in the event-processing loop kills throughput, introduces massive non-deterministic latencies, balloons costs, and makes system availability dependent on third-party cloud uptime.

### The Solution: Control Plane vs. Data Plane Separation

```
                    CONTROL PLANE (Low Frequency / High Context)
  Flutter UI ──► Describe Domain ──► Gemini AI ──► Structured DomainPolicy ──► Policy Validator ──► Human Approval ──► Activate
                                                                                                                          │
══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╪══════
                    DATA PLANE (High Frequency / Ultra-Low Latency / 20k+ e/min)                                           │
  Event Ingestion ──► Classification ──► AdaptQ Decision Engine ◄────────────────────────────────────────────────────────┘
                                               │
                         ┌─────────────────────┼─────────────────────┬─────────────────────┐
                         ▼                     ▼                     ▼                     ▼
                      STREAM              MICRO-BATCH              DEFER                 SHED
                     (P0 Critical)         (P1 / P2)             (P2 Queue)            (P3 Logs)
                         │                     │                     │                     │
                         └─────────────────────┴──────────┬──────────┴─────────────────────┘
                                                          ▼
                                                    Worker Pool (1-16)
                                                          ▼
                                                   Sink & Telemetry
                                                          ▼
                                              Flutter Live Control Center
```

- **Control Plane**: Gemini runs exclusively on policy generation, AI Copilot Q&A, explainability reasoning, and scenario simulations.
- **Data Plane**: Operates at 20,000+ events/min completely decoupled from LLMs. If Gemini is down or the network is severed, **AdaptQ continues processing with 100% throughput and zero data plane dependency**.

---

## 3. Structured DomainPolicy Architecture

Every pipeline configuration is governed by a strictly validated, strongly-typed schema:

```json
{
  "domainName": "Hospital Disaster Management",
  "description": "Emergency triage during multi-casualty disaster response",
  "eventTypes": [
    {
      "name": "Emergency Patient Alert",
      "priority": "P0",
      "critical": true,
      "slaMs": 100,
      "preferredStrategy": "stream",
      "canDefer": false,
      "canShed": false,
      "retryable": true,
      "idempotencyRequired": true
    },
    {
      "name": "Ambulance Arrival",
      "priority": "P0",
      "critical": true,
      "slaMs": 150,
      "preferredStrategy": "stream",
      "canDefer": false,
      "canShed": false
    },
    {
      "name": "ICU Bed Availability",
      "priority": "P1",
      "critical": false,
      "slaMs": 1500,
      "preferredStrategy": "micro_batch",
      "canDefer": false,
      "canShed": false
    },
    {
      "name": "Routine Reports",
      "priority": "P3",
      "critical": false,
      "slaMs": 30000,
      "preferredStrategy": "batch",
      "canDefer": true,
      "canShed": true,
      "sheddingThreshold": 0.75
    }
  ]
}
```

---

## 4. Deterministic Policy Validator & Human Approval

AI output is **never trusted blindly**. Before any synthesized policy can be applied, it passes through the deterministic `PolicyValidator`:

- **Rule 1 (Zero-Loss Invariant)**: `critical = true` **MUST** have `canShed = false`.
- **Rule 2 (Urgency Invariant)**: `critical = true` **MUST** have `canDefer = false`.
- **Rule 3 (Idempotency Invariant)**: `critical = true` and `retryable = true` **MUST** have `idempotencyRequired = true`.
- **Rule 4 (SLA Invariant)**: `priority = P0` with `slaMs < 500` cannot have `preferredStrategy = batch`.
- **Rule 5 (Shedding Safety)**: Any event with `canShed = true` must specify an explicit `sheddingThreshold > 0.0`.

### Human Approval Gate
The Flutter UI presents a clear review card:
- Displays all event tiers, SLAs, and shedding eligibility.
- Visual badge: `✓ Deterministic Validation: PASSED`.
- `[ EDIT POLICY ]`: Tweak priority, SLA thresholds, or strategies.
- `[ ACCEPT & DEPLOY ]`: Human authorization required to activate the policy in the AdaptQ runtime engine.

---

## 5. Decision Explainability Matrix

Every processing decision is traceable to deterministic telemetry and policy parameters:
- **Event ID & Type** (e.g., `PAY-183821: Payment Capture`)
- **Priority Tier**: `P0 / CRITICAL`
- **Assigned Strategy**: `STREAM`
- **Reasoning Checklist**:
  - `✓ Critical event designated by active DomainPolicy`
  - `✓ SLA remaining: 78ms (strict target: 100ms)`
  - `✓ Queue depth: 4,210; worker load: 84%`
  - `✓ Micro-batch rejected because SLA risk exceeds tolerance`
  - `✓ Shedding prohibited by immutable safety policy`

---

## 6. Predefined Domains Included

1. **🛒 E-Commerce Flash Sale**: Orders, Payments, Inventory Sync, User Clickstreams, Telemetry Logs.
2. **🏥 Hospital Disaster Management**: Emergency Alerts, Ambulance Arrivals, ICU Bed Status, Medical Supplies, Routine Reports.
3. **🎓 University Result Publishing**: Result Lookup, Student Auth, Fee Verification, Score Notifications, System Telemetry.
4. **✨ Custom Domains**: Any domain synthesized via the Gemini Domain Architect.

---

## 7. Security & API Key Management

- **Zero Client Exposure**: The `GEMINI_API_KEY` is **NEVER** stored in Flutter, never passed to the mobile client, and never returned in any REST API response.
- **Server-Side Storage**: Read strictly from backend environment variables:
  ```env
  # backend/.env (Strictly ignored by .gitignore)
  GEMINI_API_KEY=your_gemini_api_key_here
  PORT=8000
  HOST=0.0.0.0
  ```
- **Fallback Guarantee**: If the backend is unavailable or `GEMINI_API_KEY` is omitted, AdaptQ switches to its offline deterministic policy generation and rules engine without crashing.

---

## 8. How to Run the Project

### Prerequisites
- Flutter SDK (3.0.0+)
- Python 3.10+ (for FastAPI backend)

### Step 1: Start the Backend (FastAPI Control Plane)
```bash
cd backend
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```
*Health Check*: `http://localhost:8000/api/v1/health`

### Step 2: Run the Flutter Dashboard
```bash
# In the root project directory (c:\vh)
flutter pub get
flutter run
```

### Step 3: Run All Unit Tests
```bash
# Flutter / Dart tests (37 unit & widget tests)
flutter test

# Backend Python tests (Policy validator & schema tests)
python -m pytest backend/tests
```

---

## 9. 5-Minute Hackathon Demo Script

1. **Baseline Ingestion (1,000 e/min)**:
   - Show the dashboard in stable state.
   - P0 Latency: ~38ms | Critical Events Lost: 0 | Status: STABLE.
2. **Inject 20× Traffic Surge**:
   - Tap `[ 🚨 20× SPIKE ]` (surging to 20,000 events/min).
   - Observe AdaptQ adapting in real-time: P0 payments stay in `STREAM` mode; P2 clicks switch to `MICRO-BATCH`; P3 logs are safely sampled/shed.
   - Highlight: **0 Critical Events Dropped**.
3. **Create a New Pipeline Domain**:
   - Tap `[ ✨ AI Architect ]` or `[ + Create Domain ]`.
   - Select preset: *"Hospital Disaster Response"*.
   - Tap `[ ✨ GENERATE ADAPTIVE POLICY ]`.
   - Observe live AI analysis steps: Domain identified ➔ Event tiers ➔ Safety validation passed.
4. **Review & Human Approval**:
   - Inspect the generated policy card.
   - Tap `[ EDIT POLICY ]` to show human-in-the-loop control.
   - Tap `[ ACCEPT & DEPLOY ]` to activate the Hospital domain into AdaptQ.
5. **Demonstrate Domain Agility**:
   - Dashboard instantly adapts: Event streams now display *"Emergency Patient Alert"*, *"Ambulance Arrival"*, *"ICU Bed Availability"*.
   - Tap any event tile to open the **Decision Explainability Matrix**.
6. **AI Copilot Q&A**:
   - Tap the glowing `[ AI Copilot ]` button.
   - Ask: *"Why are routine reports being shed?"*
   - Copilot answers with structured **FACTS, CURRENT METRICS, POLICY, RECOMMENDATION**.
7. **Time-Travel Benchmark Replay**:
   - Tap `[ ⏪ Replay ]` to compare Naive (FIFO) vs. AdaptQ:
     - Naive: 4,850ms latency, 18.4% dropped, system crashed.
     - AdaptQ: 38.5ms latency, 0 dropped, 100% SLA preserved.
8. **Closing Statement**:
   > *"AdaptQ doesn't need to be rewritten for every domain. It learns the domain policy once, then its deterministic adaptive engine protects what matters under pressure."*
