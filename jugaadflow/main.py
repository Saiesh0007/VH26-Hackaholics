import asyncio
import logging
import os
import uvicorn

from jugaadflow.generator.sources import ALL_SOURCES
from jugaadflow.pipeline.queues import create_queues
from jugaadflow.pipeline.classifier import classifier_loop
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.pipeline.worker import worker
from jugaadflow.pipeline.decision_engine import feedback_loop
from jugaadflow.pipeline.thresholds import Thresholds
from jugaadflow.metrics.store import Metrics
from jugaadflow.agents.state import AgentState
from jugaadflow.dashboard.server import create_app, metrics_broadcaster

NUM_WORKERS = 8
logger = logging.getLogger("jugaadflow")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(message)s",
    datefmt="%H:%M:%S",
)


async def main():
    queues = create_queues()
    strategy = Strategy()
    metrics = Metrics()
    thresholds = Thresholds()
    agent_state = AgentState()
    rate_multiplier = [1.0]

    app = create_app(queues, strategy, metrics, rate_multiplier, thresholds, agent_state)

    config = uvicorn.Config(app, host="0.0.0.0", port=8000, log_level="warning")
    server = uvicorn.Server(config)

    tasks = []

    for src in ALL_SOURCES:
        tasks.append(asyncio.create_task(src(queues.input_queue, rate_multiplier)))

    tasks.append(asyncio.create_task(classifier_loop(queues, metrics, strategy)))

    for i in range(NUM_WORKERS):
        tasks.append(asyncio.create_task(worker(i, queues, strategy, metrics)))

    tasks.append(asyncio.create_task(feedback_loop(queues, strategy, metrics, thresholds, interval=3.0)))
    tasks.append(asyncio.create_task(metrics_broadcaster(queues, strategy, metrics, rate_multiplier, app, interval=1.0)))

    if os.environ.get("GEMINI_API_KEY"):
        from jugaadflow.agents.optimizer import optimizer_loop
        from jugaadflow.agents.evaluator import evaluator_loop

        agent_state.agents_enabled = True
        metrics.recent_agent_actions = agent_state.recent_actions

        tasks.append(asyncio.create_task(
            optimizer_loop(thresholds, strategy, queues, metrics, agent_state)
        ))
        tasks.append(asyncio.create_task(
            evaluator_loop(thresholds, strategy, queues, metrics, agent_state)
        ))
        logger.info("AI agents enabled (optimizer + evaluator)")

        if os.environ.get("TWILIO_ACCOUNT_SID"):
            logger.info("Twilio escalation available (button-only, no auto-calls)")
        else:
            logger.info("Twilio escalation disabled (no TWILIO_ACCOUNT_SID)")
    else:
        logger.info("AI agents disabled (no GEMINI_API_KEY)")

    print("\n  ⚡ JugaadFlow running at http://localhost:8000\n")

    await server.serve()

    for t in tasks:
        t.cancel()


if __name__ == "__main__":
    asyncio.run(main())
