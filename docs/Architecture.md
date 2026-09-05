# Architecture — EventFlow

## 1. Architecture Objective

Build a distributed event-processing system with an explicit:

# Adaptive Event Scheduler

between durable event storage and execution workers.

The scheduler is the core application-level innovation.

Kafka provides durable buffering and transport.

The scheduler decides:

> Which event should execute next?

---

# 2. Fixed Technology Stack

## Frontend

- React
- TypeScript
- Vite
- Tailwind CSS
- Recharts

## Backend

- Node.js
- TypeScript
- Fastify
- Zod

## Event Backbone

- Apache Kafka

## Database

- PostgreSQL

## Infrastructure

- Docker Compose

## Testing

- Vitest
- Integration tests
- Load tests
- Chaos tests

## Optional

Redis may be introduced only if a concrete performance or coordination requirement appears after the core architecture works.

---

# 3. High-Level Architecture

```text
                  EVENT PRODUCERS
              ┌──────────┴──────────┐
              │                     │
        Application API       Shell / Load Generator
              │                     │
              └──────────┬──────────┘
                         ↓
                 ┌───────────────┐
                 │ INGESTION API │
                 │   + Zod       │
                 └───────┬───────┘
                         ↓
                 ┌───────────────┐
                 │     KAFKA     │
                 │ Durable Queue │
                 └───────┬───────┘
                         ↓
             ┌────────────────────────┐
             │ ADAPTIVE EVENT         │
             │       SCHEDULER        │
             │                        │
             │ Priority               │
             │ Fairness               │
             │ Aging                  │
             │ Ordering               │
             │ Backpressure           │
             │ Worker Capacity        │
             └───────────┬────────────┘
                         ↓
                  ┌─────────────┐
                  │ WORKER POOL │
                  │ W1 W2 W3... │
                  └──────┬──────┘
                         ↓
                ┌─────────────────┐
                │ BUSINESS        │
                │ PROCESSOR       │
                └───────┬─────────┘
                        │
              ┌─────────┴─────────┐
              ↓                   ↓
        PostgreSQL              FAILURE
                                │
                        ┌───────┴───────┐
                        ↓               ↓
                      RETRY            DLQ

                         ↓
                  OBSERVABILITY
                         ↓
                    DASHBOARD
````

---

# 4. Responsibility of Each Component

## Ingestion API

Responsibilities:

-  Receive events 
-  Validate payload 
-  Generate/validate event ID 
-  Publish to Kafka 
-  Reject malformed requests 

---

## Kafka

Kafka is:

> Durable event transport and buffering.

Kafka is NOT the application scheduler.

---

## Adaptive Scheduler

The scheduler is:

> The decision-making layer.

It determines:

-  Which event is eligible 
-  Which event has higher effective priority 
-  Whether fairness requires another queue 
-  Whether aging should promote an event 
-  Whether ordering prevents execution 
-  Which worker should receive work 

---

# 5. Scheduler Pipeline

```
```

```
Kafka Event
    ↓
Read Event
    ↓
Validate State
    ↓
Check Ordering
    ↓
Calculate Base Priority
    ↓
Calculate Aging
    ↓
Calculate Effective Priority
    ↓
Apply Fairness
    ↓
Check Worker Capacity
    ↓
Dispatch
    ↓
Record Decision
```

---

# 6. Priority

Initial values:

```
```

```
CRITICAL = 100
HIGH     = 70
NORMAL   = 40
LOW      = 10
```

---

# 7. Effective Priority

Conceptually:

```
```

```
effective_priority =
    base_priority
    + aging_bonus
```

The aging bonus must:

-  increase with waiting time 
-  be bounded 
-  be deterministic 
-  be observable 

---

# 8. Fairness

Initial weights:

```
```

```
CRITICAL = 3
HIGH     = 2
NORMAL   = 1
LOW      = 1
```

The scheduler should balance:

```
```

```
Priority
+
Fairness
+
Aging
```

---

# 9. Ordering

Kafka partition key:

```
```

```
entity_id
```

For events belonging to the same entity:

```
```

```
ORDER_CREATED
      ↓
PAYMENT_SUCCESS
      ↓
ORDER_CONFIRMED
```

must execute in the required sequence.

Independent entities can execute concurrently.

---

# 10. Worker Pool

Workers are execution resources.

Example:

```
```

```
Scheduler
   │
   ├── W1 → Entity A
   ├── W2 → Entity B
   ├── W3 → Entity C
   └── W4 → Entity D
