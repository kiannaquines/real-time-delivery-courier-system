from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.common import OrderStatus


class LocationCoord(BaseModel):
    latitude: float
    longitude: float


class RiderLocationPoint(BaseModel):
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    heading: Optional[float] = None
    speed: Optional[float] = None
    timestamp: datetime


class RiderLocationBatchRequest(BaseModel):
    locations: List[RiderLocationPoint]


class DeliveryStatusUpdateRequest(BaseModel):
    status: OrderStatus
    cod_collected: bool = False
    audit_reason: Optional[str] = None


class Delivery(BaseModel):
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


class DeliverySnapshot(BaseModel):
    delivery_id: str
    order_id: str
    status: OrderStatus
    rider_id: Optional[str] = None
    rider_name: Optional[str] = None
    rider_phone: Optional[str] = None
    store_location: Optional[LocationCoord] = None
    destination_location: Optional[LocationCoord] = None
    last_rider_location: Optional[RiderLocationPoint] = None
    eta_seconds: Optional[int] = None
    remaining_distance_meters: Optional[float] = None
