import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.models.store import MenuItem, MenuCategory, Store
from app.schemas.store import MenuItem as MenuItemSchema, MenuItemCreateRequest, MenuItemUpdateRequest
from app.schemas.common import SuccessResponse

router = APIRouter(prefix="/menu-items", tags=["Menu Items"])


@router.post("", response_model=MenuItemSchema, status_code=status.HTTP_201_CREATED)
def create_menu_item(
    request: MenuItemCreateRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    store = db.query(Store).filter(Store.id == request.store_id).first()
    if not store:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found.")

    category_name = None
    if request.category_id:
        category = db.query(MenuCategory).filter(MenuCategory.id == request.category_id).first()
        if category:
            category_name = category.name

    item = MenuItem(
        id=str(uuid.uuid4()),
        store_id=request.store_id,
        category_id=request.category_id,
        name=request.name,
        description=request.description,
        price=request.price,
        image_url=request.image_url,
        is_available=request.is_available,
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    return MenuItemSchema(
        id=item.id,
        store_id=item.store_id,
        category_id=item.category_id,
        category_name=category_name,
        name=item.name,
        description=item.description,
        price=float(item.price),
        image_url=item.image_url,
        is_available=item.is_available,
    )


@router.put("/{item_id}", response_model=MenuItemSchema)
def update_menu_item(
    item_id: str,
    request: MenuItemUpdateRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu item not found.")

    for field, val in request.model_dump(exclude_unset=True).items():
        setattr(item, field, val)

    db.commit()
    db.refresh(item)

    category_name = item.category.name if item.category else None
    return MenuItemSchema(
        id=item.id,
        store_id=item.store_id,
        category_id=item.category_id,
        category_name=category_name,
        name=item.name,
        description=item.description,
        price=float(item.price),
        image_url=item.image_url,
        is_available=item.is_available,
    )


@router.delete("/{item_id}", response_model=SuccessResponse)
def delete_menu_item(
    item_id: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Menu item not found.")

    db.delete(item)
    db.commit()
    return SuccessResponse(message="Menu item successfully deleted.")
