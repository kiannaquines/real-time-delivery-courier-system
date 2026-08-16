import random
import string
import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.order import Order, OrderItem, Payment
from app.models.delivery import Delivery
from app.models.store import Store, MenuItem
from app.models.user import Address, User
from app.schemas.order import OrderCreateRequest, FeePreviewRequest, FeePreviewResponse
from app.services.mapbox_service import get_route_distance_and_duration, calculate_delivery_fee
from app.services.audit_service import log_audit_event, enqueue_notification


def generate_order_number() -> str:
    timestamp = datetime.now().strftime("%y%m%d")
    random_str = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"MNS-{timestamp}-{random_str}"


async def preview_order_fee(db: Session, request: FeePreviewRequest) -> FeePreviewResponse:
    store = db.query(Store).filter(Store.id == request.store_id, Store.is_active == True).first()
    if not store:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found or inactive.")

    dist_km, duration_mins = await get_route_distance_and_duration(
        origin_lat=float(store.latitude),
        origin_lon=float(store.longitude),
        dest_lat=request.delivery_latitude,
        dest_lon=request.delivery_longitude,
    )
    delivery_fee = calculate_delivery_fee(dist_km)

    return FeePreviewResponse(
        base_fee=49.00,
        distance_km=dist_km,
        per_km_fee=12.00,
        total_delivery_fee=delivery_fee,
        estimated_duration_minutes=duration_mins,
    )


async def create_order(db: Session, customer: User, request: OrderCreateRequest) -> Order:
    # 1. Validate Store
    store = db.query(Store).filter(Store.id == request.store_id, Store.is_active == True).first()
    if not store:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found or inactive.")

    # 2. Validate Address
    address = db.query(Address).filter(Address.id == request.address_id, Address.customer_id == customer.id).first()
    if not address:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery address not found.")

    if not request.items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Order must have at least one item.")

    # 3. Validate Single Store Invariant & Calculate Subtotal
    subtotal = 0.0
    order_items_to_create = []

    for item_req in request.items:
        menu_item = db.query(MenuItem).filter(
            MenuItem.id == item_req.menu_item_id,
            MenuItem.store_id == store.id,
            MenuItem.is_available == True
        ).first()

        if not menu_item:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Menu item {item_req.menu_item_id} is unavailable or does not belong to this store."
            )

        unit_price = float(menu_item.price)
        item_subtotal = round(unit_price * item_req.quantity, 2)
        subtotal += item_subtotal

        order_items_to_create.append(
            OrderItem(
                id=str(uuid.uuid4()),
                menu_item_id=menu_item.id,
                item_name=menu_item.name,
                unit_price=unit_price,
                quantity=item_req.quantity,
                subtotal=item_subtotal,
                special_instructions=item_req.special_instructions,
            )
        )

    # 4. Route distance, duration and delivery fee
    dist_km, duration_mins = await get_route_distance_and_duration(
        origin_lat=float(store.latitude),
        origin_lon=float(store.longitude),
        dest_lat=float(address.latitude),
        dest_lon=float(address.longitude),
    )
    delivery_fee = calculate_delivery_fee(dist_km)
    total_amount = round(subtotal + delivery_fee, 2)

    # 5. Build Order
    order_id = str(uuid.uuid4())
    order = Order(
        id=order_id,
        order_number=generate_order_number(),
        customer_id=customer.id,
        store_id=store.id,
        status="pending",
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        total_amount=total_amount,
        delivery_address=address.address_line,
        delivery_latitude=address.latitude,
        delivery_longitude=address.longitude,
        route_distance_km=dist_km,
        route_duration_minutes=duration_mins,
        customer_notes=request.notes,
    )
    db.add(order)

    # 6. Add Items
    for oi in order_items_to_create:
        oi.order_id = order_id
        db.add(oi)

    # 7. Add Cash On Delivery Payment record (unpaid)
    payment = Payment(
        id=str(uuid.uuid4()),
        order_id=order_id,
        method="cash_on_delivery",
        amount=total_amount,
        status="unpaid",
    )
    db.add(payment)

    # 8. Add Delivery record (pending)
    delivery = Delivery(
        id=str(uuid.uuid4()),
        order_id=order_id,
        status="pending",
    )
    db.add(delivery)

    # Enqueue Notification for dispatch
    enqueue_notification(
        db,
        event_type="order.created",
        payload={"order_id": order_id, "order_number": order.order_number, "customer_id": customer.id}
    )

    db.commit()
    db.refresh(order)
    return order


def cancel_order(db: Session, user: User, order_id: str, reason: str) -> Order:
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found.")

    if order.status in ["delivered", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel order in status '{order.status}'."
        )

    # Customers can only cancel if pending
    if user.role == "customer":
        if order.customer_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
        if order.status != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Orders that have already been confirmed or assigned cannot be cancelled by the customer. Please contact support."
            )
    elif user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only customers or admins may cancel an order.")

    order.status = "cancelled"
    order.cancellation_reason = reason

    if order.delivery:
        order.delivery.status = "cancelled"
        order.delivery.cancelled_at = datetime.now(timezone.utc)

    # Log audit event
    log_audit_event(
        db,
        actor_id=user.id,
        actor_email=user.email,
        action="order.cancel",
        target_type="order",
        target_id=order.id,
        reason=reason,
        metadata={"previous_status": order.status}
    )

    enqueue_notification(
        db,
        event_type="order.cancelled",
        payload={"order_id": order.id, "reason": reason}
    )

    db.commit()
    db.refresh(order)
    return order
