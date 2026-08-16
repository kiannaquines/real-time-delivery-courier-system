import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_password_hash
from app.api.deps import require_admin, require_rider
from app.models.user import User, RiderProfile
from app.models.delivery import Delivery
from app.models.order import Order
from app.schemas.rider import CreateRiderRequest, RiderProfileResponse, RiderStatusUpdateRequest
from app.schemas.order import OrderDetail
from app.api.v1.orders import get_order_detail

router = APIRouter(prefix="/riders", tags=["Riders"])


@router.get("", response_model=List[RiderProfileResponse])
def list_riders(current_user: User = Depends(require_admin), db: Session = Depends(get_db)):
    riders = db.query(User).filter(User.role == "rider").all()
    results = []
    for r in riders:
        active_del = db.query(Delivery).filter(
            Delivery.rider_id == r.id,
            Delivery.status.in_(["assigned", "picked_up", "on_the_way"])
        ).first()

        results.append(
            RiderProfileResponse(
                id=r.rider_profile.id if r.rider_profile else r.id,
                user_id=r.id,
                full_name=r.full_name,
                email=r.email,
                phone=r.phone,
                status=r.rider_profile.status if r.rider_profile else "offline",
                vehicle_type=r.rider_profile.vehicle_type if r.rider_profile else "Motorcycle",
                plate_number=r.rider_profile.plate_number if r.rider_profile else "N/A",
                active_delivery_id=active_del.id if active_del else None,
            )
        )
    return results


@router.post("", response_model=RiderProfileResponse, status_code=status.HTTP_201_CREATED)
def create_rider(
    request: CreateRiderRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    existing = db.query(User).filter(User.email == request.email.lower()).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered.")

    user = User(
        id=str(uuid.uuid4()),
        email=request.email.lower(),
        hashed_password=get_password_hash(request.password),
        full_name=request.full_name,
        phone=request.phone,
        role="rider",
        is_active=True,
    )
    db.add(user)
    db.flush()

    profile = RiderProfile(
        id=str(uuid.uuid4()),
        user_id=user.id,
        status="available",
        vehicle_type=request.vehicle_type,
        plate_number=request.plate_number,
    )
    db.add(profile)
    db.commit()
    db.refresh(user)

    return RiderProfileResponse(
        id=profile.id,
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        status=profile.status,
        vehicle_type=profile.vehicle_type,
        plate_number=profile.plate_number,
        active_delivery_id=None,
    )


@router.put("/status", response_model=RiderProfileResponse)
def update_status(
    request: RiderStatusUpdateRequest,
    current_user: User = Depends(require_rider),
    db: Session = Depends(get_db)
):
    profile = current_user.rider_profile
    if not profile:
        profile = RiderProfile(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            status=request.status.value,
            vehicle_type="Motorcycle",
            plate_number="N/A",
        )
        db.add(profile)
    else:
        profile.status = request.status.value

    db.commit()
    db.refresh(profile)

    active_del = db.query(Delivery).filter(
        Delivery.rider_id == current_user.id,
        Delivery.status.in_(["assigned", "picked_up", "on_the_way"])
    ).first()

    return RiderProfileResponse(
        id=profile.id,
        user_id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        phone=current_user.phone,
        status=profile.status,
        vehicle_type=profile.vehicle_type,
        plate_number=profile.plate_number,
        active_delivery_id=active_del.id if active_del else None,
    )


@router.get("/active-delivery", response_model=Optional[OrderDetail])
def get_active_delivery(
    current_user: User = Depends(require_rider),
    db: Session = Depends(get_db)
):
    active_del = db.query(Delivery).filter(
        Delivery.rider_id == current_user.id,
        Delivery.status.in_(["assigned", "picked_up", "on_the_way"])
    ).first()

    if not active_del:
        return None

    return get_order_detail(active_del.order_id, current_user, db)
