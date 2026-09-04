from typing import List, Optional
from pydantic import BaseModel, Field

class EventPolicy(BaseModel):
    type: str = Field(..., description="Unique event type slug, e.g. 'payment_charge' or 'emergency_alert'")
    displayName: str = Field(..., description="Human readable display name, e.g. 'Payment Charge'")
    description: str = Field(..., description="Brief description of the event semantics")
    priority: str = Field(..., description="Priority code: 'P0', 'P1', 'P2', or 'P3'")
    critical: bool = Field(..., description="True if critical workload that must NEVER be dropped")
    slaMs: int = Field(..., description="Target SLA latency in milliseconds")
    batchable: bool = Field(default=False, description="Whether event can be micro-batched")
    maxBatchSize: int = Field(default=1, description="Maximum batch size if batchable")
    preferredStrategy: str = Field(default="stream", description="Preferred strategy: 'stream', 'batch', 'defer', 'shed'")
    canDefer: bool = Field(default=False, description="Whether event can be deferred to disk spillover")
    canShed: bool = Field(default=False, description="Whether non-critical event can be sampled/shed")
    sheddingThreshold: float = Field(default=0.0, description="Queue pressure threshold (0.0 - 1.0) to begin shedding")
    retryable: bool = Field(default=True, description="Whether failed processing can be retried")
    idempotencyRequired: bool = Field(default=True, description="Whether deduplication/idempotency key is mandatory")
    processingCost: float = Field(default=0.5, description="Relative computational cost (0.1 to 1.0)")
    dependencies: List[str] = Field(default_factory=list, description="Downstream services or external dependencies")

class PriorityTier(BaseModel):
    code: str = Field(..., description="'P0', 'P1', 'P2', or 'P3'")
    name: str = Field(..., description="Tier name, e.g. 'Critical Financial & Triage'")
    description: str = Field(..., description="Operational policy description")
    targetSlaMs: int = Field(..., description="Maximum SLA ceiling")
    allowShedding: bool = Field(default=False, description="Whether shedding is ever permitted in this tier")

class GlobalPolicySettings(BaseModel):
    baselineTrafficRate: int = Field(default=1000, description="Baseline events per minute")
    spikeTrafficRate: int = Field(default=20000, description="Surge events per minute under spike")
    maxQueueCapacity: int = Field(default=10000, description="Maximum internal queue buffer capacity")
    maxBatchSizeLimit: int = Field(default=1000, description="Hard ceiling for batch size")
    maxDeferWindowSecondsLimit: int = Field(default=300, description="Maximum deferral window in seconds")
    maxSamplingRateLimit: float = Field(default=0.90, description="Maximum shed rate allowed")

class DomainPolicy(BaseModel):
    domainName: str = Field(..., description="Human-readable domain name, e.g. 'Hospital Disaster Management'")
    description: str = Field(..., description="Domain overview and operational mission")
    version: str = Field(default="v1.0.0", description="Policy version identifier")
    eventTypes: List[EventPolicy] = Field(..., description="List of event definitions and their SLA constraints")
    priorityTiers: List[PriorityTier] = Field(default_factory=list, description="Priority tiers configured for domain")
    globalSettings: GlobalPolicySettings = Field(default_factory=GlobalPolicySettings)
    metadata: Optional[dict] = Field(default_factory=dict)
