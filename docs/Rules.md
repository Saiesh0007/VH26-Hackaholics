# Rules — Engineering, Scheduling, Reliability & AI Boundaries

## 1. Source of Truth

The following documents are authoritative:

```text
Project.md
Architecture.md
Rules.md
Phases.md
Design.md
Memory.md
````

Code must follow these documents.

If a major architectural change is required, update Memory.md and document the decision.

---

# 2. Fixed Technology Rules

Use:

-  TypeScript 
-  React 
-  Vite 
-  Tailwind 
-  Fastify 
-  Kafka 
-  PostgreSQL 
-  Zod 
-  Docker Compose 
-  Vitest 
-  Recharts 

Redis is optional and requires a concrete reason.

---

# 3. Avoid

Do not introduce:

-  Multiple message brokers 
-  Multiple databases without justification 
-  Kubernetes unless explicitly required 
-  Unnecessary microservices 
-  Service mesh 
-  AI features unrelated to the core problem 
-  Complex infrastructure for demonstration purposes 
-  Decorative technologies 

The priority is:

> Working system > unnecessary complexity

---

# 4. Scheduler Rules

## Priority

```
```

```
CRITICAL > HIGH > NORMAL > LOW
```

---

## Fairness

Never implement:

```
```

```
always choose highest priority
```

as the only scheduling algorithm.

That can cause starvation.

---

## Aging

Waiting events should accumulate aging.

Aging must be:

-  deterministic 
-  measurable 
-  bounded 
-  observable 

---

## Starvation Prevention

A lower-priority event must not wait indefinitely because higher-priority traffic continuously arrives.

---

## Ordering

Scheduler decisions must not violate required same-entity ordering.

---

## Worker Capacity

Do not dispatch more work than workers can safely process.

---

# 5. Event Rules

Every event must contain:

```
```

```
event_id
event_type
entity_id
priority
timestamp
payload
```

Validate every external event.

---

# 6. Idempotency

`event_id` is the logical idempotency key.

Duplicate events must not produce duplicate business effects.

At-least-once delivery is acceptable.

Duplicate business effects are not.

---

# 7. Ordering

Use:

```
```

```
entity_id
```

as the ordering key where appropriate.

Independent entities may execute concurrently.

---

# 8. Error Handling

Never silently swallow errors.

Every failure must be:

-  handled 
-  retried 
-  rejected 
-  sent to DLQ 
-  or surfaced through monitoring 

Classify errors:

```
```

```
VALIDATION_ERROR
TRANSIENT_ERROR
BUSINESS_ERROR
INFRASTRUCTURE_ERROR
UNKNOWN_ERROR
```

---

# 9. Retry Rules

Retry only errors that are genuinely transient.

Initial:

```
```

```
MAX_RETRIES = 3
```

Use backoff.

Record:

```
```

```
attempt
reason
timestamp
```

Do not retry malformed payloads forever.

---

# 10. DLQ Rules

A permanently failing event should eventually enter DLQ.

DLQ must preserve enough information for:

-  debugging 
-  inspection 
-  replay 

---

# 11. Backpressure

Never create an unbounded in-memory event queue.

Kafka/durable infrastructure must absorb backlog.

Expose:

```
```

```
queue_depth
queue_lag
arrival_rate
processing_rate
```

---

# 12. Worker Scaling

Scaling must be based on observable workload.

Do not fabricate:

```
```

```
"we automatically scale perfectly"
```

Measure the behavior.

---

# 13. Shell Script Rules

Required:

```
```

```
scripts/scheduler-demo.sh
```

It must:

-  be executable 
-  have clear scenario names 
-  use predictable exit codes 
-  fail clearly 
-  show actual observed values 
-  preferably invoke the real system 
-  not contain fake benchmark results 

Example:

```
```

```
./scripts/scheduler-demo.sh --scenario burst
```

---

# 14. Benchmark Rules

Never fabricate:

-  throughput 
-  latency 
-  success rate 
-  worker count 
-  queue depth 
-  zero-loss claims 

All performance claims must come from actual tests.

---

# 15. Logging

Every important event-processing log should make it possible to identify:

```
```

```
event_id
entity_id
worker_id
attempt
scheduler decision
failure reason
duration
```

---

# 16. Security

Never commit:

-  passwords 
-  API keys 
-  tokens 
-  credentials 

Use environment variables.

Validate all external input.

Demo control endpoints must not be unrestricted in production.

---

# 17. Testing

## Unit Tests

Must cover:

```
```

```
priority
fairness
aging
starvation
ordering
retry classification
```

---

## Integration Tests

Must cover:

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

Also:

```
```

```
retry
DLQ
idempotency
ordering
```

---

## Load Tests

Run:

```
```

```
1K/min
5K/min
10K/min
20K/min
```

---

## Chaos Tests

Test:

```
```

```
service failure
slow worker
duplicate events
invalid events
out-of-order events
traffic burst
```

---

# 18. AI Rules

AI may assist with:

-  boilerplate 
-  tests 
-  refactoring 
-  debugging 
-  documentation 
-  UI implementation 

AI must NOT invent:

-  benchmark results 
-  security guarantees 
-  reliability claims 
-  completed functionality 

Generated code must be verified.

---

# 19. Definition of Done

A task is complete only when:

```
```

```
implemented
     +
tested
     +
verified
     +
Memory.md updated
```

Code existing in a file does not mean the feature is complete.

---

# 20. Documentation Rule

Every major architectural or scheduling decision must be recorded in Memory.md.

---

# 21. Demo Rule

Every feature that is important to the judging criteria should have a reproducible demonstration.

Examples:

```
```

```
Priority → priority scenario
Burst → burst scenario
Failure → failure scenario
Duplicate → duplicate scenario
Ordering → ordering scenario
Starvation → starvation scenario
```

```
```

````

---
