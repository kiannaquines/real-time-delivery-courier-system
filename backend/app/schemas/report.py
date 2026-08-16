from typing import List, Optional
from pydantic import BaseModel
from app.schemas.order import Order


class SalesReportResponse(BaseModel):
    total_orders: int
    total_sales: float
    total_delivery_fees: float
    orders: List[Order] = []


class RiderPerformanceSummary(BaseModel):
    rider_id: str
    rider_name: str
    completed_deliveries: int
    total_distance_km: float
    average_delivery_time_minutes: float


class RiderReportResponse(BaseModel):
    riders: List[RiderPerformanceSummary] = []
