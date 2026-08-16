from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class MenuCategory(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    store_id: str
    name: str
    display_order: int


class MenuItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    store_id: str
    category_id: Optional[str] = None
    category_name: Optional[str] = None
    name: str
    description: Optional[str] = None
    price: float
    image_url: Optional[str] = None
    is_available: bool


class MenuItemCreateRequest(BaseModel):
    store_id: str
    category_id: Optional[str] = None
    name: str
    description: Optional[str] = None
    price: float
    image_url: Optional[str] = None
    is_available: bool = True


class MenuItemUpdateRequest(BaseModel):
    category_id: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    image_url: Optional[str] = None
    is_available: Optional[bool] = None


class Store(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    description: Optional[str] = None
    address: str
    latitude: float
    longitude: float
    image_url: Optional[str] = None
    is_active: bool


class StoreCreateRequest(BaseModel):
    name: str
    description: Optional[str] = None
    address: str
    latitude: float
    longitude: float
    image_url: Optional[str] = None
    is_active: bool = True


class StoreUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None


class StoreDetail(BaseModel):
    store: Store
    categories: List[MenuCategory] = []
    items: List[MenuItem] = []
