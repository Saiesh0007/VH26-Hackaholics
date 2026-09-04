# JugaadFlow — Code Review Fix List

Read this file, then apply all fixes in order. Start with MUST FIX, then SHOULD FIX, then NICE TO FIX, then STILL NEEDED. After all fixes, run the 6 test files to verify.

---

## MUST FIX (correctness bugs)

### 1. decision_engine.py — de-escalation ignores tier 1 latency

File: `jugaadflow/pipeline/decision_engine.py`, function `_check_deescalation()`

The spec requires BOTH latency AND queue depth for de-escalation:
```
Emergency→Critical: t1_latency < 100ms AND t1_queue < 200
Critical→Elevated:  t1_latency < 60ms  AND t1_queue < 50
Elevated→Normal:    t1_latency < 40ms  AND t1_queue < 10
```

Currently only checks `t1_queue` and `lower_q`, completely ignores `t1_latency_ms`. This causes flapping: de-escalates while latency is still high, then immediately re-escalates.

Fix:
```python
def _check_deescalation(t1_latency_ms, t1_queue, lower_q, current_level):
    if current_level == 3 and t1_latency_ms < 100 and t1_queue < 200 and lower_q < 1500:
        return 2
    if current_level == 2 and t1_latency_ms < 60 and t1_queue < 50 and lower_q < 500:
        return 1
    if current_level == 1 and t1_latency_ms < 40 and t1_queue < 10 and lower_q < 50:
        return 0
    return None
```

### 2. server.py — clients.remove(ws) can raise ValueError

File: `jugaadflow/dashboard/server.py`, function `websocket_endpoint()`

Race between `metrics_broadcaster` removing dead clients and the `WebSocketDisconnect` handler. If broadcaster removes the client first, `remove()` throws `ValueError`.

Fix — change the except block:
```python
except WebSocketDisconnect:
    if ws in clients:
        clients.remove(ws)
```

---

## SHOULD FIX (affects demo quality)

### 3. server.py — avg_latency_ms() called twice per tier

File: `jugaadflow/dashboard/server.py`, function `build_metrics_payload()`

Each call iterates up to 500 deque elements. Called 2x per tier × 4 tiers = 8 wasted iterations every second.

Fix — cache the result:
```python
latency = {}
for t in range(1, 5):
    ms = metrics.avg_latency_ms(t)
    latency[f"tier{t}"] = round(ms, 1) if ms is not None else None
```
Then use the `latency` dict in the return payload instead of calling `avg_latency_ms()` inline.

### 4. dashboard.js — null latency renders as 0ms on chart

File: `jugaadflow/dashboard/static/dashboard.js`

`data.latency_ms.tier1 || 0` makes "no data" look like "0ms = instant" on the chart. Misleading during deferral when a tier has no samples.

Fix — in the `handleMessage()` latency chart section:
```javascript
pushChartData(latencyChart, label, [
    data.latency_ms.tier1,
    data.latency_ms.tier2,
    data.latency_ms.tier3,
    data.latency_ms.tier4,
]);
```
And add `spanGaps: false` to each latency dataset in `initCharts()` so Chart.js breaks the line at null points instead of drawing to 0.

### 5. classifier.py — incoming_rate never updated

File: `jugaadflow/pipeline/classifier.py`, function `classifier_loop()`

`metrics.incoming_rate` is always 0.0. Dashboard always shows 0 for incoming rate.

Fix — add rate tracking to the classifier loop:
```python
async def classifier_loop(queues, metrics, strategy=None):
    if strategy is None:
        strategy = Strategy()
    count = 0
    window_start = time.time()
    while True:
        event = await queues.input_queue.get()
        await classify_and_route(event, queues, metrics, strategy)
        count += 1
        now = time.time()
        if now - window_start >= 1.0:
            metrics.incoming_rate = count / (now - window_start)
            count = 0
            window_start = now
```
Add `import time` at the top if not already present.

### 6. test_decision_engine.py — hardcoded True in "stayed NORMAL" check

File: `tests/test_decision_engine.py`, line 77

`'PASS' if True else 'FAIL'` always passes regardless of actual level.

Fix — capture the level after Phase 1:
```python
# After Phase 1 sleep (around line 54):
normal_level = strategy.level

# In the summary section (around line 77):
print(f"  Normal -> stayed NORMAL: {'PASS' if normal_level == 0 else 'FAIL'}")
```

### 7. test_defer_shed.py — 15s recovery too short

File: `tests/test_defer_shed.py`, line 69

De-escalation from Emergency→Normal takes 18s minimum (6s cooldown × 3 level steps). Deferred drain only starts at Level 0 (drain_deferred=True). With only 15s, the system never reaches Normal and deferred queues never drain.

Fix:
```python
await asyncio.sleep(25.0)
```

### 8. dashboard.js — mode toggle desyncs on page refresh

File: `jugaadflow/dashboard/static/dashboard.js` and `jugaadflow/dashboard/server.py`

`currentMode` is local JS state. If the page refreshes, it resets to 'adaptive' even if naive mode is active on the server.

Fix — in `server.py` `build_metrics_payload()`, add to the returned dict:
```python
"naive_mode": app.state.naive_mode,
```

