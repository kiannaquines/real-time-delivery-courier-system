import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, require_customer, require_admin
from app.models.user import User
from app.models.order import Order, OrderItem, Payment
from app.models.delivery import Delivery
from app.models.misc import IdempotencyKey
from app.schemas.order import (
    Order as OrderSchema,
    OrderDetail,
    OrderItem as OrderItemSchema,
    Payment as PaymentSchema,
    DeliverySummary,
    OrderCreateRequest,
    FeePreviewRequest,
    FeePreviewResponse,
    CancelOrderRequest,
    AssignOrderRequest,
)
from app.schemas.common import OrderStatus
from app.services.order_service import preview_order_fee, create_order, cancel_order
from app.services.delivery_service import assign_order_to_rider

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("/preview-fee", response_model=FeePreviewResponse)
async def preview_fee(request: FeePreviewRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return await preview_order_fee(db, request)


@router.get("", response_model=List[OrderSchema])
def list_orders(
    status: Optional[OrderStatus] = Query(None),
    store_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Order)

    if current_user.role == "customer":
        query = query.filter(Order.customer_id == current_user.id)
    elif current_user.role == "rider":
        # Rider gets orders where they are assigned
        query = query.join(Delivery).filter(Delivery.rider_id == current_user.id)

    if status:
        query = query.filter(Order.status == status.value)
    if store_id:
        query = query.filter(Order.store_id == store_id)

    orders = query.order_by(Order.created_at.desc()).all()

    result = []
    for o in orders:
        result.append(
            OrderSchema(
                id=o.id,
                order_number=o.order_number,
                customer_id=o.customer_id,
                customer_name=o.customer.full_name if o.customer else None,
                customer_phone=o.customer.phone if o.customer else None,
                store_id=o.store_id,
                store_name=o.store.name if o.store else None,
                status=o.status,
                subtotal=float(o.subtotal),
                delivery_fee=float(o.delivery_fee),
                total_amount=float(o.total_amount),
                payment_status="paid" if (o.payment and o.payment.status == "paid") else "unpaid",
                delivery_address=o.delivery_address,
                delivery_latitude=float(o.delivery_latitude),
                delivery_longitude=float(o.delivery_longitude),
                created_at=o.created_at,
            )
        )
    return result


@router.post("", response_model=OrderSchema, status_code=status.HTTP_201_CREATED)
async def place_order(
    request: OrderCreateRequest,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db)
):
    # Idempotency check
    if idempotency_key:
        existing_key = db.query(IdempotencyKey).filter(
            IdempotencyKey.key == idempotency_key,
            IdempotencyKey.user_id == current_user.id
        ).first()
        if existing_key:
            return existing_key.response_body

    order = await create_order(db, current_user, request)

    res_data = OrderSchema(
        id=order.id,
        order_number=order.order_number,
        customer_id=order.customer_id,
        customer_name=current_user.full_name,
        customer_phone=current_user.phone,
        store_id=order.store_id,
        store_name=order.store.name if order.store else None,
        status=order.status,
        subtotal=float(order.subtotal),
        delivery_fee=float(order.delivery_fee),
        total_amount=float(order.total_amount),
        payment_status=order.payment.status if order.payment else "unpaid",
        delivery_address=order.delivery_address,
        delivery_latitude=float(order.delivery_latitude),
        delivery_longitude=float(order.delivery_longitude),
        created_at=order.created_at,
    )

    if idempotency_key:
        new_key = IdempotencyKey(
            id=str(uuid.uuid4()),
            key=idempotency_key,
            user_id=current_user.id,
            request_path="/orders",
            response_code=201,
            response_body=res_data.model_dump(mode="json"),
        )
        db.add(new_key)
        db.commit()

    return res_data


@router.get("/{order_id}", response_model=OrderDetail)
def get_order_detail(
    order_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found.")

    if current_user.role == "customer" and order.customer_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    elif current_user.role == "rider":
        if not order.delivery or order.delivery.rider_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    order_schema = OrderSchema(
        id=order.id,
        order_number=order.order_number,
        customer_id=order.customer_id,
        customer_name=order.customer.full_name if order.customer else None,
        customer_phone=order.customer.phone if order.customer else None,
        store_id=order.store_id,
        store_name=order.store.name if order.store else None,
        status=order.status,
        subtotal=float(order.subtotal),
        delivery_fee=float(order.delivery_fee),
        total_amount=float(order.total_amount),
        payment_status="paid" if (order.payment and order.payment.status == "paid") else "unpaid",
        delivery_address=order.delivery_address,
        delivery_latitude=float(order.delivery_latitude),
        delivery_longitude=float(order.delivery_longitude),
        created_at=order.created_at,
    )

    items_schema = [
        OrderItemSchema(
            id=it.id,
            menu_item_id=it.menu_item_id,
            item_name=it.item_name,
            unit_price=float(it.unit_price),
            quantity=it.quantity,
            subtotal=float(it.subtotal),
            special_instructions=it.special_instructions,
        )
        for it in order.items
    ]

    payment_schema = None
    if order.payment:
        payment_schema = PaymentSchema(
            id=order.payment.id,
            method=order.payment.method,
            amount=float(order.payment.amount),
            status="paid" if order.payment.status == "paid" else "unpaid",
            collected_at=order.payment.collected_at,
        )

    delivery_schema = None
    if order.delivery:
        d = order.delivery
        delivery_schema = DeliverySummary(
            id=d.id,
            order_id=d.order_id,
            rider_id=d.rider_id,
            rider_name=d.rider.full_name if d.rider else None,
            rider_phone=d.rider.phone if d.rider else None,
            status=d.status,
            pickup_time=d.picked_up_at,
            delivered_time=d.delivered_at,
            last_latitude=float(d.last_latitude) if d.last_latitude else None,
            last_longitude=float(d.last_longitude) if d.last_longitude else None,
            last_location_time=d.last_location_updated_at,
        )

    return OrderDetail(
        order=order_schema,
        items=items_schema,
        payment=payment_schema,
        delivery=delivery_schema,
    )


@router.post("/{order_id}/cancel", response_model=OrderSchema)
def cancel(
    order_id: str,
    request: CancelOrderRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = cancel_order(db, current_user, order_id, request.reason)
    return OrderSchema(
        id=order.id,
        order_number=order.order_number,
        customer_id=order.customer_id,
        customer_name=order.customer.full_name if order.customer else None,
        customer_phone=order.customer.phone if order.customer else None,
        store_id=order.store_id,
        store_name=order.store.name if order.store else None,
        status=order.status,
        subtotal=float(order.subtotal),
        delivery_fee=float(order.delivery_fee),
        total_amount=float(order.total_amount),
        payment_status=order.payment.status if order.payment else "unpaid",
        delivery_address=order.delivery_address,
        delivery_latitude=float(order.delivery_latitude),
        delivery_longitude=float(order.delivery_longitude),
        created_at=order.created_at,
    )


@router.post("/{order_id}/assign", response_model=OrderDetail)
def assign(
    order_id: str,
    request: AssignOrderRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    order = assign_order_to_rider(db, current_user, order_id, request.rider_id)
    return get_order_detail(order.id, current_user, db)
