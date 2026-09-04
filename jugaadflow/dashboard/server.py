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

    @app.get("/")
    async def index():
        return HTMLResponse((STATIC_DIR / "index.html").read_text())

    @app.get("/style.css")
    async def style():
        from fastapi.responses import Response
        return Response(
            content=(STATIC_DIR / "style.css").read_text(),
            media_type="text/css",
        )

    @app.get("/dashboard.js")
    async def js():
        from fastapi.responses import Response
        return Response(
            content=(STATIC_DIR / "dashboard.js").read_text(),
            media_type="application/javascript",
        )

    @app.websocket("/ws")
    async def websocket_endpoint(ws: WebSocket):
        await ws.accept()
        clients.append(ws)
        try:
            while True:
                await ws.receive_text()
        except WebSocketDisconnect:
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
    return app


def build_metrics_payload(
    queues: Queues,
    strategy: Strategy,
    metrics: Metrics,
    rate_multiplier: list[float],
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
            "tier1": round(metrics.avg_latency_ms(1), 1) if metrics.avg_latency_ms(1) is not None else None,
            "tier2": round(metrics.avg_latency_ms(2), 1) if metrics.avg_latency_ms(2) is not None else None,
            "tier3": round(metrics.avg_latency_ms(3), 1) if metrics.avg_latency_ms(3) is not None else None,
            "tier4": round(metrics.avg_latency_ms(4), 1) if metrics.avg_latency_ms(4) is not None else None,
        },
        "throughput_per_sec": dict(metrics.throughput_window),
        "counters": {
            "processed": dict(metrics.processed_count),
            "shed": dict(metrics.shed_count),
            "deferred": dict(metrics.deferred_count),
            "batched": dict(metrics.batched_count),
        },
        "incoming_rate": metrics.incoming_rate,
        "classified_per_sec": dict(metrics.classified_window),
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
        payload = build_metrics_payload(queues, strategy, metrics, rate_multiplier)
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
