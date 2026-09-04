import time
import threading
from dataclasses import dataclass, field


_counter = 0
_counter_lock = threading.Lock()


def _next_id() -> str:
    global _counter
    with _counter_lock:
        _counter += 1
        return f"evt-{_counter:05d}"


@dataclass
class Event:
    type: str
    source: str
    payload: dict
    priority: int = 0
    created_at: float = field(default_factory=time.time)
    id: str = field(default_factory=_next_id)
