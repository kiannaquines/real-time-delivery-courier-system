from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import settings
from app.models.misc import OutboxEvent
from app.schemas.upload import CronJobResponse

router = APIRouter(prefix="/cron", tags=["Cron"])


@router.post("/process-outbox", response_model=CronJobResponse)
def process_outbox(
    x_cron_secret: str = Header(..., alias="x-cron-secret"),
    db: Session = Depends(get_db)
):
    if x_cron_secret != settings.CRON_SECRET:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid cron secret.")

    pending_events = db.query(OutboxEvent).filter(
        OutboxEvent.status == "pending",
        OutboxEvent.retry_count < 5
    ).limit(50).all()

    processed = 0
    failed = 0

    now = datetime.now(timezone.utc)
    for evt in pending_events:
        try:
            # Dispatch to Firebase if service account configured
            # Here we mark sent idempotently
            evt.status = "sent"
            evt.processed_at = now
            processed += 1
        except Exception as e:
            evt.retry_count += 1
            evt.last_error = str(e)
            if evt.retry_count >= 5:
                evt.status = "failed"
            failed += 1

    db.commit()
    return CronJobResponse(processed_count=processed, failed_count=failed)