Then in `dashboard.js` `handleMessage()`, add:
```javascript
const btn = document.getElementById('modeBtn');
btn.textContent = data.naive_mode ? 'Mode: Naive' : 'Mode: Adaptive';
currentMode = data.naive_mode ? 'naive' : 'adaptive';
```

---

## NICE TO FIX (code quality)

### 9. event.py — unnecessary threading.Lock

File: `jugaadflow/generator/event.py`

Asyncio is single-threaded. The lock is never contested. CLAUDE.md says "Don't use threads."

Fix — remove `import threading`, the `_counter_lock`, and simplify:
```python
_counter = 0

def _next_id() -> str:
    global _counter
    _counter += 1
    return f"evt-{_counter:05d}"
```

### 10. decision_engine.py — escalation has undocumented lower_q triggers

File: `jugaadflow/pipeline/decision_engine.py`, function `_check_escalation()`

The spec says escalation is based on t1_latency and t1_queue ONLY. The code adds `lower_q > 200/1000/3000` as additional OR conditions. This can cause unnecessary escalation when tier 1 is fine but lower queues are deep.

Decision needed: either remove `lower_q` from escalation to match the spec exactly, or keep it and document it as an intentional enhancement in CLAUDE.md and architecture.md. If presenting to judges against the spec, matching the spec is safer.

### 11. style.css + dashboard.js — canvas sizing conflict

File: `jugaadflow/dashboard/static/style.css` and `jugaadflow/dashboard/static/dashboard.js`

`!important` on canvas width/height overrides Chart.js responsive behavior.

Fix — in `dashboard.js`, add to `sharedOpts`:
```javascript
maintainAspectRatio: false,
```
Then in `style.css`, the `!important` can stay as a fallback or be removed.

### 12. server.py — unused import

File: `jugaadflow/dashboard/server.py`

`from fastapi.staticfiles import StaticFiles` is imported but never used. Remove it.

### 13. test_batching.py — weak assertions

File: `tests/test_batching.py`

Only checks `total_batched_spike > 0`. Doesn't verify which types were batched.

Fix — add to the summary:
```python
click_or_log_batched = batched_spike.get('click', 0) + batched_spike.get('log', 0) > 0
print(f"  Click/log batched:   {'PASS' if click_or_log_batched else 'FAIL'}")
print(f"  Payment NOT batched: {'PASS' if batched_spike.get('payment', 0) == 0 else 'FAIL'}")
```

---

## STILL NEEDED (not yet built)

### 14. main.py — entry point

File: `jugaadflow/main.py` (create new)

Wire everything together. Rough structure:
```python
import asyncio
import uvicorn
from jugaadflow.generator.sources import ALL_SOURCES
from jugaadflow.pipeline.queues import create_queues
from jugaadflow.pipeline.classifier import classifier_loop
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.pipeline.worker import worker
from jugaadflow.pipeline.decision_engine import feedback_loop
from jugaadflow.metrics.store import Metrics
from jugaadflow.dashboard.server import create_app, metrics_broadcaster

async def main():
    queues = create_queues()
    strategy = Strategy()
    metrics = Metrics()
    rate_multiplier = [1.0]

    app = create_app(queues, strategy, metrics, rate_multiplier)

    config = uvicorn.Config(app, host="0.0.0.0", port=8000, log_level="warning")
    server = uvicorn.Server(config)

    await asyncio.gather(
        *[src(queues.input_queue, rate_multiplier) for src in ALL_SOURCES],
        classifier_loop(queues, metrics, strategy),
        *[worker(i, queues, strategy, metrics) for i in range(8)],
        feedback_loop(queues, strategy, metrics),
        metrics_broadcaster(queues, strategy, metrics, rate_multiplier, app),
        server.serve(),
    )

if __name__ == "__main__":
    asyncio.run(main())
```

### 15. Naive mode wiring

`app.state.naive_mode` flag is set by the dashboard toggle but nothing reads it. Need a mechanism to swap between adaptive and naive pipelines at runtime. Options:
- Have workers check a shared `naive_mode` flag and pull from a FIFO queue when True
- Or cancel adaptive tasks and start naive tasks on toggle (more complex, cleaner separation)

The naive functions already exist in `jugaadflow/benchmark/naive.py` (`naive_classifier_loop`, `naive_worker`).

### 16. plan.md — fix shed rate discrepancy

File: `plan.md`

Level 2 says "shed (sample 1 in 5)" which is 20% kept. CLAUDE.md and the code both say 10%. Change plan.md to match: "shed (sample 1 in 10)" or "shed (sample 10%)".

---

## Verification

After all fixes, run every test:
```bash
cd /home/soham/Downloads/VH26-Hackaholics
python tests/test_generator.py
python tests/test_classifier.py
python tests/test_workers.py
python tests/test_decision_engine.py
python tests/test_batching.py
python tests/test_defer_shed.py
```

Key things to verify:
- test_decision_engine: escalates during spike AND de-escalates during recovery (no flapping)
- ALL tests: `Payment never shed: PASS`
- test_defer_shed: deferred queues drain during recovery (with the longer 25s sleep)
- Once main.py exists: `python jugaadflow/main.py` starts the dashboard at http://localhost:8000
