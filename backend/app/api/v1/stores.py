import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.models.store import Store, MenuCategory, MenuItem
from app.schemas.store import Store as StoreSchema, StoreCreateRequest, StoreUpdateRequest, StoreDetail, MenuCategory as MenuCategorySchema, MenuItem as MenuItemSchema

router = APIRouter(prefix="/stores", tags=["Stores"])


@router.get("", response_model=List[StoreSchema])
def list_stores(is_active: Optional[bool] = Query(None), db: Session = Depends(get_db)):
    query = db.query(Store)
    if is_active is not None:
        query = query.filter(Store.is_active == is_active)
    stores = query.order_by(Store.name.asc()).all()
    return stores


@router.post("", response_model=StoreSchema, status_code=status.HTTP_201_CREATED)
def create_store(
    request: StoreCreateRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    store = Store(
        id=str(uuid.uuid4()),
        name=request.name,
        description=request.description,
        address=request.address,
        latitude=request.latitude,
        longitude=request.longitude,
        image_url=request.image_url,
        is_active=request.is_active,
    )
    db.add(store)
    db.commit()
    db.refresh(store)
    return store


@router.get("/{store_id}", response_model=StoreDetail)
def get_store_detail(store_id: str, db: Session = Depends(get_db)):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found.")

    categories = db.query(MenuCategory).filter(MenuCategory.store_id == store.id).order_by(MenuCategory.display_order.asc()).all()
    items = db.query(MenuItem).filter(MenuItem.store_id == store.id).all()

    item_schemas = []
    category_map = {c.id: c.name for c in categories}
    for it in items:
        item_schemas.append(
            MenuItemSchema(
                id=it.id,
                store_id=it.store_id,
                category_id=it.category_id,
                category_name=category_map.get(it.category_id),
                name=it.name,
                description=it.description,
                price=float(it.price),
                image_url=it.image_url,
                is_available=it.is_available,
            )
        )

    return StoreDetail(
        store=StoreSchema.model_validate(store),
        categories=[MenuCategorySchema.model_validate(c) for c in categories],
        items=item_schemas,
    )


@router.put("/{store_id}", response_model=StoreSchema)
def update_store(
    store_id: str,
    request: StoreUpdateRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found.")

    for field, val in request.model_dump(exclude_unset=True).items():
        setattr(store, field, val)

    db.commit()
    db.refresh(store)
    return store
