import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_refresh_token,
    get_password_hash,
    hash_refresh_token,
    verify_password,
)
from app.models.user import User, RiderProfile
from app.models.misc import RefreshToken
from app.schemas.auth import CustomerRegisterRequest, LoginRequest, AuthTokenResponse, UserSummary


def register_customer(db: Session, request: CustomerRegisterRequest) -> Tuple[User, str, str]:
    existing = db.query(User).filter(User.email == request.email.lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists."
        )

    user = User(
        id=str(uuid.uuid4()),
        email=request.email.lower(),
        hashed_password=get_password_hash(request.password),
        full_name=request.full_name,
        phone=request.phone,
        role="customer",
        is_active=True,
    )
    db.add(user)
    db.flush()

    # Generate tokens
    access_token = create_access_token(subject=user.id, role=user.role)
    raw_refresh = generate_refresh_token()
    refresh_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=hash_refresh_token(raw_refresh),
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        is_revoked=False,
    )
    db.add(refresh_record)
    db.commit()
    db.refresh(user)

    return user, access_token, raw_refresh


def authenticate_user(db: Session, request: LoginRequest) -> Tuple[User, str, str]:
    user = db.query(User).filter(User.email == request.email.lower()).first()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated."
        )

    access_token = create_access_token(subject=user.id, role=user.role)
    raw_refresh = generate_refresh_token()
    refresh_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=hash_refresh_token(raw_refresh),
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        is_revoked=False,
    )
    db.add(refresh_record)
    db.commit()

    return user, access_token, raw_refresh


def rotate_refresh_token(db: Session, raw_token: str) -> Tuple[User, str, str]:
    hashed = hash_refresh_token(raw_token)
    record = db.query(RefreshToken).filter(
        RefreshToken.token_hash == hashed,
        RefreshToken.is_revoked == False
    ).first()

    if not record:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token."
        )

    now = datetime.now(timezone.utc)
    if record.expires_at.replace(tzinfo=timezone.utc) < now:
        record.is_revoked = True
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired."
        )

    # Invalidate old token (one-time use rotation)
    record.is_revoked = True

    user = db.query(User).filter(User.id == record.user_id).first()
    if not user or not user.is_active:
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is invalid or inactive."
        )

    # Issue new pair
    access_token = create_access_token(subject=user.id, role=user.role)
    new_raw_refresh = generate_refresh_token()
    new_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=hash_refresh_token(new_raw_refresh),
        expires_at=now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        is_revoked=False,
    )
    db.add(new_record)
    db.commit()

    return user, access_token, new_raw_refresh


def revoke_all_user_tokens(db: Session, user_id: str):
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.is_revoked == False
    ).update({"is_revoked": True})
    db.commit()
