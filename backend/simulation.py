"""
Traffic simulation engine for FlashFlow.

Maintains a live SimulationState that drives the admin metrics feed.
Call `get_simulation()` for the current state, and use `start_simulation()`,
`stop_simulation()`, and `set_rate()` to control it.

The background task (`_tick`) updates queue stats and event counters every second
so the admin dashboard (polling /api/admin/metrics every 3s) always sees fresh data.
"""
import asyncio
import math
import random
from datetime import datetime, timezone
from dataclasses import dataclass, field


@dataclass
class _State:
    running: bool = False
    mode: str = "Normal"
    rate: int = 4000          # req / min
    events_ingested: int = 0
    p0_lost: int = 0
    tick: int = 0             # internal tick counter

    # Derived / computed
    traffic: int = 4000
    events_per_sec: int = 66
    queue_depth: int = 1750
    pressure: float = 42.0
    deferred: int = 12
    batched: int = 28
    shed: int = 0
    critical_lost: int = 0
    backpressure: str = "Contained"

    # Queue bands
    p0_depth: int = 42
    p1_depth: int = 96
    p2_depth: int = 184
    p3_depth: int = 612

    p0_pressure: float = 12.0
    p1_pressure: float = 34.0
    p2_pressure: float = 61.0
    p3_pressure: float = 82.0

    p0_deferred: int = 0
    p1_deferred: int = 2
    p2_deferred: int = 10
    p3_deferred: int = 26

    p0_shed: int = 0
    p1_shed: int = 0
    p2_shed: int = 1
    p3_shed: int = 7


_state = _State()
_task: asyncio.Task | None = None

# Pre-generated event types for realism
_EVENT_TYPES = [
    "PRODUCT_VIEW", "PRODUCT_VIEW", "PRODUCT_VIEW",
    "CART_UPDATE", "CART_UPDATE",
    "CHECKOUT_INIT",
    "ORDER_CREATED",
    "PAYMENT_CAPTURED",
    "INVENTORY_RESERVE",
    "NOTIFICATION_SEND",
    "ANALYTICS_TRACK",
    "SESSION_HEARTBEAT",
]

_DECISIONS = {
    "P0": "STREAM",
    "P1": "STREAM",
    "P2": "STREAM",   # becomes DEFER under extreme load
    "P3": "BATCH",    # becomes SHED under extreme load
}

# Rolling event log (last 50 events)
_event_log: list[dict] = []


def _compute_derived(s: _State):
    """
    Recompute all derived fields from `rate` and `mode`.
    Called every time rate or mode changes, and on every tick.
    """
    rate = s.rate
    eps  = rate / 60.0          # events per second
    extreme = rate > 15_000
    high    = rate > 8_000

    s.traffic        = rate + random.randint(-200, 200)
    s.events_per_sec = int(eps * random.uniform(0.94, 1.0))
    s.queue_depth    = int(rate * 0.26 + random.randint(-100, 100))
    s.pressure       = min(99.0, rate / 200.0)
    s.deferred       = int(rate / 300) if extreme else int(rate / 600)
    s.batched        = int(rate / 200) if high else int(rate / 400)
    s.shed           = int(rate / 1200) if extreme else 0
    s.critical_lost  = 0   # P0 invariant always holds
    s.backpressure   = "Active" if extreme else "Contained"

    # Queue bands
    s.p0_depth   = max(10, int(rate * 0.003) + random.randint(-3, 3))
    s.p1_depth   = max(20, int(rate * 0.007) + random.randint(-5, 5))
    s.p2_depth   = max(30, int(rate * 0.013) + random.randint(-8, 8))
    s.p3_depth   = max(50, int(rate * 0.044) + random.randint(-15, 15))

    s.p0_pressure = min(99.0, rate / 1500.0)
    s.p1_pressure = min(99.0, rate / 500.0)
    s.p2_pressure = min(99.0, rate / 300.0)
    s.p3_pressure = min(99.0, rate / 200.0)

    s.p0_deferred = 0
    s.p1_deferred = 0 if not high     else int(rate / 5000)
    s.p2_deferred = 0 if not high     else int(rate / 800)
    s.p3_deferred = int(rate / 500)

    s.p0_shed = 0
    s.p1_shed = 0
    s.p2_shed = 0 if not extreme else int(rate / 4000)
    s.p3_shed = 0 if not extreme else int(rate / 1500)

    # Override decisions under extreme load
    _DECISIONS["P2"] = "DEFER" if extreme else "STREAM"
    _DECISIONS["P3"] = "SHED"  if extreme else ("BATCH" if high else "BATCH")


