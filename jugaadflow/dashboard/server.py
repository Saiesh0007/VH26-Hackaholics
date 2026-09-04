import asyncio
import json
import time
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from jugaadflow.pipeline.queues import Queues
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.metrics.store import Metrics
from jugaadflow.pipeline.decision_engine import LEVEL_NAMES

STATIC_DIR = Path(__file__).parent / "static"
FRONTEND_DIST = Path(__file__).parent.parent.parent / "frontend" / "dist"
BASE_EVENTS_PER_MIN = 3400.0


class RateRequest(BaseModel):
    events_per_min: float


def create_app(
    queues: Queues,
    strategy: Strategy,
    metrics: Metrics,
    rate_multiplier: list[float],
) -> FastAPI:
    app = FastAPI(title="JugaadFlow Dashboard")
    clients: list[WebSocket] = []

    if FRONTEND_DIST.exists():
        app.mount("/assets", StaticFiles(directory=FRONTEND_DIST / "assets"), name="assets")

        @app.get("/old")
        async def old_dashboard():
            return HTMLResponse((STATIC_DIR / "index.html").read_text())
    else:
        @app.get("/style.css")
        async def style():
            from fastapi.responses import Response
            return Response(content=(STATIC_DIR / "style.css").read_text(), media_type="text/css")

        @app.get("/dashboard.js")
        async def js():
            from fastapi.responses import Response
            return Response(content=(STATIC_DIR / "dashboard.js").read_text(), media_type="application/javascript")

    @app.websocket("/ws")
    async def websocket_endpoint(ws: WebSocket):
        await ws.accept()
        clients.append(ws)
        try:
            while True:
                await ws.receive_text()
        except WebSocketDisconnect:
            if ws in clients:
                clients.remove(ws)

    @app.post("/api/spike")
    async def trigger_spike():
        rate_multiplier[0] = 20.0
        return {"status": "spike", "rate_multiplier": 20.0}

    @app.post("/api/normal")
    async def trigger_normal():
        rate_multiplier[0] = 1.0
        return {"status": "normal", "rate_multiplier": 1.0}

    @app.post("/api/rate")
    async def set_rate(req: RateRequest):
        multiplier = max(0.1, min(100.0, req.events_per_min / BASE_EVENTS_PER_MIN))
        rate_multiplier[0] = multiplier
        return {
            "rate_multiplier": round(multiplier, 2),
            "events_per_min": round(multiplier * BASE_EVENTS_PER_MIN),
        }

    @app.post("/api/mode/naive")
    async def set_naive():
        app.state.naive_mode = True
        return {"mode": "naive"}

    @app.post("/api/mode/adaptive")
    async def set_adaptive():
        app.state.naive_mode = False
        return {"mode": "adaptive"}

    app.state.clients = clients
    app.state.naive_mode = False

    @app.get("/{path:path}")
    async def spa_fallback(path: str):
        from fastapi.responses import FileResponse
        if FRONTEND_DIST.exists():
            file_path = FRONTEND_DIST / path
            if file_path.is_file():
                return FileResponse(file_path)
            return FileResponse(FRONTEND_DIST / "index.html")
        return HTMLResponse((STATIC_DIR / "index.html").read_text())

    return app


def build_metrics_payload(
    queues: Queues,
    strategy: Strategy,
    metrics: Metrics,
    rate_multiplier: list[float],
    app_ref=None,
) -> dict:
    return {
        "timestamp": time.time(),
        "level": strategy.level,
        "level_name": LEVEL_NAMES[strategy.level],
        "backpressure": metrics.backpressure_active,
        "rate_multiplier": rate_multiplier[0],
        "queues": {
            "tier1": queues.tier1.qsize(),
            "tier2": queues.tier2.qsize(),
            "tier3": queues.tier3.qsize(),
            "tier4": queues.tier4.qsize(),
            "deferred_tier2": queues.deferred_tier2.qsize(),
            "deferred_tier3": queues.deferred_tier3.qsize(),
            "input": queues.input_queue.qsize(),
        },
        "latency_ms": {
            f"tier{t}": (round(ms, 1) if (ms := metrics.avg_latency_ms(t)) is not None else None)
            for t in range(1, 5)
        },
        "naive_mode": getattr(app_ref.state, 'naive_mode', False) if app_ref else False,
        "throughput_per_sec": dict(metrics.throughput_window),
        "counters": {
            "processed": dict(metrics.processed_count),
            "shed": dict(metrics.shed_count),
            "deferred": dict(metrics.deferred_count),
            "batched": dict(metrics.batched_count),
        },
        "incoming_rate": metrics.incoming_rate,
        "classified_per_sec": dict(metrics.classified_window),
        "recent_events": list(metrics.recent_events),
        "recent_decisions": list(metrics.recent_decisions),
    }


async def metrics_broadcaster(
    queues: Queues,
    strategy: Strategy,
    metrics: Metrics,
    rate_multiplier: list[float],
    app: FastAPI,
    interval: float = 1.0,
):
    while True:
        await asyncio.sleep(interval)
        payload = build_metrics_payload(queues, strategy, metrics, rate_multiplier, app)
        metrics.reset_throughput()
        data = json.dumps(payload)
        dead = []
        for ws in app.state.clients:
            try:
                await ws.send_text(data)
            except Exception:
                dead.append(ws)
        for ws in dead:
            app.state.clients.remove(ws)
