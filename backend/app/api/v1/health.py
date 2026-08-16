from datetime import datetime, timezone
from fastapi import APIRouter
from app.schemas.common import HealthStatus

router = APIRouter(tags=["Health"])


@router.get("/health/live", response_model=HealthStatus)
def health_live():
    return HealthStatus(status="ok", timestamp=datetime.now(timezone.utc))


@router.get("/health/ready", response_model=HealthStatus)
def health_ready():
    return HealthStatus(status="ok", timestamp=datetime.now(timezone.utc))
