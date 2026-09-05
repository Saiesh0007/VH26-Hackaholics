import asyncio
import logging
import random
import time

from jugaadflow.generator.event import Event
from jugaadflow.pipeline.queues import Queues
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.metrics.store import Metrics

logger = logging.getLogger("jugaadflow.worker")

PROCESSING_TIME = {
    "payment": 0.05,
    "order": 0.04,
    "inventory": 0.02,
    "click": 0.01,
    "log": 0.005,
}

BATCH_PROCESSING_TIME = 0.05
MAX_RETRIES = 3
FAILURE_RATE = 0.05


class ProcessingError(Exception):
    pass


async def process_individual(event: Event, metrics: Metrics, completed_events: dict | None = None):
    if completed_events is not None and event.id in completed_events:
        metrics.idempotent_skips += 1
        return

    # Simulated failure: 5% on tier 3/4 only — NEVER on tier 1/2
    if event.priority >= 3 and random.random() < FAILURE_RATE:
        raise ProcessingError(f"Simulated failure for {event.id}")

    await asyncio.sleep(PROCESSING_TIME[event.type])
    latency = time.time() - event.created_at
    metrics.record_processed(event, latency)

    if completed_events is not None:
        completed_events[event.id] = time.time()


async def process_batch(queue: asyncio.Queue, batch_size: int, metrics: Metrics, completed_events: dict | None = None):
    batch = []
    for _ in range(batch_size):
        if not queue.empty():
            try:
                batch.append(queue.get_nowait())
            except asyncio.QueueEmpty:
                break
        else:
            break
    if batch:
        await asyncio.sleep(BATCH_PROCESSING_TIME)
        for event in batch:
            if completed_events is not None and event.id in completed_events:
                metrics.idempotent_skips += 1
                continue
            latency = time.time() - event.created_at
            metrics.record_processed(event, latency)
            metrics.batched_count[event.type] += 1
            if completed_events is not None:
                completed_events[event.id] = time.time()


def _handle_failure(event: Event, queues: Queues, metrics: Metrics, dead_letter: list | None):
    event.retry_count += 1
    if event.retry_count > MAX_RETRIES:
        metrics.dead_letter_count += 1
        if dead_letter is not None:
            dead_letter.append({
                "id": event.id, "type": event.type,
                "priority": event.priority, "retries": event.retry_count,
                "time": time.strftime("%H:%M:%S"),
            })
        logger.warning("Dead-lettered %s after %d retries", event.id, event.retry_count)
    else:
        metrics.retries_total += 1
        queue = queues.tier(event.priority)
        try:
            queue.put_nowait(event)
        except asyncio.QueueFull:
            metrics.dead_letter_count += 1
            if dead_letter is not None:
                dead_letter.append({
                    "id": event.id, "type": event.type,
                    "priority": event.priority, "retries": event.retry_count,
                    "time": time.strftime("%H:%M:%S"),
                })
        logger.info("Retry #%d for %s", event.retry_count, event.id)


async def worker(
    worker_id: int, queues: Queues, strategy: Strategy, metrics: Metrics,
    completed_events: dict | None = None,
    worker_kill_flags: list | None = None,
    dead_letter=None,
):
    while True:
        if worker_kill_flags and worker_kill_flags[worker_id]:
            await asyncio.sleep(0.1)
            continue

        if strategy.naive_mode:
            if not queues.fifo.empty():
                event = await queues.fifo.get()
                try:
                    await process_individual(event, metrics, completed_events)
                except ProcessingError:
                    _handle_failure(event, queues, metrics, dead_letter)
            else:
                await asyncio.sleep(0.01)
            continue

        event = None

        # Tier 1: always process (never defer, never batch)
        if not queues.tier1.empty():
            event = await queues.tier1.get()

        # Tier 2: process or batch
        elif not queues.tier2.empty():
            if strategy.tier2 == "batch":
                await process_batch(queues.tier2, strategy.batch_sizes["tier2"], metrics, completed_events)
                continue
            else:
                event = await queues.tier2.get()

        # Tier 3: process or batch
        elif not queues.tier3.empty():
            if strategy.tier3 == "batch":
                await process_batch(queues.tier3, strategy.batch_sizes["tier3"], metrics, completed_events)
                continue
            else:
                event = await queues.tier3.get()

        # Tier 4: process, batch, or shed-sample
        elif not queues.tier4.empty():
            if strategy.tier4 == "shed":
                try:
                    event = queues.tier4.get_nowait()
                except asyncio.QueueEmpty:
                    event = None
                else:
                    if not (random.random() < strategy.shed_sample_rate):
                        metrics.shed_count[event.type] += 1
                        try:
                            queues.kafka_overflow.put_nowait(event)
                        except asyncio.QueueFull:
                            pass
                        event = None
            elif strategy.tier4 == "batch":
                await process_batch(queues.tier4, strategy.batch_sizes["tier4"], metrics, completed_events)
                continue
            else:
                event = await queues.tier4.get()

        # Deferred queues: drain when allowed
        elif not queues.deferred_tier2.empty() and strategy.drain_deferred:
            event = await queues.deferred_tier2.get()

        elif not queues.deferred_tier3.empty() and strategy.drain_deferred:
            event = await queues.deferred_tier3.get()

        else:
            await asyncio.sleep(0.01)
            continue

        if event is None:
            continue

        try:
            await process_individual(event, metrics, completed_events)
        except ProcessingError:
            _handle_failure(event, queues, metrics, dead_letter)


async def completed_events_cleanup(completed_events: dict, ttl: float = 60.0, interval: float = 10.0):
    while True:
        await asyncio.sleep(interval)
        now = time.time()
        expired = [eid for eid, ts in completed_events.items() if (now - ts) >= ttl]
        for eid in expired:
            del completed_events[eid]


async def kafka_consumer_loop(queues: Queues, strategy: Strategy, interval: float = 0.5):
    """
    Background loop that drains the simulated Kafka overflow queue 
    when the system is healthy enough to handle it.
    """
    while True:
        await asyncio.sleep(interval)
        if queues.kafka_overflow.empty():
            continue
            
        # Only re-inject overflowed events if we are at normal or elevated levels
        # and the input queue has some breathing room
        if strategy.level <= 1 and queues.input_queue.qsize() < 2000:
            batch_size = min(100, queues.kafka_overflow.qsize())
            for _ in range(batch_size):
                try:
                    event = queues.kafka_overflow.get_nowait()
                    # Re-inject back to input queue to let the dispatcher route it properly
                    # This simulates a Kafka consumer reading from the topic and pushing it to the app
                    queues.input_queue.put_nowait(event)
                except (asyncio.QueueEmpty, asyncio.QueueFull):
                    break

