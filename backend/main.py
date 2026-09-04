import os
import logging
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables strictly from backend/.env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

from models.domain_policy import DomainPolicy
from models.predefined_domains import PREDEFINED_DOMAINS
from validator.policy_validator import PolicyValidator, ValidationReport
from ai.gemini_provider import GeminiProvider

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("adaptq.backend")

app = FastAPI(
    title="AdaptQ Adaptive Data Processing Platform",
    description="Control-plane & Data-plane API for AdaptQ Domain Architect, Policy Validation, and Copilot",
    version="1.0.0"
)

# CORS setup for Flutter web & local apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize AI Provider
ai_provider = GeminiProvider()

# In-memory registry of active and custom domains
active_domain_key = "ecommerce"
domains_registry: Dict[str, DomainPolicy] = dict(PREDEFINED_DOMAINS)

class GeneratePolicyRequest(BaseModel):
    description: str

class CopilotChatRequest(BaseModel):
    query: str
    context: Dict[str, Any]

class ExplainDecisionRequest(BaseModel):
    event: Dict[str, Any]
    context: Dict[str, Any]

class WhatIfRequest(BaseModel):
    scenario: Dict[str, Any]
    simulation: Dict[str, Any]

class ActivateDomainRequest(BaseModel):
    domainKey: str
    customPolicy: Optional[DomainPolicy] = None

@app.get("/api/v1/health")
def health():
    return {
        "status": "healthy",
        "service": "AdaptQ Control Plane",
        "activeDomain": active_domain_key,
        "aiConfigured": bool(ai_provider.api_key and not ai_provider.api_key.startswith("your_"))
    }

@app.get("/api/v1/domains")
def list_domains():
    """Returns available domain policies."""
    result = []
    for k, v in domains_registry.items():
        result.append({
            "key": k,
            "domainName": v.domainName,
            "description": v.description,
            "isActive": (k == active_domain_key),
            "eventCount": len(v.eventTypes),
            "criticalCount": sum(1 for e in v.eventTypes if e.critical)
        })
    return result

@app.get("/api/v1/domains/{domain_key}")
def get_domain(domain_key: str):
    if domain_key not in domains_registry:
        raise HTTPException(status_code=404, detail="Domain not found")
    return domains_registry[domain_key]

@app.post("/api/v1/domains/activate")
def activate_domain(req: ActivateDomainRequest):
    global active_domain_key
    if req.customPolicy:
        # Validate custom policy first
        report = PolicyValidator.validate(req.customPolicy)
        if not report.isValid:
            raise HTTPException(status_code=400, detail={"errors": report.errors})
        
        key = req.domainKey.lower().replace(" ", "_")
        domains_registry[key] = req.customPolicy
        active_domain_key = key
        logger.info(f"Activated custom domain: {req.customPolicy.domainName} ({key})")
        return {"status": "activated", "domainKey": key, "policy": req.customPolicy}
    
    if req.domainKey not in domains_registry:
        raise HTTPException(status_code=404, detail="Domain not found in registry")
    
    active_domain_key = req.domainKey
    logger.info(f"Activated existing domain: {active_domain_key}")
    return {"status": "activated", "domainKey": active_domain_key, "policy": domains_registry[active_domain_key]}

@app.post("/api/v1/ai/generate-policy")
async def generate_policy(req: GeneratePolicyRequest):
    """
    Calls Gemini Domain Architect to synthesize natural language into a DomainPolicy.
    Validates output deterministically before returning to the operator.
    """
    if not req.description or len(req.description.strip()) < 5:
        raise HTTPException(status_code=400, detail="Description is too short. Please describe your event pipeline.")

    try:
        policy = await ai_provider.generate_domain_policy(req.description)
        validation_report = PolicyValidator.validate(policy)
        return {
            "policy": policy,
            "validation": validation_report
        }
    except Exception as e:
        logger.error(f"Error generating policy: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/ai/validate-policy")
def validate_policy(policy: DomainPolicy):
    """Validates an edited or proposed domain policy against hard invariants."""
    report = PolicyValidator.validate(policy)
    return report

@app.post("/api/v1/ai/copilot")
async def chat_copilot(req: CopilotChatRequest):
    """Answers operator queries with structured telemetry grounding."""
    try:
        response = await ai_provider.chat_copilot(req.query, req.context)
        return response
    except Exception as e:
        logger.error(f"Error in copilot: {e}")
        return ai_provider._offline_copilot_response(req.query, req.context)

@app.post("/api/v1/ai/explain-decision")
async def explain_decision(req: ExplainDecisionRequest):
    """Provides decision explainability breakdown for a specific event."""
    explanation = await ai_provider.explain_decision(req.event, req.context)
    return explanation

@app.post("/api/v1/ai/what-if")
async def what_if_analysis(req: WhatIfRequest):
    """Provides predictive analysis for what-if scenarios."""
    analysis = await ai_provider.what_if_analysis(req.scenario, req.simulation)
    return analysis

# -------------------------------------------------------------
# Backwards Compatibility Routes for ApiPipelineRepository
# -------------------------------------------------------------

@app.get("/api/v1/metrics")
def get_metrics():
    return {
        "eventRatePerMin": 1000,
        "throughputPerSec": 17,
        "systemLoadPercentage": 25.0,
        "queuePressurePercentage": 8.0,
        "p0LatencyMs": 38.5,
        "p1LatencyMs": 52.0,
        "p2LatencyMs": 110.0,
        "p3LatencyMs": 185.0,
        "criticalEventsLost": 0,
        "totalDeferredCount": 0,
        "totalShedCount": 0,
        "workerUtilization": 42.0,
        "timestamp": "2026-09-04T22:00:00Z"
    }

@app.get("/api/v1/policy")
def get_current_policy():
    return domains_registry[active_domain_key]

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run("main:app", host=host, port=port, reload=True)
