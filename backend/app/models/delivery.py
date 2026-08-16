import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class Delivery(Base):
    __tablename__ = "deliveries"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(36), ForeignKey("orders.id", ondelete="CASCADE"), unique=True, nullable=False)
    rider_id = Column(String(36), ForeignKey("users.id"), nullable=True, index=True)
    status = Column(String(50), default="pending", nullable=False, index=True)
    assigned_at = Column(DateTime, nullable=True)
    picked_up_at = Column(DateTime, nullable=True)
    delivered_at = Column(DateTime, nullable=True)
    cancelled_at = Column(DateTime, nullable=True)
    last_latitude = Column(Numeric(10, 7), nullable=True)
    last_longitude = Column(Numeric(10, 7), nullable=True)
    last_location_updated_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    order = relationship("Order", back_populates="delivery")
    rider = relationship("User", foreign_keys=[rider_id])
    locations = relationship("RiderLocation", back_populates="delivery", cascade="all, delete-orphan")


class RiderLocation(Base):
    __tablename__ = "rider_locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    delivery_id = Column(String(36), ForeignKey("deliveries.id", ondelete="CASCADE"), nullable=False, index=True)
    rider_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    latitude = Column(Numeric(10, 7), nullable=False)
    longitude = Column(Numeric(10, 7), nullable=False)
    accuracy = Column(Numeric(10, 2), nullable=True)
    heading = Column(Numeric(6, 2), nullable=True)
    speed = Column(Numeric(6, 2), nullable=True)
    recorded_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    delivery = relationship("Delivery", back_populates="locations")
    rider = relationship("User", foreign_keys=[rider_id])
