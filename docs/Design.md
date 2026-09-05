# Design — EventFlow Scheduler Control Room

# 1. Design Direction

The UI should feel like a:

> Distributed systems control room

It should NOT look like a generic CRUD/admin dashboard.

Personality:

- Technical
- Fast
- Reliable
- High-signal
- Operational
- Judge-friendly

---

# 2. Theme

Dark-first.

Use:

- near-black background
- dark elevated surfaces
- subtle borders
- strong typography

---

# 3. Semantic Colors

Use color primarily to communicate state.

```text
Green  → Healthy / Success

Amber  → Warning / Retry

Red    → Failure / DLQ

Blue   → Active / Information

Purple → Scheduler / Priority
````

Do not make the entire interface colorful.

---

# 4. Typography

Primary:

```
```

```
Inter
```

Technical:

```
```

```
JetBrains Mono
```

Suggested:

```
```

```
Page title:    28–32px

Section title: 18–22px

Large metric:  28–40px

Body:          14–16px

Secondary:     12–14px

Technical:     12–14px
```

---

# 5. Dashboard

```
```

```
┌─────────────────────────────────────────────────────────┐
│ EVENTFLOW                    ● SYSTEM HEALTHY           │
│ Adaptive Event Scheduler                                 │
├────────────┬────────────┬────────────┬──────────────────┤
│ Arrival    │ Processing │ Backlog    │ Workers          │
│ 18.2K/min  │ 17.9K/min  │ 2,381      │ 12               │
├────────────┴────────────┴────────────┴──────────────────┤
│                    THROUGHPUT                            │
│ Incoming  ─────────────────────────                     │
│ Processed ───────────────────────                       │
├──────────────────────────┬──────────────────────────────┤
│ SCHEDULER                │ PRIORITY QUEUES              │
│                          │                              │
│ Next: EVT-123            │ CRITICAL █████████           │
│ Priority: CRITICAL       │ HIGH     ███████             │
│ Worker: W4               │ NORMAL   █████               │
│ Reason: business urgency │ LOW      ███                 │
├──────────────────────────┼──────────────────────────────┤
│ WORKERS                  │ FAILURES / DLQ               │
│ W1 ● ACTIVE              │ Retry: 32                   │
│ W2 ● ACTIVE              │ DLQ: 3                      │
│ W3 ● BUSY                │ Recent failures...           │
│ W4 ● IDLE                │                              │
└──────────────────────────┴──────────────────────────────┘
```

---

# 6. Scheduler Visualization

This is the most important visual.

Example:

```
```

```
SCHEDULER

CRITICAL
  EVT-12
  EVT-19

HIGH
  EVT-21

NORMAL
  EVT-25

LOW
  EVT-31
```

Then:

```
```

```
NEXT DECISION

EVT-31

Base Priority:
LOW

Waiting:
31s

Aging Bonus:
+35

Effective:
NORMAL+

Reason:
STARVATION PREVENTION
```

This makes the algorithm visible to judges.

---

# 7. Worker Visualization

```
```

```
WORKERS

W1 ● ACTIVE    EVT-123
W2 ● ACTIVE    EVT-124
W3 ● BUSY      EVT-125
W4 ● IDLE
W5 ● RETRYING  EVT-129
```

---

# 8. Traffic Visualization

Show:

```
```

```
Incoming Rate
Processing Rate
Backlog
```

When a spike occurs:

```
```

```
Incoming:
████████████████████ 20K/min

Processing:
██████████████       14K/min

Backlog:
████████             6K
```

Then show recovery.

---

# 9. Demo Controls

Section:

```
```

```
SIMULATION CONTROLS
```

Buttons:

```
```

```
[ Traffic Spike ]

[ Fail Payment Service ]

[ Slow Workers ]

[ Duplicate Event ]

[ Out-of-Order Events ]

[ Starvation Test ]

[ Invalid Event ]
```

Current scenario must be visible.

---

# 10. Event Detail

Clicking an event should show:

```
```

```
EVENT

ID:
EVT-123

Type:
PAYMENT_FAILED

Entity:
ORDER-991

Priority:
CRITICAL

Created:
12:03:10

Queued:
12:03:11

Started:
12:03:12

Completed:
12:03:13

Worker:
W4

Attempts:
1

Status:
SUCCESS
```

---

# 11. Shell UI

The shell script should produce readable terminal output.

Example:

```
```

```
╔══════════════════════════════════════════════════╗
║              EVENTFLOW SCHEDULER                ║
╚══════════════════════════════════════════════════╝

Scenario: STARVATION

QUEUE STATUS
────────────────────────────────────────────────────
CRITICAL : 12
HIGH     : 18
NORMAL   : 23
LOW      : 1

LOW EVENT

EVT-042
Waiting: 31s
Base priority: LOW

Starvation Risk: HIGH

Applying AGING...

Effective Priority:
NORMAL+

Worker W3 → EVT-042

✓ EXECUTED
```

The shell should provide a non-color fallback for terminals that do not support ANSI colors.

---

# 12. Animation

Use subtle live updates:

-  Counters 
-  Queue movement 
-  Worker state 
-  Scheduler decisions 
-  Status changes 

Avoid excessive animations.

---

# 13. Judge-Focused Design

The following moments must be visually obvious.

## Normal

```
```

```
SYSTEM HEALTHY
```

## Burst

```
```

```
20K/min
Backlog ↑
Workers ↑
```

## Priority

```
```

```
CRITICAL EVENT SELECTED
```

## Failure

```
```

```
SERVICE DOWN
RETRY ↑
```

## Recovery

```
```

```
SERVICE UP
BACKLOG ↓
```

## Starvation

```
```

```
LOW EVENT WAITING
       ↓
AGING
       ↓
PROMOTED
       ↓
EXECUTED
```

---

# 14. Accessibility

-  Never depend only on color. 
-  Use labels/icons. 
-  Maintain readable contrast. 
-  Keyboard accessible controls. 
-  Do not hide critical information behind animations. 

---

# 15. Design Principle

The dashboard should answer these questions immediately:

```
```

```
What is happening?

What is the scheduler doing?

Is the system overloaded?

Are critical events safe?

Are events failing?

Are events starving?

Are workers keeping up?
```

```
```

````

---
