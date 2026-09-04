import asyncio
import random

from jugaadflow.generator.event import Event
from jugaadflow.generator import payloads


SOURCE_CONFIG = {
    "payment": {
        "source_name": "payment-gateway",
        "base_interval": (0.5, 2.0),
        "payload_fn": payloads.payment_payload,
    },
    "order": {
        "source_name": "order-service",
        "base_interval": (0.3, 1.0),
        "payload_fn": payloads.order_payload,
    },
    "inventory": {
        "source_name": "inventory-service",
        "base_interval": (0.1, 0.5),
        "payload_fn": payloads.inventory_payload,
    },
    "click": {
        "source_name": "clickstream",
        "base_interval": (0.01, 0.1),
        "payload_fn": payloads.click_payload,
    },
    "log": {
        "source_name": "app-logger",
        "base_interval": (0.01, 0.05),
        "payload_fn": payloads.log_payload,
    },
}


async def _source_loop(
    event_type: str,
    input_queue: asyncio.Queue,
    rate_multiplier: list[float],
):
    config = SOURCE_CONFIG[event_type]
    lo, hi = config["base_interval"]
    payload_fn = config["payload_fn"]
    source_name = config["source_name"]

    while True:
        base = random.uniform(lo, hi)
        jitter = base * random.uniform(-0.25, 0.25)
        interval = max(0.001, (base + jitter) / rate_multiplier[0])
        await asyncio.sleep(interval)

        event = Event(
            type=event_type,
            source=source_name,
            payload=payload_fn(),
        )
        await input_queue.put(event)


async def payment_source(input_queue: asyncio.Queue, rate_multiplier: list[float]):
    await _source_loop("payment", input_queue, rate_multiplier)


async def order_source(input_queue: asyncio.Queue, rate_multiplier: list[float]):
    await _source_loop("order", input_queue, rate_multiplier)


async def inventory_source(input_queue: asyncio.Queue, rate_multiplier: list[float]):
    await _source_loop("inventory", input_queue, rate_multiplier)


async def click_source(input_queue: asyncio.Queue, rate_multiplier: list[float]):
    await _source_loop("click", input_queue, rate_multiplier)


async def log_source(input_queue: asyncio.Queue, rate_multiplier: list[float]):
    await _source_loop("log", input_queue, rate_multiplier)


ALL_SOURCES = [payment_source, order_source, inventory_source, click_source, log_source]
