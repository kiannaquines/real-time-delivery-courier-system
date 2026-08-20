import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_customer
from app.models.user import User, Address
from app.schemas.auth import Address as AddressSchema, AddressCreateRequest

router = APIRouter(prefix="/customers", tags=["Customers"])


@router.get("/addresses", response_model=List[AddressSchema])
def list_addresses(current_user: User = Depends(require_customer), db: Session = Depends(get_db)):
    addresses = db.query(Address).filter(Address.customer_id == current_user.id).order_by(Address.created_at.desc()).all()
    return addresses


@router.post("/addresses", response_model=AddressSchema, status_code=status.HTTP_201_CREATED)
def create_address(
    request: AddressCreateRequest,
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db)
):
    if request.is_default:
        db.query(Address).filter(Address.customer_id == current_user.id).update({"is_default": False})

    address = Address(
        id=str(uuid.uuid4()),
        customer_id=current_user.id,
        label=request.label,
        address_line=request.address_line,
        latitude=request.latitude,
        longitude=request.longitude,
        delivery_notes=request.delivery_notes,
        is_default=request.is_default,
    )
    db.add(address)
    db.commit()
    db.refresh(address)
    return address


@router.put("/addresses/{address_id}/default", response_model=AddressSchema)
def set_default_address(
    address_id: str,
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db)
):
    address = db.query(Address).filter(Address.id == address_id, Address.customer_id == current_user.id).first()
    if not address:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found.")

    db.query(Address).filter(Address.customer_id == current_user.id).update({"is_default": False})
    address.is_default = True
    db.commit()
    db.refresh(address)
    return address


@router.delete("/addresses/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_address(
    address_id: str,
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db)
):
    address = db.query(Address).filter(Address.id == address_id, Address.customer_id == current_user.id).first()
    if not address:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found.")

    db.delete(address)
    db.commit()
    return None
