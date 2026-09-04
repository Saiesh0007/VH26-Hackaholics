"""
Pydantic models (schemas) for FlashFlow API.
"""
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, Literal, List
from datetime import datetime


# ─── Auth / User ──────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: Literal["customer", "admin"] = "customer"

    @field_validator("name")
    @classmethod
    def name_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Name cannot be empty")
        return v.strip()


class UserLogin(BaseModel):
    email: str
    password: str


class UserOut(BaseModel):
    id: str
    name: str
    email: str
    role: Literal["customer", "admin"]


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ─── Products ─────────────────────────────────────────────────────────────────

class Product(BaseModel):
    id: str
    name: str
    category: str
    price: float
    stock: int
    rating: float
    color: str
    tag: str


# ─── Orders ───────────────────────────────────────────────────────────────────

class OrderItem(BaseModel):
    product_id: str
    name: str
    quantity: int
    price: float


class OrderCreate(BaseModel):
    items: List[OrderItem]
    shipping_address: Optional[str] = "Demo address"


class Order(BaseModel):
    id: str
    user_id: str
    items: List[OrderItem]
    total: float
    status: Literal["Processing", "Shipped", "Delivered", "Cancelled"]
    created_at: str
    shipping_address: str


# ─── Pipeline / Metrics ───────────────────────────────────────────────────────

class QueueBand(BaseModel):
    priority: str          # P0, P1, P2, P3
    label: str             # Critical, High, Normal, Low
    depth: int
    pressure: float        # 0-100 %
    deferred: int
    shed: int
    processing_rate: int   # events/sec
    p95_latency_ms: int


class PipelineMetrics(BaseModel):
    traffic: int           # req/min
    events_per_sec: int
    queue_depth: int
    pressure: float        # overall %
    deferred: int
    batched: int
    shed: int
    critical_lost: int
    backpressure: str      # "Contained" | "Active"
    queues: List[QueueBand]
    timestamp: str


class EventEntry(BaseModel):
    id: str
    type: str
    priority: str
    decision: str
    queue: str
    pressure: float
    worker: float
    time: str
    reason: str


class DecisionEntry(BaseModel):
    id: str
    event_type: str
    priority: str
    decision: str
    queue_pressure: float
    worker_load: float
    timestamp: str
    reason: str


# ─── Simulation ───────────────────────────────────────────────────────────────

class SimulationConfig(BaseModel):
    mode: Literal["Normal", "Big Billion Days", "Stress", "Recovery"] = "Normal"
    rate: int = 4000   # requests per minute

    @field_validator("rate")
    @classmethod
    def rate_range(cls, v: int) -> int:
        if not (1000 <= v <= 50000):
            raise ValueError("Rate must be between 1,000 and 50,000 req/min")
        return v


class RateUpdate(BaseModel):
    rate: int

    @field_validator("rate")
    @classmethod
    def rate_range(cls, v: int) -> int:
        if not (1000 <= v <= 50000):
            raise ValueError("Rate must be between 1,000 and 50,000 req/min")
        return v


class SimulationState(BaseModel):
    running: bool
    mode: str
    rate: int
    events_ingested: int
    p0_lost: int
    backpressure: str


# ─── Alerts / Benchmarks ──────────────────────────────────────────────────────

class Alert(BaseModel):
    id: str
    severity: Literal["critical", "warning", "info"]
    title: str
    message: str
    timestamp: str


class BenchmarkResult(BaseModel):
    label: str
    throughput: int         # events/sec
    p50_latency_ms: int
    p95_latency_ms: int
    p99_latency_ms: int
    error_rate: float
