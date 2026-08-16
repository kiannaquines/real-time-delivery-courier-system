from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from app.schemas.common import UserRole


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class CustomerRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str
    phone: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserSummary(BaseModel):
    id: str
    email: str
    full_name: str
    role: UserRole
    phone: Optional[str] = None


class AuthTokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int
    user: UserSummary


class UserDetailResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: UserRole
    phone: Optional[str] = None
    created_at: datetime


class AddressBase(BaseModel):
    label: str
    address_line: str
    latitude: float
    longitude: float
    delivery_notes: Optional[str] = None
    is_default: bool = False


class AddressCreateRequest(AddressBase):
    pass


class Address(AddressBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    customer_id: str
    created_at: datetime
