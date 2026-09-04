# AdaptQ: Adaptive AI Data Pipeline Command Center

> *"Process what matters. Defer what can wait."*

AdaptQ is a production-style Flutter command center for an autonomous, AI-managed data pipeline capable of surviving a **20× traffic surge** (1,000 → 20,000+ events/min) without dropping critical P0 workloads (Payments and Orders).

---

## Architecture Overview

```
                    FLUTTER MOBILE APP
                           │
               ┌───────────┼────────────┐
               │           │            │
               ▼           ▼            ▼
          Dashboard     Events      What-If
                        Assistant    Simulator
               │           │            │
               └───────────┼────────────┘
                           │
                    Repository Layer
                           │
              ┌────────────┴─────────────┐
              │                          │
              ▼                          ▼
      MockPipelineRepository     ApiPipelineRepository
              │                          │
              ▼                          ▼
      Local Simulation Engine       Future FastAPI
              │                          │
              └────────────┬─────────────┘
                           │
                           ▼
                    FLOWMIND AGENT
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           OBSERVE       REASON        ACT
              │            │            │
              └────────────┼────────────┘
                           ▼
                     SAFETY GUARD
                           │
                           ▼
                   PIPELINE RUNTIME
                           │
       ┌───────────┬───────┼─────────┬──────────┐
       ▼           ▼       ▼         ▼          ▼
      P0          P1      P2        P3       Workers
   Critical     High    Normal     Low
       │           │       │         │
       └───────────┴───────┴─────────┘
                           │
                           ▼
                        METRICS
                           │
                           └──────→ FLOWMIND
```

---

## Key Features

1. **Autonomous FlowMind AI Control Loop**:
   - Continuously runs `Observe → Analyze → Reason → Propose → Safety Validate → Execute → Verify → Adjust` cycle.
   - Dynamically adapts processing policies (`STREAM`, `BATCH`, `DEFER`, `SHED`) based on live metric feedback.
2. **Immutable SafetyGuard Protection**:
   - Guarantees **P0 Payment** and **P0 Order** events are **NEVER shed or lost**.
   - Rejects policy proposals violating max batch sizes, deferral windows, or critical event protection.
3. **Repository-Driven & API-First Architecture**:
   - Abstract `PipelineRepository` interface with `MockPipelineRepository` and future `ApiPipelineRepository`.
   - Seamlessly switch backend sources without altering UI components.
4. **Command Center Observability**:
   - Real-time event ingestion counter (1,000 → 20,000 events/min).
   - Animated hero counters, telemetry grid, and Critical Event Shield widget.
   - Priority Queue cards for P0 Critical, P1 High, P2 Normal, and P3 Low.
5. **Interactive Hackathon Presentation Tools**:
   - **🔥 20× Spike** and **🟢 Recover** CTA buttons.
   - **What-If Simulator**: Scenario testing sliders for traffic rate, worker pool count, and batch sizes.
   - **Naive vs. Adaptive Benchmark**: Side-by-side performance metrics comparison.
   - **Five-tab navigation**: Dashboard, Events, FlowMind, Pipeline, and Analytics.

---

## Getting Started & Running Tests

### Prerequisites
- Flutter SDK 3.0+ installed
- Dart SDK 3.0+ installed

### Running the App
```bash
flutter run
```

### Running Unit Tests
```bash
flutter test
```

### ⚡ Interactive Terminal Live Demo (Pitch & Presentation Mode)
Run the real-time ANSI terminal demonstration showcasing the 20× surge attack, FlowMind AI reasoning, SafetyGuard invariant validation, and benchmark scorecard:

**On Windows (PowerShell):**
```powershell
.\scripts\demo.ps1
```

**On Linux / macOS / Git Bash:**
```bash
chmod +x scripts/demo.sh
./scripts/demo.sh
```

**Or directly via Dart:**
```bash
dart run scripts/demo.dart
```

---

## Future Integration Roadmap

- **FastAPI Backend**: Implement REST endpoints (`/metrics`, `/queues`, `/events`, `/agent/policy`) inside `ApiPipelineRepository`.
- **WebSocket Streaming**: Connect `WebSocketPipelineRealtimeService` to `/ws/metrics` and `/ws/events`.
- **External LLM Agent**: Connect `FlowMindAgent` to a remote backend control plane LLM service.
