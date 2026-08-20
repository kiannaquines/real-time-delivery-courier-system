import os
import sys
import uuid
import argparse

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User, RiderProfile, Address
from app.models.store import Store, MenuCategory, MenuItem
from app.models.order import Order, OrderItem, Payment
from app.models.delivery import Delivery, RiderLocation
from app.models.misc import RefreshToken, DeviceToken, OutboxEvent, AuditLog, IdempotencyKey

# Static Deterministic UUIDs for development stability
ADMIN_ID = "00000000-0000-4000-8000-000000000001"
RIDER_ID = "00000000-0000-4000-8000-000000000002"
CUSTOMER_ID = "00000000-0000-4000-8000-000000000003"
STORE_1_ID = "00000000-0000-4000-8000-000000000010"
STORE_2_ID = "00000000-0000-4000-8000-000000000020"


def reset_all_tables(db):
    """Deletes all records in strict reverse foreign-key dependency order."""
    print("Clearing all existing database tables in safe reverse FK dependency order...")
    db.query(RiderLocation).delete()
    db.query(Delivery).delete()
    db.query(Payment).delete()
    db.query(OrderItem).delete()
    db.query(Order).delete()
    db.query(MenuItem).delete()
    db.query(MenuCategory).delete()
    db.query(Store).delete()
    db.query(Address).delete()
    db.query(RiderProfile).delete()
    db.query(RefreshToken).delete()
    db.query(DeviceToken).delete()
    db.query(AuditLog).delete()
    db.query(IdempotencyKey).delete()
    db.query(OutboxEvent).delete()
    db.query(User).delete()
    db.commit()


