import asyncio
import random
import time

from jugaadflow.generator.event import Event
from jugaadflow.pipeline.queues import Queues
from jugaadflow.pipeline.strategy import Strategy
from jugaadflow.metrics.store import Metrics

PROCESSING_TIME = {
    "payment": 0.05,
    "order": 0.04,
    "inventory": 0.02,
    "click": 0.01,
    "log": 0.005,
}

BATCH_PROCESSING_TIME = 0.05


async def process_individual(event: Event, metrics: Metrics):
    await asyncio.sleep(PROCESSING_TIME[event.type])
    latency = time.time() - event.created_at
    metrics.record_processed(event, latency)


async def process_batch(queue: asyncio.Queue, batch_size: int, metrics: Metrics):
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
            latency = time.time() - event.created_at
            metrics.record_processed(event, latency)
            metrics.batched_count[event.type] += 1


async def worker(worker_id: int, queues: Queues, strategy: Strategy, metrics: Metrics):
    while True:
        if strategy.naive_mode:
            if not queues.fifo.empty():
                event = await queues.fifo.get()
                await process_individual(event, metrics)
            else:
                await asyncio.sleep(0.01)
            continue

        # Tier 1: always process (never defer, never batch)
        if not queues.tier1.empty():
            event = await queues.tier1.get()
            await process_individual(event, metrics)

        # Tier 2: process or batch (classifier handles defer routing)
        elif not queues.tier2.empty():
            if strategy.tier2 == "batch":
                await process_batch(queues.tier2, strategy.batch_sizes["tier2"], metrics)
            else:
                event = await queues.tier2.get()
                await process_individual(event, metrics)

        # Tier 3: process or batch
        elif not queues.tier3.empty():
            if strategy.tier3 == "batch":
                await process_batch(queues.tier3, strategy.batch_sizes["tier3"], metrics)
            else:
                event = await queues.tier3.get()
                await process_individual(event, metrics)

        # Tier 4: process, batch, or shed-sample
        elif not queues.tier4.empty():
            if strategy.tier4 == "shed":
                try:
                    event = queues.tier4.get_nowait()
                except asyncio.QueueEmpty:
                    pass
                else:
                    if random.random() < strategy.shed_sample_rate:
                        await process_individual(event, metrics)
                    else:
                        metrics.shed_count[event.type] += 1
            elif strategy.tier4 == "batch":
                await process_batch(queues.tier4, strategy.batch_sizes["tier4"], metrics)
            else:
                event = await queues.tier4.get()
                await process_individual(event, metrics)

        # Deferred queues: drain when allowed
        elif not queues.deferred_tier2.empty() and strategy.drain_deferred:
            event = await queues.deferred_tier2.get()
            await process_individual(event, metrics)

        elif not queues.deferred_tier3.empty() and strategy.drain_deferred:
            event = await queues.deferred_tier3.get()
            await process_individual(event, metrics)

        else:
            await asyncio.sleep(0.01)
