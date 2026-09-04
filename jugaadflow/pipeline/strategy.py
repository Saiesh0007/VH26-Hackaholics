from dataclasses import dataclass, field


@dataclass
class Strategy:
    level: int = 0
    tier2: str = "process"
    tier3: str = "process"
    tier4: str = "process"
    batch_sizes: dict = field(default_factory=lambda: {"tier2": 5, "tier3": 10, "tier4": 20})
    shed_sample_rate: float = 0.1
    drain_deferred: bool = False
