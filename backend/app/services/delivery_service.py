import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.order import Order, Payment
from app.models.delivery import Delivery
from app.models.user import User, RiderProfile
from app.schemas.delivery import DeliveryStatusUpdateRequest
from app.services.audit_service import log_audit_event, enqueue_notification


def assign_order_to_rider(db: Session, admin_user: User, order_id: str, rider_id: str) -> Order:
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found.")

    if order.status in ["delivered", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot assign order in status '{order.status}'."
        )

    rider = db.query(User).filter(User.id == rider_id, User.role == "rider").first()
    if not rider:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rider not found.")

    # 1 Active Delivery Invariant check
    active_delivery = db.query(Delivery).filter(
        Delivery.rider_id == rider.id,
        Delivery.status.in_(["assigned", "picked_up", "on_the_way"])
    ).first()

    if active_delivery and active_delivery.order_id != order.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Rider already has an active delivery (Order {active_delivery.order_id})."
        )

    # Update or create delivery
    delivery = order.delivery
    if not delivery:
        delivery = Delivery(id=str(uuid.uuid4()), order_id=order.id)
        db.add(delivery)

    now = datetime.now(timezone.utc)
    delivery.rider_id = rider.id
    delivery.status = "assigned"
    delivery.assigned_at = now

    order.status = "assigned"

    # Update rider profile status
    if rider.rider_profile:
        rider.rider_profile.status = "busy"

    log_audit_event(
        db,
        actor_id=admin_user.id,
        actor_email=admin_user.email,
        action="order.assign_rider",
        target_type="order",
        target_id=order.id,
        reason=f"Assigned to rider {rider.full_name} ({rider.id})",
        metadata={"rider_id": rider.id}
    )

    enqueue_notification(
        db,
        event_type="order.assigned",
        payload={"order_id": order.id, "rider_id": rider.id, "rider_name": rider.full_name}
    )

    db.commit()
    db.refresh(order)
    return order


def update_delivery_status(
    db: Session,
    user: User,
    delivery_id: str,
    update_req: DeliveryStatusUpdateRequest
) -> Delivery:
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery not found.")

    order = delivery.order

    # Role validation
    if user.role == "rider":
        if delivery.rider_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not assigned to this delivery.")
    elif user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized.")

    target_status = update_req.status
    now = datetime.now(timezone.utc)

    # Valid transitions:
    # pending/confirmed -> assigned -> picked_up -> on_the_way -> delivered
    valid_transitions = {
        "pending": ["confirmed", "assigned", "cancelled"],
        "confirmed": ["assigned", "cancelled"],
        "assigned": ["picked_up", "cancelled"],
        "picked_up": ["on_the_way", "delivered", "cancelled"],
        "on_the_way": ["delivered", "cancelled"],
        "delivered": [],
        "cancelled": []
    }

    allowed = valid_transitions.get(delivery.status, [])
    if target_status not in allowed and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid state transition from '{delivery.status}' to '{target_status}'."
        )

    delivery.status = target_status
    order.status = target_status

    if target_status == "picked_up":
        delivery.picked_up_at = now
    elif target_status == "delivered":
        delivery.delivered_at = now
        # Process Cash on Delivery collection
        if order.payment:
            order.payment.status = "paid"
            order.payment.collected_by = user.id
            order.payment.collected_at = now

        # Free rider back to available
        if delivery.rider and delivery.rider.rider_profile:
            delivery.rider.rider_profile.status = "available"

    elif target_status == "cancelled":
        delivery.cancelled_at = now
        if delivery.rider and delivery.rider.rider_profile:
            delivery.rider.rider_profile.status = "available"

    if update_req.audit_reason or user.role == "admin":
        log_audit_event(
            db,
            actor_id=user.id,
            actor_email=user.email,
            action=f"delivery.status.{target_status}",
            target_type="delivery",
            target_id=delivery.id,
            reason=update_req.audit_reason or f"Transition to {target_status}",
            metadata={"status": target_status, "order_id": order.id}
        )

    enqueue_notification(
        db,
        event_type=f"delivery.{target_status}",
        payload={"delivery_id": delivery.id, "order_id": order.id, "status": target_status}
    )

    db.commit()
    db.refresh(delivery)
    return delivery
