from enum import Enum
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field
from datetime import datetime


class OrderStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    assigned = "assigned"
    picked_up = "picked_up"
    on_the_way = "on_the_way"
    delivered = "delivered"
    cancelled = "cancelled"


class PaymentStatus(str, Enum):
    unpaid = "unpaid"
    paid = "paid"


class RiderStatus(str, Enum):
    available = "available"
    busy = "busy"
    offline = "offline"


class UserRole(str, Enum):
    customer = "customer"
    rider = "rider"
    admin = "admin"


class SuccessResponse(BaseModel):
    success: bool = True
    message: str = "Operation completed successfully"


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None


class HealthStatus(BaseModel):
    status: str = "ok"
    timestamp: datetime
