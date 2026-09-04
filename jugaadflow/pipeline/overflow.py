import asyncio

from jugaadflow.generator.event import Event
from jugaadflow.pipeline.queues import Queues
from jugaadflow.metrics.store import Metrics


async def route_to_queue(event: Event, queues: Queues, metrics: Metrics):
    queue = queues.tier(event.priority)

    try:
        queue.put_nowait(event)
    except asyncio.QueueFull:
        if event.priority == 1:
            await queue.put(event)
        elif event.priority in (2, 3):
            deferred = queues.deferred(event.priority)
            try:
                deferred.put_nowait(event)
                metrics.deferred_count[event.type] += 1
            except asyncio.QueueFull:
                metrics.shed_count[event.type] += 1
        else:
            metrics.shed_count[event.type] += 1
