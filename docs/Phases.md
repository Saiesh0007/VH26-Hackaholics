# Phases — EventFlow Hackathon Execution Plan

# Phase 0 — Scope Freeze

## Goal

Establish the Adaptive Event Scheduler as the core innovation.

## Completed

- [x] Requirements documented
- [x] CPU-scheduler analogy identified
- [x] Adaptive scheduler adopted as core
- [x] Priority defined
- [x] Fairness defined
- [x] Aging defined
- [x] Starvation prevention defined
- [x] Shell demonstration requirement added
- [x] Architecture defined
- [x] Design defined
- [x] Rules defined
- [x] Memory defined

## Exit Criteria

The team can explain:

```text
Event
 ↓
Kafka
 ↓
Scheduler
 ↓
Worker
 ↓
Result
````

and explain why the scheduler is different from Kafka.

---

# Phase 1 — Repository Foundation

## Goal

Create the development environment.

## Tasks

-  Initialize repository 
-  Create monorepo structure 
-  Configure TypeScript 
-  Configure Docker Compose 
-  Start Kafka 
-  Start PostgreSQL 
-  Configure environment variables 
-  Create shared event schema 

## First Package

```
```

```
packages/event-schema/
```

Define:

```
```

```
Event
Priority
EventStatus
```

and Zod validation.

## Exit Criteria

Infrastructure starts successfully.

Shared event schema compiles and validates sample events.

---

# Phase 2 — End-to-End Pipeline

## Goal

Process one event end-to-end.

```
```

```
API
 ↓
Kafka
 ↓
Scheduler
 ↓
Worker
 ↓
PostgreSQL
```

## Tasks

-  Event validation 
-  Ingestion API 
-  Kafka producer 
-  Scheduler consumer 
-  Basic dispatch 
-  Worker 
-  Database persistence 

## Exit Criteria

A valid event can reach successful completion.

---

# Phase 3 — Scheduler Core

## Goal

Implement the project differentiator.

## Tasks

-  Priority enum 
-  Priority comparison 
-  Scheduler queue 
-  Weighted fairness 
-  Aging 
-  Starvation detection 
-  Starvation prevention 
-  Ordering eligibility 
-  Worker dispatch 
-  Scheduler decision logging 

## Required Tests

```
```

```
Critical beats Normal

High beats Normal

Fairness works

Aging increases effective priority

Low event eventually executes

Same entity remains ordered
```

## Exit Criteria

Scheduler can demonstrate:

```
```

```
priority
+
fairness
+
aging
+
ordering
```

---

# Phase 4 — Reliability

## Goal

Make processing resilient.

## Tasks

-  Idempotency 
-  Retry classification 
-  Backoff 
-  Failure recording 
-  DLQ 
-  DLQ replay 

## Exit Criteria

Demonstrate:

```
```

```
duplicate → suppressed

transient failure → retry

permanent failure → DLQ
```

---

# Phase 5 — Scale and Backpressure

## Goal

Handle workload spikes.

## Tasks

-  Kafka partitions 
-  Multiple workers 
-  Load generator 
-  Queue metrics 
-  Backpressure 
-  Worker adaptation 

## Benchmark

Run:

```
```

```
1K/min
5K/min
10K/min
20K/min
```

Record:

```
```

```
input rate
output rate
backlog
latency
failure count
lost events
worker count
```

## Exit Criteria

20K/min test is reproducible and measured.

---

# Phase 6 — Shell Demonstration

## Goal

Create the required command-line demonstration.

## File

```
```

```
scripts/scheduler-demo.sh
```

## Scenarios

```
```

```
priority
burst
starvation
failure
duplicate
ordering
```

## Exit Criteria

Every scenario runs using one command.

Example:

```
```

```
./scripts/scheduler-demo.sh --scenario starvation
```

---

# Phase 7 — Dashboard

## Goal

Make scheduler behavior visually obvious.

## Display

```
```

```
Arrival rate
Processing rate
Backlog
Workers
Priority queues
Waiting time
Latency
Retries
DLQ
Scheduler decisions
Starvation risk
```

## Exit Criteria

A judge can understand the system within seconds.

---

# Phase 8 — Integrated Chaos Demo

## Goal

Combine all capabilities.

## Demo

```
```

```
Normal traffic
 ↓
Traffic burst
 ↓
Critical events
 ↓
Worker scaling
 ↓
Service failure
 ↓
Retry
 ↓
DLQ
 ↓
Recovery
 ↓
Duplicate
 ↓
Ordering
 ↓
Starvation
 ↓
Aging
```

## Exit Criteria

Full demonstration works from a clean environment.

---

# Phase 9 — Benchmark Evidence

## Goal

Replace claims with measurements.

Create:

```
```

```
benchmark-results.md
```

Example:

| ScenarioInputProcessedLostLatencyWorkers |          |          |          |          |          |
| ---------------------------------------- | -------- | -------- | -------- | -------- | -------- |
| Normal                                   | measured | measured | measured | measured | measured |
| 5K/min                                   | measured | measured | measured | measured | measured |
| 10K/min                                  | measured | measured | measured | measured | measured |
| 20K/min                                  | measured | measured | measured | measured | measured |

Never enter invented numbers.

---

# Phase 10 — Final Demo

## Recommended 5-Minute Story

### 0:00

Problem:

> Not every event is equally important.

### 0:30

Architecture:

```
```

```
Kafka
 ↓
Adaptive Scheduler
 ↓
Workers
```

### 1:00

Priority scheduling.

### 1:30

20K/min burst.

### 2:30

Failure + retry.

### 3:15

DLQ + recovery.

### 4:00

Starvation + aging.

### 4:30

Duplicate + ordering.

### 5:00

Actual benchmark results.

---

# Phase 11 — Submission

Checklist:

-  Clean installation 
-  README 
-  Architecture diagram 
-  Tests passing 
-  Shell demos 
-  Load tests 
-  Dashboard 
-  Chaos scenarios 
-  Benchmark results 
-  Memory.md updated 
-  Presentation 
-  Demo rehearsal 

---

# Priority if Time Runs Out

Build in this order:

```
```

```
1. End-to-end pipeline
2. Scheduler
3. Priority
4. Aging/fairness
5. Reliability
6. 20K/min test
7. Shell demo
8. Dashboard
9. Polish
```

Do NOT sacrifice scheduler correctness for visual polish.

```
```

````

---
