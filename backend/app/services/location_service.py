import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.delivery import Delivery, RiderLocation
from app.models.user import User, RiderProfile
from app.models.order import Order
from app.schemas.delivery import (
    RiderLocationPoint,
    DeliverySnapshot,
    LocationCoord,
)
from app.services.mapbox_service import get_route_distance_and_duration


async def ingest_rider_locations(
    db: Session,
    rider_user: User,
    delivery_id: str,
    locations: List[RiderLocationPoint],
) -> bool:
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found.")

    if delivery.rider_id != rider_user.id and rider_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not assigned to this delivery.")

    if delivery.status not in ["assigned", "picked_up", "on_the_way"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot ingest location for delivery with status '{delivery.status}'."
        )

    if not locations:
        return True

    # Sort chronologically
    sorted_locs = sorted(locations, key=lambda l: l.timestamp)

    for loc in sorted_locs:
        point = RiderLocation(
            id=str(uuid.uuid4()),
            delivery_id=delivery.id,
            rider_id=rider_user.id,
            latitude=loc.latitude,
            longitude=loc.longitude,
            accuracy=loc.accuracy,
            heading=loc.heading,
            speed=loc.speed,
            recorded_at=loc.timestamp,
        )
        db.add(point)

    # Update delivery & rider profile last known position
    latest = sorted_locs[-1]
    delivery.last_latitude = latest.latitude
    delivery.last_longitude = latest.longitude
    delivery.last_location_updated_at = latest.timestamp

    if rider_user.rider_profile:
        rider_user.rider_profile.current_latitude = latest.latitude
        rider_user.rider_profile.current_longitude = latest.longitude
        rider_user.rider_profile.last_location_updated_at = latest.timestamp

    db.commit()
    return True


async def get_delivery_snapshot(
    db: Session,
    user: User,
    delivery_id: str
) -> DeliverySnapshot:
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found.")

    order = delivery.order
    # Access control: Customer owner, assigned rider, or admin
    if user.role == "customer" and order.customer_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    elif user.role == "rider" and delivery.rider_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    store = order.store
    store_loc = LocationCoord(latitude=float(store.latitude), longitude=float(store.longitude)) if store else None
    dest_loc = LocationCoord(latitude=float(order.delivery_latitude), longitude=float(order.delivery_longitude))

    last_point = None
    eta_sec = None
    remaining_dist = None

    if delivery.last_latitude and delivery.last_longitude:
        last_point = RiderLocationPoint(
            latitude=float(delivery.last_latitude),
            longitude=float(delivery.last_longitude),
            timestamp=delivery.last_location_updated_at or datetime.now(timezone.utc)
        )
        # Compute dynamic remaining distance & ETA to destination
        dist_km, dur_mins = await get_route_distance_and_duration(
            float(delivery.last_latitude), float(delivery.last_longitude),
            float(order.delivery_latitude), float(order.delivery_longitude)
        )
        remaining_dist = round(dist_km * 1000.0, 2)
        eta_sec = dur_mins * 60

    return DeliverySnapshot(
        delivery_id=delivery.id,
        order_id=order.id,
        status=delivery.status,
        rider_id=delivery.rider_id,
        rider_name=delivery.rider.full_name if delivery.rider else None,
        rider_phone=delivery.rider.phone if delivery.rider else None,
        store_location=store_loc,
        destination_location=dest_loc,
        last_rider_location=last_point,
        eta_seconds=eta_sec,
        remaining_distance_meters=remaining_dist,
    )
