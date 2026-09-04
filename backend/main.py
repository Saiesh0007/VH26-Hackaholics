"""
FlashFlow FastAPI backend — entrypoint.

Start with:
    uvicorn main:app --reload --port 8000
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import simulation as sim

from routers.auth_router     import router as auth_router
from routers.admin_router    import router as admin_router
from routers.products_router import router as products_router
from routers.orders_router   import router as orders_router


# ─── Lifespan (startup / shutdown) ────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start background simulation at default "Normal" rate on boot so the
    # admin dashboard has live metrics immediately after login.
    await sim.start_simulation(mode="Normal", rate=4000)
    yield
    await sim.stop_simulation()


# ─── App ──────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="FlashFlow API",
    description=(
        "Resilient e-commerce pipeline backend. "
        "Provides role-based auth (admin / customer), live pipeline metrics, "
        "traffic simulation control, and a full order-management API."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# ─── CORS ─────────────────────────────────────────────────────────────────────
# Allow the Vite dev server (port 5173) and any other local origin.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(products_router)
app.include_router(orders_router)


# ─── Health ───────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"])
def health():
    """Simple liveness check."""
    return {"status": "ok", "service": "flashflow-api"}


@app.get("/", tags=["Health"])
def root():
    return {
        "message": "FlashFlow API is running.",
        "docs":    "/docs",
        "roles":   {"admin": "admin@flashflow.dev / admin123", "customer": "maya@flashflow.dev / user123"},
    }
