from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.common import OrderStatus, PaymentStatus


class FeePreviewRequest(BaseModel):
    store_id: str
    delivery_latitude: float
    delivery_longitude: float


class FeePreviewResponse(BaseModel):
    base_fee: float
    distance_km: float
    per_km_fee: float
    total_delivery_fee: float
    estimated_duration_minutes: int


class OrderItemCreate(BaseModel):
    menu_item_id: str
    quantity: int = Field(..., ge=1)
    special_instructions: Optional[str] = None


class OrderCreateRequest(BaseModel):
    store_id: str
    address_id: str
    items: List[OrderItemCreate]
    notes: Optional[str] = None


class OrderItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    menu_item_id: str
    item_name: str
    unit_price: float
    quantity: int
    subtotal: float
    special_instructions: Optional[str] = None


class Payment(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    method: str = "cash_on_delivery"
    amount: float
    status: PaymentStatus
    collected_at: Optional[datetime] = None


class DeliverySummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    order_id: str
    rider_id: Optional[str] = None
    rider_name: Optional[str] = None
    rider_phone: Optional[str] = None
    status: OrderStatus
    pickup_time: Optional[datetime] = None
    delivered_time: Optional[datetime] = None
    last_latitude: Optional[float] = None
    last_longitude: Optional[float] = None
    last_location_time: Optional[datetime] = None


class Order(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    order_number: str
    customer_id: str
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    store_id: str
    store_name: Optional[str] = None
    status: OrderStatus
    subtotal: float
    delivery_fee: float
    total_amount: float
    payment_status: PaymentStatus
    delivery_address: str
    delivery_latitude: float
    delivery_longitude: float
    created_at: datetime


class OrderDetail(BaseModel):
    order: Order
    items: List[OrderItem] = []
    payment: Optional[Payment] = None
    delivery: Optional[DeliverySummary] = None


class CancelOrderRequest(BaseModel):
    reason: str


class AssignOrderRequest(BaseModel):
    rider_id: str
