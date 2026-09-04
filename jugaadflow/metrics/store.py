import time
from collections import deque
from dataclasses import dataclass, field


@dataclass
class Metrics:
    latency_samples: dict[int, deque] = field(default_factory=lambda: {
        1: deque(maxlen=500),
        2: deque(maxlen=500),
        3: deque(maxlen=500),
        4: deque(maxlen=500),
    })

    processed_count: dict[str, int] = field(default_factory=lambda: {
        "payment": 0, "order": 0, "inventory": 0, "click": 0, "log": 0,
    })
    shed_count: dict[str, int] = field(default_factory=lambda: {
        "payment": 0, "order": 0, "inventory": 0, "click": 0, "log": 0,
    })
    deferred_count: dict[str, int] = field(default_factory=lambda: {
        "payment": 0, "order": 0, "inventory": 0, "click": 0, "log": 0,
    })
    batched_count: dict[str, int] = field(default_factory=lambda: {
        "payment": 0, "order": 0, "inventory": 0, "click": 0, "log": 0,
    })

    throughput_window: dict[int, int] = field(default_factory=lambda: {
        1: 0, 2: 0, 3: 0, 4: 0,
    })

    classified_window: dict[int, int] = field(default_factory=lambda: {
        1: 0, 2: 0, 3: 0, 4: 0,
    })

    current_level: int = 0
    backpressure_active: bool = False
    incoming_rate: float = 0.0
    start_time: float = field(default_factory=time.time)

    def record_classified(self, tier: int):
        self.classified_window[tier] += 1

    def record_processed(self, event, latency: float):
        self.latency_samples[event.priority].append(latency)
        self.processed_count[event.type] += 1
        self.throughput_window[event.priority] += 1

    def avg_latency(self, tier: int) -> float | None:
        samples = self.latency_samples[tier]
        if not samples:
            return None
        return sum(samples) / len(samples)

    def avg_latency_ms(self, tier: int) -> float | None:
        avg = self.avg_latency(tier)
        return avg * 1000 if avg is not None else None

    def reset_throughput(self):
        for k in self.throughput_window:
            self.throughput_window[k] = 0
        for k in self.classified_window:
            self.classified_window[k] = 0
