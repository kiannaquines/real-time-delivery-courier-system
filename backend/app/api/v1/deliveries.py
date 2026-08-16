from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, require_rider
from app.models.user import User
from app.models.delivery import Delivery as DeliveryModel
from app.schemas.delivery import (
    Delivery as DeliverySchema,
    DeliveryStatusUpdateRequest,
    RiderLocationBatchRequest,
    DeliverySnapshot,
)
from app.schemas.common import SuccessResponse
from app.services.delivery_service import update_delivery_status
from app.services.location_service import ingest_rider_locations, get_delivery_snapshot

router = APIRouter(prefix="/deliveries", tags=["Deliveries"])


@router.post("/{delivery_id}/status", response_model=DeliverySchema)
def update_status(
    delivery_id: str,
    request: DeliveryStatusUpdateRequest,
    current_user: User = Depends(require_rider),
    db: Session = Depends(get_db)
):
    delivery = update_delivery_status(db, current_user, delivery_id, request)
    return DeliverySchema(
        id=delivery.id,
        order_id=delivery.order_id,
        rider_id=delivery.rider_id,
        rider_name=delivery.rider.full_name if delivery.rider else None,
        rider_phone=delivery.rider.phone if delivery.rider else None,
        status=delivery.status,
        pickup_time=delivery.picked_up_at,
        delivered_time=delivery.delivered_at,
        last_latitude=float(delivery.last_latitude) if delivery.last_latitude else None,
        last_longitude=float(delivery.last_longitude) if delivery.last_longitude else None,
        last_location_time=delivery.last_location_updated_at,
    )


@router.post("/{delivery_id}/location", response_model=SuccessResponse)
async def ingest_location(
    delivery_id: str,
    request: RiderLocationBatchRequest,
    current_user: User = Depends(require_rider),
    db: Session = Depends(get_db)
):
    await ingest_rider_locations(db, current_user, delivery_id, request.locations)
    return SuccessResponse(message=f"Ingested {len(request.locations)} locations successfully.")


@router.get("/{delivery_id}/snapshot", response_model=DeliverySnapshot)
async def get_snapshot(
    delivery_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return await get_delivery_snapshot(db, current_user, delivery_id)
