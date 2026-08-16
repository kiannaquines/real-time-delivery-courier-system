import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

os.environ["DATABASE_URL"] = "sqlite:///./test_mns.db"
os.environ["DIRECT_DATABASE_URL"] = "sqlite:///./test_mns.db"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-mns-2026"
os.environ["CRON_SECRET"] = "test-cron-secret"

import sys

# Ensure backend root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import Base, get_db
from app.main import app
from app.core.security import get_password_hash, create_access_token
from app.models.user import User, RiderProfile

TEST_SQLALCHEMY_DATABASE_URL = "sqlite:///./test_mns.db"
test_engine = create_engine(TEST_SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    
    # Seed initial Admin, Rider, Customer
    db = TestingSessionLocal()
    
    # Admin
    admin_user = User(
        id="admin-uuid-1",
        email="admin@mns.com",
        hashed_password=get_password_hash("AdminPass123!"),
        full_name="MNS Head Admin",
        phone="+639171112222",
        role="admin",
        is_active=True,
    )
    db.add(admin_user)

    # Rider
    rider_user = User(
        id="rider-uuid-1",
        email="rider@mns.com",
        hashed_password=get_password_hash("RiderPass123!"),
        full_name="John Swift Rider",
        phone="+639173334444",
        role="rider",
        is_active=True,
    )
    db.add(rider_user)
    db.flush()

    rider_prof = RiderProfile(
        id="rider-prof-uuid-1",
        user_id=rider_user.id,
        status="available",
        vehicle_type="Motorcycle",
        plate_number="MNS-8899",
    )
    db.add(rider_prof)

    # Customer
    customer_user = User(
        id="customer-uuid-1",
        email="customer@mns.com",
        hashed_password=get_password_hash("CustomerPass123!"),
        full_name="Alice Customer",
        phone="+639175556666",
        role="customer",
        is_active=True,
    )
    db.add(customer_user)

    db.commit()
    db.close()
    
    yield
    
    Base.metadata.drop_all(bind=test_engine)
    if os.path.exists("./test_mns.db"):
        os.remove("./test_mns.db")


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def admin_headers():
    token = create_access_token("admin-uuid-1", "admin")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def rider_headers():
    token = create_access_token("rider-uuid-1", "rider")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def customer_headers():
    token = create_access_token("customer-uuid-1", "customer")
    return {"Authorization": f"Bearer {token}"}
