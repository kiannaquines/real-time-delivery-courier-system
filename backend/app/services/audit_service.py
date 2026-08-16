import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from sqlalchemy.orm import Session
from app.models.misc import AuditLog, OutboxEvent


def log_audit_event(
    db: Session,
    actor_id: Optional[str],
    actor_email: Optional[str],
    action: str,
    target_type: str,
    target_id: str,
    reason: str,
    metadata: Optional[Dict[str, Any]] = None,
) -> AuditLog:
    entry = AuditLog(
        id=str(uuid.uuid4()),
        actor_id=actor_id,
        actor_email=actor_email,
        action=action,
        target_type=target_type,
        target_id=str(target_id),
        reason=reason,
        metadata_json=metadata or {},
        created_at=datetime.now(timezone.utc),
    )
    db.add(entry)
    return entry


def enqueue_notification(
    db: Session,
    event_type: str,
    payload: Dict[str, Any],
) -> OutboxEvent:
    event = OutboxEvent(
        id=str(uuid.uuid4()),
        event_type=event_type,
        payload=payload,
        status="pending",
        retry_count=0,
        created_at=datetime.now(timezone.utc),
    )
    db.add(event)
    return event