def seed_data(reset: bool = False):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    if reset:
        reset_all_tables(db)

    print("Ensuring M&S Delivery Express Kabacan core data & deterministic accounts...")

    # 1. Admin User
    admin = db.query(User).filter(User.email == "admin@mns.com").first()
    if not admin:
        admin = User(
            id=ADMIN_ID,
            email="admin@mns.com",
            hashed_password=get_password_hash("AdminPass123!"),
            full_name="M&S Head Admin",
            phone="+63 917 111 2222",
            role="admin",
            is_active=True,
        )
        db.add(admin)
        db.flush()

    # 2. Rider User
    rider = db.query(User).filter(User.email == "rider@mns.com").first()
    if not rider:
        rider = User(
            id=RIDER_ID,
            email="rider@mns.com",
            hashed_password=get_password_hash("RiderPass123!"),
            full_name="Carlos Swift Rider",
            phone="+63 917 333 4444",
            role="rider",
            is_active=True,
        )
        db.add(rider)
        db.flush()

    rider_profile = db.query(RiderProfile).filter(RiderProfile.user_id == rider.id).first()
    if not rider_profile:
        rider_profile = RiderProfile(
            id="00000000-0000-4000-8000-000000000004",
            user_id=rider.id,
            status="available",
            vehicle_type="Yamaha NMAX 155",
            plate_number="MNS-7788",
            current_latitude=7.1265,
            current_longitude=124.8295,
        )
        db.add(rider_profile)

    # 3. Customer User
    customer = db.query(User).filter(User.email == "customer@mns.com").first()
    if not customer:
        customer = User(
            id=CUSTOMER_ID,
            email="customer@mns.com",
            hashed_password=get_password_hash("CustomerPass123!"),
            full_name="Alice Rivera",
            phone="+63 917 555 6666",
            role="customer",
            is_active=True,
        )
        db.add(customer)
        db.flush()

    customer_address = db.query(Address).filter(Address.customer_id == customer.id).first()
    if not customer_address:
        customer_address = Address(
            id="00000000-0000-4000-8000-000000000005",
            customer_id=customer.id,
            label="Home (Purok Miracle)",
            address_line="Purok Miracle, Poblacion, Kabacan, Cotabato",
            latitude=7.1280,
            longitude=124.8310,
            delivery_notes="Beside yellow gate, near USM entrance",
            is_default=True,
        )
        db.add(customer_address)

    # 4. Partner Store 1: Rose Garden Restaurant
    store_1 = db.query(Store).filter(Store.id == STORE_1_ID).first()
    if not store_1:
        store_1 = Store(
            id=STORE_1_ID,
            name="Rose Garden Restaurant",
            description="Famous crispy fried chicken, specialty burgers, and native Filipino favorites in Kabacan.",
            address="Poblacion, Kabacan, Cotabato",
            latitude=7.1275,
            longitude=124.8320,
            is_active=True,
        )
        db.add(store_1)
        db.flush()

        cat_1a = MenuCategory(
            id=str(uuid.uuid4()),
            store_id=store_1.id,
            name="Best Sellers",
            display_order=1,
        )
        cat_1b = MenuCategory(
            id=str(uuid.uuid4()),
            store_id=store_1.id,
            name="Burgers & Snacks",
            display_order=2,
        )
        db.add_all([cat_1a, cat_1b])
        db.flush()

        item_1a = MenuItem(
            id=str(uuid.uuid4()),
            store_id=store_1.id,
            category_id=cat_1a.id,
            name="Crispy Fried Chicken Meal",
            description="2-piece golden crispy fried chicken with rice, gravy, and iced tea.",
            price=145.00,
            is_available=True,
        )
        item_1b = MenuItem(
            id=str(uuid.uuid4()),
            store_id=store_1.id,
            category_id=cat_1b.id,
            name="Classic Cheeseburger Deluxe",
            description="Charbroiled 100% beef patty with melted cheddar, lettuce, tomatoes, and secret sauce.",
            price=95.00,
            is_available=True,
        )
        db.add_all([item_1a, item_1b])

    # 5. Partner Store 2: M&S Express Kitchen - USM Kabacan
    store_2 = db.query(Store).filter(Store.id == STORE_2_ID).first()
    if not store_2:
        store_2 = Store(
            id=STORE_2_ID,
            name="M&S Express Kitchen - USM Kabacan",
            description="Freshly baked artisan pastries, milk teas, and sizzling rice meals for students and locals.",
            address="USM Avenue, Kabacan, Cotabato",
            latitude=7.1245,
            longitude=124.8350,
            is_active=True,
        )
        db.add(store_2)
        db.flush()

        cat_2a = MenuCategory(
            id=str(uuid.uuid4()),
            store_id=store_2.id,
            name="Milk Tea & Refreshments",
            display_order=1,
        )
        db.add(cat_2a)
        db.flush()

        item_2a = MenuItem(
            id=str(uuid.uuid4()),
            store_id=store_2.id,
            category_id=cat_2a.id,
            name="Brown Sugar Pearl Milk Tea (Large)",
            description="Signature roasted brown sugar tiger milk with chewy tapioca pearls.",
            price=85.00,
            is_available=True,
        )
        db.add(item_2a)

    # 6. Sample Order Check
    existing_order = db.query(Order).first()
    if not existing_order:
        first_item = db.query(MenuItem).first()
        order_1 = Order(
            id="00000000-0000-4000-8000-000000000099",
            order_number="MNS-260816-A102",
            customer_id=customer.id,
            store_id=store_1.id,
            status="on_the_way",
            subtotal=240.00,
            delivery_fee=49.00,
            total_amount=289.00,
            delivery_address="Purok Miracle, Poblacion, Kabacan, Cotabato",
            delivery_latitude=7.1280,
            delivery_longitude=124.8310,
        )
        db.add(order_1)
        db.flush()

        if first_item:
            order_item = OrderItem(
                id=str(uuid.uuid4()),
                order_id=order_1.id,
                menu_item_id=first_item.id,
                item_name=first_item.name,
                unit_price=first_item.price,
                quantity=1,
                subtotal=first_item.price,
            )
            db.add(order_item)

        order_payment = Payment(
            id=str(uuid.uuid4()),
            order_id=order_1.id,
            amount=289.00,
            status="unpaid",
            method="cash_on_delivery",
        )
        order_delivery = Delivery(
            id="00000000-0000-4000-8000-000000000098",
            order_id=order_1.id,
            rider_id=rider.id,
            status="on_the_way",
            last_latitude=7.1265,
            last_longitude=124.8295,
        )
        db.add_all([order_payment, order_delivery])

    db.commit()
    db.close()
    print("Database seeding verified successfully for M&S Kabacan!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed database")
    parser.add_argument("--reset", action="store_true", help="Reset all data before seeding")
    args = parser.parse_args()
    seed_data(reset=args.reset)
