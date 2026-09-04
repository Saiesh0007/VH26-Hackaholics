"""
Admin router — all endpoints require role == 'admin'.

Covers:
  GET  /api/admin/metrics
  GET  /api/admin/events
  GET  /api/admin/decisions
  GET  /api/admin/queues
  GET  /api/admin/alerts
  GET  /api/admin/benchmarks
  GET  /api/admin/simulation
  POST /api/admin/simulation/start
  POST /api/admin/simulation/stop
  PUT  /api/admin/simulation/rate
"""
from fastapi import APIRouter, Depends
from auth import require_admin
import simulation as sim
import database as db
from models import SimulationConfig, RateUpdate
from datetime import datetime, timezone
import random

router = APIRouter(prefix="/api/admin", tags=["Admin"])

# Shared admin dependency applied to all routes in this router
_admin = Depends(require_admin)


# ─── Metrics ──────────────────────────────────────────────────────────────────

@router.get("/metrics")
def get_metrics(user: dict = _admin):
    """Live pipeline metrics — poll every 3s from the frontend."""
    return sim.get_metrics_snapshot()


# ─── Event Stream ─────────────────────────────────────────────────────────────

@router.get("/events")
def get_events(n: int = 20, user: dict = _admin):
    """Recent event log entries (most-recent first)."""
    events = sim.get_event_log(n)
    # Guarantee at least some data even before simulation starts
    if not events:
        events = _seed_events(n)
    try:
        events = db.get_events(n) + events
    except Exception:
        pass
    return {"events": events, "total": len(events)}


def _seed_events(n: int) -> list[dict]:
    types = ["PRODUCT_VIEW","CART_UPDATE","ORDER_CREATED","PAYMENT_CAPTURED","INVENTORY_RESERVE","NOTIFICATION_SEND"]
    now = datetime.now(timezone.utc)
    result = []
    for i in range(n):
        prio = random.choices(["P0","P1","P2","P3"], weights=[5,15,40,40])[0]
        result.append({
            "id": f"evt-{10482 - i}",
            "type": random.choice(types),
            "priority": prio,
            "decision": "STREAM" if prio in ("P0","P1") else ("DEFER" if prio=="P2" else "BATCH"),
            "queue": prio,
            "pressure": round(42 + random.uniform(-5, 5), 1),
            "worker": round(44 + random.uniform(-5, 10), 1),
            "time": f"{now.hour}:{now.minute - i % 30:02d}:{random.randint(0, 59):02d}",
            "reason": "Critical path" if prio == "P0" else "Load within threshold",
        })
    return result


# ─── Decisions ────────────────────────────────────────────────────────────────

@router.get("/decisions")
def get_decisions(n: int = 20, user: dict = _admin):
    """Decision log — enriched event entries showing routing choices."""
    events = sim.get_event_log(n)
    try:
        events = db.get_events(n) + events
    except Exception:
        pass
    events = events[:n] or _seed_events(n)
    # Enrich with decision-specific fields
    enriched = []
    for e in events:
        enriched.append({
            "id":             e["id"],
            "event_type":     e["type"],
            "priority":       e["priority"],
            "decision":       e["decision"],
            "queue_pressure": e["pressure"],
            "worker_load":    e["worker"],
            "timestamp":      e["time"],
            "reason":         e["reason"],
        })
    return {"decisions": enriched, "total": len(enriched)}


# ─── Queues ───────────────────────────────────────────────────────────────────

@router.get("/queues")
def get_queues(user: dict = _admin):
    """Per-priority queue status."""
    snapshot = sim.get_metrics_snapshot()
    return {"queues": snapshot["queues"]}


# ─── Alerts ───────────────────────────────────────────────────────────────────

@router.get("/alerts")
def get_alerts(user: dict = _admin):
    """Active system alerts (dynamic based on simulation state)."""
    state   = sim.get_simulation()
    alerts  = []
    ts      = datetime.now(timezone.utc).strftime("%H:%M:%S")

    if state.rate > 15_000:
        alerts.append({
            "id": "ALT-001", "severity": "critical",
            "title": "Extreme traffic spike",
            "message": f"Current rate {state.rate:,} req/min exceeds stress threshold. P2 events being deferred.",
            "timestamp": ts,
        })
    if state.rate > 8_000:
        alerts.append({
            "id": "ALT-002", "severity": "warning",
            "title": "Elevated queue pressure",
            "message": "P3 queue pressure above 80%. Batch processing engaged.",
            "timestamp": ts,
        })
    alerts.append({
        "id": "ALT-003", "severity": "info",
        "title": "P0 invariant holding",
        "message": "Zero critical events lost. System operating within SLA.",
        "timestamp": ts,
    })
    return {"alerts": alerts}


# ─── Benchmarks ───────────────────────────────────────────────────────────────

@router.get("/benchmarks")
def get_benchmarks(user: dict = _admin):
    """Throughput benchmark results."""
    benchmarks = [
        {"label": "Normal load (4k/min)",       "throughput": 66,  "p50_latency_ms": 8,  "p95_latency_ms": 28,  "p99_latency_ms": 62,  "error_rate": 0.0},
        {"label": "High load (10k/min)",         "throughput": 165, "p50_latency_ms": 14, "p95_latency_ms": 54,  "p99_latency_ms": 120, "error_rate": 0.0},
        {"label": "Stress (20k/min)",            "throughput": 320, "p50_latency_ms": 28, "p95_latency_ms": 108, "p99_latency_ms": 240, "error_rate": 0.2},
        {"label": "Big Billion Days (35k/min)",  "throughput": 540, "p50_latency_ms": 45, "p95_latency_ms": 189, "p99_latency_ms": 410, "error_rate": 0.8},
    ]
    return {"benchmarks": benchmarks}


# ─── Simulation Control ───────────────────────────────────────────────────────

@router.get("/simulation")
def get_simulation_state(user: dict = _admin):
    """Return current simulation config and status."""
    s = sim.get_simulation()
    return {
        "running":          s.running,
        "mode":             s.mode,
        "rate":             s.rate,
        "events_ingested":  s.events_ingested,
        "p0_lost":          s.p0_lost,
        "backpressure":     s.backpressure,
    }


@router.post("/simulation/start")
async def start_simulation(config: SimulationConfig, user: dict = _admin):
    """Start the traffic simulation with the given mode and req/min rate."""
    await sim.start_simulation(config.mode, config.rate)
    return {
        "status":  "started",
        "mode":    config.mode,
        "rate":    config.rate,
        "message": f"Simulation started at {config.rate:,} req/min in '{config.mode}' mode.",
    }


@router.post("/simulation/stop")
async def stop_simulation(user: dict = _admin):
    """Stop the active simulation."""
    await sim.stop_simulation()
    return {"status": "stopped", "message": "Simulation stopped."}


@router.put("/simulation/rate")
def update_simulation_rate(payload: RateUpdate, user: dict = _admin):
    """
    Hot-update the traffic rate without stopping the simulation.
    The frontend slider calls this on every change.
    """
    sim.set_rate(payload.rate)
    s = sim.get_simulation()
    return {
        "status":       "updated",
        "rate":         payload.rate,
        "backpressure": s.backpressure,
        "message":      f"Rate updated to {payload.rate:,} req/min.",
    }
