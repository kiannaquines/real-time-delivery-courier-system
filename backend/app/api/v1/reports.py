from datetime import date
from typing import Optional, Union
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.schemas.report import SalesReportResponse, RiderReportResponse
from app.services.report_service import generate_sales_report, generate_rider_report

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get("/sales", response_model=SalesReportResponse)
def get_sales_report(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    store_id: Optional[str] = Query(None),
    format: Optional[str] = Query("json"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    report_json, csv_string = generate_sales_report(db, start_date, end_date, store_id)
    if format == "csv":
        return Response(content=csv_string, media_type="text/csv", headers={"Content-Disposition": "attachment; filename=sales_report.csv"})
    return report_json


@router.get("/riders", response_model=RiderReportResponse)
def get_rider_report(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    return generate_rider_report(db, start_date, end_date)