```

Worker state:

```
```

```
IDLE
ACTIVE
BUSY
RETRYING
FAILED
```

---

# 11. Backpressure

Track:

```
```

```
arrival_rate
processing_rate
queue_depth
```

If:

```
```

```
arrival_rate > processing_rate
```

backlog grows.

The system must:

-  use Kafka/durable storage for buffering 
-  avoid unbounded memory queues 
-  expose backlog 
-  increase capacity when appropriate 
-  eventually drain backlog 

---

# 12. Worker Scaling

A basic adaptive rule:

```
```

```
if backlog is continuously growing:
    increase worker capacity

if backlog is stable:
    maintain capacity

if backlog drains:
    stabilize/decrease carefully
```

Avoid rapidly switching:

```
```

```
3 → 10 → 3 → 10 → 3
```

---

# 13. Retry

Initial configuration:

```
```

```
MAX_RETRIES = 3
```

Example:

```
```

```
Attempt 1
    ↓
failure
    ↓
backoff
    ↓
Attempt 2
    ↓
failure
    ↓
backoff
    ↓
Attempt 3
```

---

# 14. Dead Letter Queue

Permanent failures:

```
```

```
event
 ↓
retry
 ↓
retry
 ↓
retry
 ↓
DLQ
```

DLQ must store:

```
```

```
event_id
payload
reason
attempts
created_at
```

DLQ replay must be supported.

---

# 15. Idempotency

Use:

```
```

```
event_id
```

as the logical idempotency key.

Example:

```
```

```
EVT-100

First:
PROCESS → SUCCESS

Second:
DUPLICATE → SKIP
```

The business operation and idempotency state should be coordinated transactionally where practical.

---

# 16. Database

## events

```
```

```
event_id
entity_id
event_type
priority
payload
created_at
status
```

## processed\_events

```
```

```
event_id PRIMARY KEY
entity_id
event_type
processed_at
result
```

## event\_failures

```
```

```
id
event_id
attempt
reason
created_at
```

## dlq\_events

```
```

```
event_id
payload
failure_reason
attempts
created_at
replayed_at
```

---

# 17. Services

```
```

```
apps/
├── api/
├── scheduler/
├── processor/
├── load-generator/
└── dashboard/
```

---

# 18. Shared Packages

```
```

```
packages/
├── event-schema/
├── scheduling/
├── config/
├── logger/
└── metrics/
```

---

# 19. Shell Script

Location:

```
```

```
scripts/scheduler-demo.sh
```

Commands:

```
```

```
./scripts/scheduler-demo.sh --scenario priority

./scripts/scheduler-demo.sh --scenario burst

./scripts/scheduler-demo.sh --scenario starvation

./scripts/scheduler-demo.sh --scenario failure

./scripts/scheduler-demo.sh --scenario duplicate

./scripts/scheduler-demo.sh --scenario ordering
```

The script should drive the actual backend/load generator wherever possible.

Do NOT create a disconnected fake simulation that reports numbers unrelated to the real system.

---

# 20. API

```
```

```
POST /events

GET /health
GET /metrics
GET /stats

GET /scheduler/state
GET /scheduler/decisions

GET /events/recent

GET /dlq
POST /dlq/:eventId/replay
```

Demo-only:

```
```

```
POST /demo/spike
POST /demo/failure
POST /demo/duplicate
POST /demo/out-of-order
POST /demo/starvation
```

Demo endpoints must be disabled or protected outside development/demo environments.

---

# 21. Metrics

Track:

```
```

```
events_received_total
events_processed_total
events_failed_total
events_retried_total
events_dlq_total

event_processing_latency
event_wait_time

queue_depth
queue_lag

worker_count
worker_utilization

scheduler_decisions_total
priority_distribution

starvation_risk
```

---

# 22. Folder Structure

```
```

```
eventflow/
│
├── apps/
│   ├── api/
│   ├── scheduler/
│   ├── processor/
│   ├── load-generator/
│   └── dashboard/
│
├── packages/
│   ├── event-schema/
│   ├── scheduling/
│   ├── config/
│   ├── logger/
│   └── metrics/
│
├── scripts/
│   └── scheduler-demo.sh
│
├── infra/
│   ├── docker-compose.yml
│   ├── kafka/
│   ├── postgres/
│   └── monitoring/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── load/
│   └── chaos/
│
├── docs/
│   ├── Project.md
│   ├── Architecture.md
│   ├── Rules.md
│   ├── Phases.md
│   ├── Design.md
│   └── Memory.md
│
└── README.md
```

---

# 23. Architectural Principle

The entire system should be explainable in five statements:

```
```

```
Kafka = durable event memory

Scheduler = decision maker

Workers = execution resources

PostgreSQL = durable business state

Dashboard = observability

Shell = repeatable demonstration
```

---

# 24. Core Differentiator

Do NOT describe the project as:

> "A Kafka event processing system."

Describe it as:

> "An operating-system-inspired adaptive scheduler for high-throughput business events, backed by a reliable distributed processing pipeline."

```
```

````

---
