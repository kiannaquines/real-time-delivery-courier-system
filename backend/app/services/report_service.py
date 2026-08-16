import csv
import io
from datetime import date, datetime, time, timezone
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.order import Order
from app.models.delivery import Delivery
from app.models.user import User, RiderProfile
from app.schemas.report import SalesReportResponse, RiderReportResponse, RiderPerformanceSummary
from app.schemas.order import Order as OrderSchema


def generate_sales_report(
    db: Session,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    store_id: Optional[str] = None
) -> Tuple[SalesReportResponse, str]:
    query = db.query(Order)

    if start_date:
        start_dt = datetime.combine(start_date, time.min).replace(tzinfo=timezone.utc)
        query = query.filter(Order.created_at >= start_dt)
    if end_date:
        end_dt = datetime.combine(end_date, time.max).replace(tzinfo=timezone.utc)
        query = query.filter(Order.created_at <= end_dt)
    if store_id:
        query = query.filter(Order.store_id == store_id)

    orders = query.order_by(Order.created_at.desc()).all()

    total_orders = len(orders)
    total_sales = sum(float(o.total_amount) for o in orders if o.status == "delivered")
    total_fees = sum(float(o.delivery_fee) for o in orders if o.status == "delivered")

    order_schemas = []
    for o in orders:
        order_schemas.append(
            OrderSchema(
                id=o.id,
                order_number=o.order_number,
                customer_id=o.customer_id,
                customer_name=o.customer.full_name if o.customer else "N/A",
                customer_phone=o.customer.phone if o.customer else "N/A",
                store_id=o.store_id,
                store_name=o.store.name if o.store else "N/A",
                status=o.status,
                subtotal=float(o.subtotal),
                delivery_fee=float(o.delivery_fee),
                total_amount=float(o.total_amount),
                payment_status=o.payment.status if o.payment else "unpaid",
                delivery_address=o.delivery_address,
                delivery_latitude=float(o.delivery_latitude),
                delivery_longitude=float(o.delivery_longitude),
                created_at=o.created_at,
            )
        )

    # Generate CSV buffer
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Order Number", "Date", "Customer", "Store", "Status", "Subtotal", "Delivery Fee", "Total Amount", "Payment Status"])
    for o in order_schemas:
        writer.writerow([
            o.order_number,
            o.created_at.strftime("%Y-%m-%d %H:%M"),
            o.customer_name,
            o.store_name,
            o.status,
            f"{o.subtotal:.2f}",
            f"{o.delivery_fee:.2f}",
            f"{o.total_amount:.2f}",
            o.payment_status
        ])

    csv_data = output.getvalue()
    response = SalesReportResponse(
        total_orders=total_orders,
        total_sales=round(total_sales, 2),
        total_delivery_fees=round(total_fees, 2),
        orders=order_schemas,
    )
    return response, csv_data


def generate_rider_report(
    db: Session,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None
) -> RiderReportResponse:
    riders = db.query(User).filter(User.role == "rider").all()
    summaries = []

    for r in riders:
        del_query = db.query(Delivery).filter(Delivery.rider_id == r.id, Delivery.status == "delivered")
        if start_date:
            start_dt = datetime.combine(start_date, time.min).replace(tzinfo=timezone.utc)
            del_query = del_query.filter(Delivery.delivered_at >= start_dt)
        if end_date:
            end_dt = datetime.combine(end_date, time.max).replace(tzinfo=timezone.utc)
            del_query = del_query.filter(Delivery.delivered_at <= end_dt)

        completed_deliveries = del_query.all()
        count = len(completed_deliveries)
        total_dist = sum(float(d.order.route_distance_km) for d in completed_deliveries if d.order)
        
        avg_time = 0.0
        if count > 0:
            durations = []
            for d in completed_deliveries:
                if d.picked_up_at and d.delivered_at:
                    dur_min = (d.delivered_at - d.picked_up_at).total_seconds() / 60.0
                    durations.append(dur_min)
            if durations:
                avg_time = sum(durations) / len(durations)

        summaries.append(
            RiderPerformanceSummary(
                rider_id=r.id,
                rider_name=r.full_name,
                completed_deliveries=count,
                total_distance_km=round(total_dist, 2),
                average_delivery_time_minutes=round(avg_time, 1),
            )
        )

    return RiderReportResponse(riders=summaries)
