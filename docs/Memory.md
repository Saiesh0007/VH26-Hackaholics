# Memory — EventFlow Context & Roadmap

## Current State

- **Current Phase:** Phase 7 — Dashboard
- **Current Task:** Dashboard implemented; verification pending.

## Architecture

- **Ingestion API:** Fastify + Zod validation
- **Message Broker:** Kafka (Durable Buffer)
- **Database:** PostgreSQL (`processed_events` table)
- **Scheduler:** 
  - Adaptive Effective Priority dispatcher
  - Dynamic Aging: `effectivePriority = basePriority + (waitTimeMs * AGING_RATE)`
  - Prevents starvation deterministically.
- **Worker Pool:** Processes `dispatched-events` with configurable concurrency via Kafka `eachBatch`.
  - **Reliability:** TRANSIENT retry loops with exponential backoff, DLQ routing for PERMANENT/exhausted errors, DUPLICATE suppression.

## Completed Phases

### Phase 1: Repository Foundation
- Initialized monorepo, Docker Compose (Kafka, PostgreSQL).
- Shared `event-schema` with Zod validation.

### Phase 2: End-to-End Pipeline
- Implemented Ingestion API (`POST /events`).
- Kafka Producer & basic Scheduler Consumer.
- Basic worker persisting to PostgreSQL.
- Verified Kafka durability (scheduler restart recovery).

### Phase 3: Scheduler Core
- Implemented Multi-Level Queuing (CRITICAL, HIGH, NORMAL, LOW).
- Tick-based dispatcher (1000ms ticks, Batch=3).
- Verified strict priority and FIFO determinism for equal priorities.

### Phase 4: Fairness, Aging and Starvation Prevention
- Refactored dispatcher to use mathematically rigorous **Effective Priority Algorithm**.
- Replaced static fairness slots with dynamic aging to guarantee both strict initial priority and eventual starvation prevention.
- Implemented structured scheduler decision logging.
- Created `phase4_starvation.test.ts`. 
- **Starvation Verification Result:** LOW event successfully bypassed an endless stream of HIGH events after its Aging Bonus pushed its Effective Priority to 189.4, tying with HIGH events.

### Phase 5: Scale and Backpressure
- Replaced hardcoded Scheduler configurations with `BATCH_SIZE` and `TICK_INTERVAL_MS` ENV vars.
- Implemented `WORKER_CONCURRENCY` in `apps/processor` using Kafka `eachBatch`.
- Created scalable `loadgen.ts` to simulate high throughput.
- Created `benchmark.ts` to orchestrate isolated load tests with automated reporting.
- **Scale Verification:**
  - `1K/min (Workers: 1)`: Perfect ingestion (16/sec) and processing. Backlog: 0.
  - `5K/min (Workers: 1)`: Backpressure demonstrated! Ingestion: 83/sec. Processing: 15/sec. Scheduler safely offloads excess to Kafka `dispatched-events`. Queue backlog grew exactly as expected to protect workers.
  - `10K/min (Workers: 5)`: 166/sec ingestion. Processed 2,246 events rapidly, drained backlog fast after loadgen stopped at peak processing of 135/sec.
  - `20K/min (Workers: 20)`: 333/sec ingestion. Handled load seamlessly, reaching peak processing rates of 361/sec (equivalent to 21.6K/min).

### Phase 6: Shell Demonstration
- Implemented robust reliability layer with ErrorClassification (TRANSIENT, PERMANENT, DUPLICATE).
- Created CLI shell wrapper (`scripts/scheduler-demo.ts`, `.sh`, `.ps1`) to reliably demonstrate all complex scheduling and reliability behaviors.
- **Manual Verification Results (All Scenarios PASSED):**
  - **Priority:** CRITICAL → HIGH → NORMAL → LOW.
  - **Burst:** Approximately 415 events generated at 5000 events/min target over 5 seconds.
  - **Starvation:** LOW event successfully processed during continuous HIGH/CRITICAL load.
  - **Failure:** Permanent failure was recorded and routed to DLQ after 1 attempt.
  - **Retry:** 3 transient failure attempts were recorded and the event ultimately succeeded.
  - **Duplicate/Idempotency:** Processed records: 1, Failure records: 0, DLQ records: 0.
  - **Ordering/FIFO:** Five events for the same entity were processed in their original FIFO order.

### Phase 7: Dashboard
- **Files Created:** 
  - `apps/dashboard/src/App.tsx` (React dashboard UI)
  - `apps/dashboard/tailwind.config.js` & `postcss.config.js`
- **Files Modified:** 
  - `apps/api/src/index.ts`
  - `apps/scheduler/src/index.ts`
  - `apps/api/package.json`
  - `apps/scheduler/package.json`
- **Telemetry Endpoints Added:** 
  - `GET /telemetry/ingestion` (API:3000)
  - `GET /telemetry/db` (API:3000) - cached fast count queries for reliability stats.
  - `GET /telemetry` (Scheduler:3001) - in-memory queues and recent dispatch decisions.
- **Dashboard Components:**
  - Health Status, Throughput Cards (Ingestion, Processed, Backlog, Workers).
  - Priority Queues visualizer (CRITICAL, HIGH, NORMAL, LOW).
  - Recharts line chart for Throughput & Backlog Trends.
  - Recent Scheduler Decisions (Event, Effective Priority, Aging Bonus, Reason).
  - Reliability Counters (Retries, DLQ).
- **Manual Verification Results (PASSED):**
  - Dashboard successfully loads at localhost:5173.
  - API telemetry endpoints respond successfully.
  - Scheduler telemetry endpoint responds successfully.
  - Dashboard receives live telemetry and visibly updates.
  - Burst scenario successfully generated approximately 415 events.
  - Dashboard reflected backend activity during live processing.
  - No Phase 1–6 scheduler/reliability behavior was intentionally changed during verification.
  - Tailwind/PostCSS startup issue was fixed.
  - Fastify/@fastify/cors compatibility issue was fixed.

### Phase 8: Integrated Chaos Demo (Verification Pending)
- **Files Created:**
  - `scripts/chaos-demo.ts`
  - `scripts/chaos-demo.sh`
  - `scripts/chaos-demo.ps1`
- **Implementation Details:**
  - Designed an overarching script to execute 9 sequential scenarios (Baseline, Burst, Priority, Starvation, Transient Failure, Permanent Failure, Duplicate, FIFO, Final State).
  - Ensured reuse of existing scheduler, reliability architecture, and `loadgen.ts` mechanics.
  - Ensured shell wrappers exist for execution on both Windows (PowerShell) and Linux/macOS (Bash).
- **Verification Pending:** The demonstration script needs to be run against a fresh database, and the results visually analyzed in the React dashboard.

## Not Yet Implemented

- Phase 9 — Benchmark Evidence

## Known Issues

- None.

## Next Task

**Phase 9 — Benchmark Evidence**
- Coordinate comprehensive benchmarks using `benchmark.ts`.
- Document peak ingestion rates, worker concurrency scaling behavior, and backpressure tolerances.
