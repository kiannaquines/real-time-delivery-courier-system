import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User, RiderProfile, Address
from app.models.store import Store, MenuCategory, MenuItem


def seed_data():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Clear existing data if present to ensure clean state
    db.query(MenuItem).delete()
    db.query(MenuCategory).delete()
    db.query(Store).delete()
    db.query(Address).delete()
    db.query(RiderProfile).delete()
    db.query(User).delete()
    db.commit()

    print("Seeding M&S Delivery Express Kabacan initial database data...")

    # 1. Admin User
    admin = User(
        id=str(uuid.uuid4()),
        email="admin@mns.com",
        hashed_password=get_password_hash("AdminPass123!"),
        full_name="M&S Head Admin",
        phone="+63 917 111 2222",
        role="admin",
        is_active=True,
    )
    db.add(admin)

    # 2. Rider User
    rider = User(
        id=str(uuid.uuid4()),
        email="rider@mns.com",
        hashed_password=get_password_hash("RiderPass123!"),
        full_name="Carlos Swift Rider",
        phone="+63 917 333 4444",
        role="rider",
        is_active=True,
    )
    db.add(rider)
    db.flush()

    rider_profile = RiderProfile(
        id=str(uuid.uuid4()),
        user_id=rider.id,
        status="available",
        vehicle_type="Yamaha NMAX 155",
        plate_number="MNS-7788",
        current_latitude=7.1265,
        current_longitude=124.8295,
    )
    db.add(rider_profile)

    # 3. Customer User
    customer = User(
        id=str(uuid.uuid4()),
        email="customer@mns.com",
        hashed_password=get_password_hash("CustomerPass123!"),
        full_name="Alice Rivera",
        phone="+63 917 555 6666",
        role="customer",
        is_active=True,
    )
    db.add(customer)
    db.flush()

    # Customer default address in Kabacan
    addr = Address(
        id=str(uuid.uuid4()),
        customer_id=customer.id,
        label="Home (Poblacion)",
        address_line="Purok Miracle, Poblacion, Kabacan, Cotabato",
        latitude=7.1280,
        longitude=124.8310,
        delivery_notes="Near USM Gate 1",
        is_default=True,
    )
    db.add(addr)

    # 4. Stores in Kabacan
    store1 = Store(
        id=str(uuid.uuid4()),
        name="Rose Garden Restaurant - Kabacan",
        description="Fresh burgers, crispy fried chicken, halal dishes and local specialties",
        address="National Highway, Poblacion, Kabacan, Cotabato",
        latitude=7.1264,
        longitude=124.8290,
        is_active=True,
    )
    store2 = Store(
        id=str(uuid.uuid4()),
        name="M&S Express Kitchen - USM Kabacan",
        description="Quick bites, rice bowls, artisanal snacks and refreshing drinks for students & faculty",
        address="University of Southern Mindanao Commercial Center, Kabacan",
        latitude=7.1245,
        longitude=124.8270,
        is_active=True,
    )
    db.add_all([store1, store2])
    db.flush()

    # 5. Menu Categories & Items for Rose Garden Restaurant
    cat_burgers = MenuCategory(id=str(uuid.uuid4()), store_id=store1.id, name="Burgers & Sandwiches", display_order=1)
    cat_chicken = MenuCategory(id=str(uuid.uuid4()), store_id=store1.id, name="Chicken & Rice Meals", display_order=2)
    cat_pizza = MenuCategory(id=str(uuid.uuid4()), store_id=store1.id, name="Pizza & Pasta", display_order=3)
    cat_drinks = MenuCategory(id=str(uuid.uuid4()), store_id=store1.id, name="Beverages", display_order=4)
    db.add_all([cat_burgers, cat_chicken, cat_pizza, cat_drinks])
    db.flush()

    items = [
        MenuItem(
            id=str(uuid.uuid4()),
            store_id=store1.id,
            category_id=cat_burgers.id,
            name="Classic Cheeseburger Deluxe",
            description="Juicy flame-grilled beef patty with cheddar cheese, lettuce, and special sauce.",
            price=120.00,
            is_available=True,
        ),
        MenuItem(
            id=str(uuid.uuid4()),
            store_id=store1.id,
            category_id=cat_chicken.id,
            name="2pc Crispy Fried Chicken with Rice",
            description="Golden crunchy fried chicken served with garlic rice and savory gravy.",
            price=165.00,
            is_available=True,
        ),
        MenuItem(
            id=str(uuid.uuid4()),
            store_id=store1.id,
            category_id=cat_pizza.id,
            name="Pepperoni Supreme Pizza",
            description="Loaded with premium beef pepperoni, mozzarella cheese, and rich tomato sauce.",
            price=290.00,
            is_available=True,
        ),
        MenuItem(
            id=str(uuid.uuid4()),
            store_id=store1.id,
            category_id=cat_drinks.id,
            name="Iced Milk Tea Deluxe",
            description="Freshly brewed black tea with rich creamy milk and brown sugar pearls.",
            price=85.00,
            is_available=True,
        ),
    ]
    db.add_all(items)

    db.commit()
    db.close()
    print("Database seeding completed successfully for M&S Kabacan!")


if __name__ == "__main__":
    seed_data()