async def _tick():
    """Background loop: update state every second while simulation is running."""
    while _state.running:
        _state.tick += 1
        _state.events_ingested += _state.events_per_sec

        _compute_derived(_state)

        # Append to rolling event log
        priority = random.choices(
            ["P0", "P1", "P2", "P3"], weights=[5, 15, 40, 40]
        )[0]
        evt_type = random.choice(_EVENT_TYPES)
        now_str  = datetime.now(timezone.utc).strftime("%H:%M:%S")
        _event_log.append({
            "id":       f"evt-{10000 + _state.tick}",
            "type":     evt_type,
            "priority": priority,
            "decision": _DECISIONS[priority],
            "queue":    priority,
            "pressure": round(_state.pressure + random.uniform(-3, 3), 1),
            "worker":   round(40 + random.uniform(-5, 15), 1),
            "time":     now_str,
            "reason":   "Critical path" if priority == "P0" else "Load within threshold",
        })
        if len(_event_log) > 50:
            _event_log.pop(0)

        await asyncio.sleep(1)


# ─── Public API ───────────────────────────────────────────────────────────────

def get_simulation() -> _State:
    return _state


def get_event_log(n: int = 20) -> list[dict]:
    return list(reversed(_event_log[-n:]))


def get_metrics_snapshot() -> dict:
    s = _state
    return {
        "traffic":        s.traffic,
        "events_per_sec": s.events_per_sec,
        "queue_depth":    s.queue_depth,
        "pressure":       round(s.pressure, 1),
        "deferred":       s.deferred,
        "batched":        s.batched,
        "shed":           s.shed,
        "critical_lost":  s.critical_lost,
        "backpressure":   s.backpressure,
        "timestamp":      datetime.now(timezone.utc).strftime("%H:%M:%S"),
        "queues": [
            {"priority": "P0", "label": "Critical", "depth": s.p0_depth, "pressure": round(s.p0_pressure, 1), "deferred": s.p0_deferred, "shed": s.p0_shed, "processing_rate": 42,  "p95_latency_ms": 12},
            {"priority": "P1", "label": "High",     "depth": s.p1_depth, "pressure": round(s.p1_pressure, 1), "deferred": s.p1_deferred, "shed": s.p1_shed, "processing_rate": 96,  "p95_latency_ms": 28},
            {"priority": "P2", "label": "Normal",   "depth": s.p2_depth, "pressure": round(s.p2_pressure, 1), "deferred": s.p2_deferred, "shed": s.p2_shed, "processing_rate": 184, "p95_latency_ms": 65},
            {"priority": "P3", "label": "Low",      "depth": s.p3_depth, "pressure": round(s.p3_pressure, 1), "deferred": s.p3_deferred, "shed": s.p3_shed, "processing_rate": 312, "p95_latency_ms": 210},
        ],
    }


async def start_simulation(mode: str, rate: int):
    global _task
    _state.running = True
    _state.mode    = mode
    _state.rate    = rate
    _compute_derived(_state)
    if _task is None or _task.done():
        _task = asyncio.create_task(_tick())


async def stop_simulation():
    global _task
    _state.running = False
    if _task and not _task.done():
        _task.cancel()
        try:
            await _task
        except asyncio.CancelledError:
            pass
    _task = None


def set_rate(rate: int):
    """Update rate immediately — no need to restart the loop."""
    _state.rate = rate
    _compute_derived(_state)


def set_mode(mode: str):
    _state.mode = mode
    _compute_derived(_state)
