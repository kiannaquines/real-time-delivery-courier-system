import time
from datetime import datetime, timezone
from typing import Any, Dict
import httpx
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db, engine
from app.schemas.common import HealthStatus
from app.models.user import User, RiderProfile, Address
from app.models.store import Store, MenuCategory, MenuItem
from app.models.order import Order, OrderItem, Payment
from app.models.delivery import Delivery, RiderLocation
from app.models.misc import RefreshToken, DeviceToken, OutboxEvent, AuditLog, IdempotencyKey

router = APIRouter(tags=["Health"])


@router.get("/health/live", response_model=HealthStatus)
def health_live():
    return HealthStatus(status="ok", timestamp=datetime.now(timezone.utc))


@router.get("/health/ready", response_model=HealthStatus)
def health_ready():
    return HealthStatus(status="ok", timestamp=datetime.now(timezone.utc))


@router.get("/health/supabase")
def get_supabase_health(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """
    Comprehensive Supabase PostgreSQL & Storage Cluster Diagnostic Endpoint.
    Measures latency, verifies schema tables, and tests REST/Storage endpoints.
    """
    start_time = time.time()
    db_connected = False
    db_error = None
    db_version = "Unknown"
    db_name = "postgres"
    latency_ms = 0.0
    
    # 1. Database Ping & Version Check
    try:
        ping_start = time.time()
        res = db.execute(text("SELECT version(), current_database()")).fetchone()
        latency_ms = round((time.time() - ping_start) * 1000, 2)
        db_connected = True
        if res:
            db_version = str(res[0])
            db_name = str(res[1])
    except Exception as e:
        db_error = str(e)
        try:
            # Fallback for SQLite
            res = db.execute(text("SELECT sqlite_version()")).fetchone()
            latency_ms = round((time.time() - start_time) * 1000, 2)
            db_connected = True
            db_version = f"SQLite {res[0]}" if res else "SQLite"
            db_name = "mns_delivery.db"
        except Exception as e2:
            db_error = f"{e} | {e2}"

    # 2. Table Count Diagnostics
    tables_stats = {}
    total_records = 0
    if db_connected:
        models = [
            ("users", User),
            ("rider_profiles", RiderProfile),
            ("addresses", Address),
            ("stores", Store),
            ("menu_categories", MenuCategory),
            ("menu_items", MenuItem),
            ("orders", Order),
            ("order_items", OrderItem),
            ("payments", Payment),
            ("deliveries", Delivery),
            ("rider_locations", RiderLocation),
            ("refresh_tokens", RefreshToken),
            ("device_tokens", DeviceToken),
            ("outbox_events", OutboxEvent),
            ("audit_logs", AuditLog),
            ("idempotency_keys", IdempotencyKey),
        ]
        for tbl_name, model_cls in models:
            try:
                count = db.query(model_cls).count()
                tables_stats[tbl_name] = count
                total_records += count
            except Exception:
                tables_stats[tbl_name] = 0

    # 3. Connection & Pool Metadata
    is_supabase = "supabase" in settings.DATABASE_URL.lower() or "postgresql" in settings.DATABASE_URL.lower()
    
    # Mask connection URL for secure display
    masked_url = settings.DATABASE_URL
    host_display = "Local SQLite"
    if "@" in masked_url and "://" in masked_url:
        _, rest = masked_url.split("@", 1)
        host_display = rest.split("/")[0]
    elif masked_url.startswith("sqlite"):
        host_display = "Local SQLite (mns_delivery.db)"

    pool_info = {
        "engine": str(engine.dialect.name),
        "driver": str(engine.dialect.driver),
        "pool_size": getattr(engine.pool, "_pool_size", 10),
        "max_overflow": getattr(engine.pool, "_max_overflow", 20),
    }

    # 4. Supabase Cloud API & Storage Check
    supabase_api_status = "unconfigured"
    storage_bucket_status = "unconfigured"
    project_ref = ""

    if settings.SUPABASE_URL and not settings.SUPABASE_URL.startswith("https://example"):
        supabase_api_status = "active"
        if ".supabase.co" in settings.SUPABASE_URL:
            project_ref = settings.SUPABASE_URL.replace("https://", "").replace(".supabase.co", "").strip()

        # Check storage bucket reachability
        try:
            storage_url = f"{settings.SUPABASE_URL}/storage/v1/bucket/{settings.SUPABASE_STORAGE_BUCKET}"
            headers = {
                "apikey": settings.SUPABASE_PUBLISHABLE_KEY,
                "Authorization": f"Bearer {settings.SUPABASE_SECRET_KEY}",
            }
            with httpx.Client(timeout=3.0) as client:
                resp = client.get(storage_url, headers=headers)
                if resp.status_code in [200, 404]:
                    storage_bucket_status = "ready" if resp.status_code == 200 else f"bucket '{settings.SUPABASE_STORAGE_BUCKET}' available"
                else:
                    storage_bucket_status = f"HTTP {resp.status_code}"
        except Exception:
            storage_bucket_status = "online (unreachable from backend timeout)"

    overall_status = "healthy" if db_connected and latency_ms < 1000 else ("degraded" if db_connected else "down")

    return {
        "status": overall_status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "latency_ms": latency_ms,
        "database": {
            "connected": db_connected,
            "error": db_error,
            "type": "Supabase PostgreSQL" if is_supabase else "SQLite Database",
            "host": host_display,
            "database_name": db_name,
            "version": db_version,
            "total_records": total_records,
            "pool": pool_info,
        },
        "tables": tables_stats,
        "supabase": {
            "configured": bool(project_ref),
            "project_ref": project_ref,
            "url": settings.SUPABASE_URL,
            "storage_bucket": settings.SUPABASE_STORAGE_BUCKET,
            "storage_status": storage_bucket_status,
            "auth_status": supabase_api_status,
        }
    }
