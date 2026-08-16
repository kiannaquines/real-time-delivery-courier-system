from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from app.schemas.common import RiderStatus


class CreateRiderRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str
    phone: str
    vehicle_type: str = "Motorcycle"
    plate_number: str


class RiderProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    full_name: str
    email: str
    phone: str
    status: RiderStatus
    vehicle_type: str
    plate_number: str
    active_delivery_id: Optional[str] = None


class RiderStatusUpdateRequest(BaseModel):
    status: RiderStatus


class DeviceTokenRequest(BaseModel):
    token: str
    platform: str # android, ios, web
