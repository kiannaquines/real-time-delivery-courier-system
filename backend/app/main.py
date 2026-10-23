from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import Base, engine
from app.api.v1 import (
    auth,
    customers,
    stores,
    menu_items,
    orders,
    deliveries,
    riders,
    devices,
    reports,
    uploads,
    cron,
    health,
)


import time
import logging

logger = logging.getLogger("uvicorn.error")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure tables exist with connection retry support
    max_retries = 5
    for attempt in range(1, max_retries + 1):
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("[DATABASE] Database tables verified successfully.")
            break
        except Exception as exc:
            logger.warning(f"[DATABASE] Connection attempt {attempt}/{max_retries} failed: {exc}")
            if attempt < max_retries:
                time.sleep(2)
            else:
                logger.error("[DATABASE] Could not initialize database after retries. Continuing to allow health checks.")
    yield


app = FastAPI(
    title="M&S Delivery System API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handler for clean error envelopes
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Let FastAPI handle HTTPException internally
    from fastapi.exceptions import HTTPException
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"code": "HTTP_ERROR", "message": exc.detail},
        )
    return JSONResponse(
        status_code=500,
        content={"code": "INTERNAL_SERVER_ERROR", "message": str(exc)},
    )

# Mount Health and Cron
app.include_router(health.router)
app.include_router(health.router, prefix="/api/v1")
app.include_router(cron.router, prefix="/api/v1")

# Mount API v1 Routers
api_v1_routers = [
    auth.router,
    customers.router,
    stores.router,
    menu_items.router,
    orders.router,
    deliveries.router,
    riders.router,
    devices.router,
    reports.router,
    uploads.router,
]

for r in api_v1_routers:
    app.include_router(r, prefix="/api/v1")

