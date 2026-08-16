import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class Order(Base):
    __tablename__ = "orders"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_number = Column(String(50), unique=True, index=True, nullable=False)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    store_id = Column(String(36), ForeignKey("stores.id"), nullable=False, index=True)
    status = Column(String(50), default="pending", nullable=False, index=True)
    subtotal = Column(Numeric(10, 2), nullable=False)
    delivery_fee = Column(Numeric(10, 2), nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    delivery_address = Column(Text, nullable=False)
    delivery_latitude = Column(Numeric(10, 7), nullable=False)
    delivery_longitude = Column(Numeric(10, 7), nullable=False)
    route_distance_km = Column(Numeric(10, 2), default=0.0, nullable=False)
    route_duration_minutes = Column(Integer, default=0, nullable=False)
    customer_notes = Column(Text, nullable=True)
    cancellation_reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    customer = relationship("User", back_populates="orders", foreign_keys=[customer_id])
    store = relationship("Store", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="order", uselist=False, cascade="all, delete-orphan")
    delivery = relationship("Delivery", back_populates="order", uselist=False, cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(36), ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    menu_item_id = Column(String(36), ForeignKey("menu_items.id"), nullable=False)
    item_name = Column(String(255), nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    quantity = Column(Integer, nullable=False)
    subtotal = Column(Numeric(10, 2), nullable=False)
    special_instructions = Column(Text, nullable=True)

    order = relationship("Order", back_populates="items")
    menu_item = relationship("MenuItem")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(36), ForeignKey("orders.id", ondelete="CASCADE"), unique=True, nullable=False)
    method = Column(String(50), default="cash_on_delivery", nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String(50), default="unpaid", nullable=False) # unpaid, paid
    collected_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    collected_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    order = relationship("Order", back_populates="payment")
    collector = relationship("User", foreign_keys=[collected_by])
