from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import settings
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.auth import (
    CustomerRegisterRequest,
    LoginRequest,
    RefreshTokenRequest,
    AuthTokenResponse,
    UserSummary,
    UserDetailResponse,
)
from app.schemas.common import SuccessResponse
from app.services.auth_service import (
    register_customer,
    authenticate_user,
    rotate_refresh_token,
    revoke_all_user_tokens,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=AuthTokenResponse, status_code=status.HTTP_201_CREATED)
def register(request: CustomerRegisterRequest, db: Session = Depends(get_db)):
    user, access_token, refresh_token = register_customer(db, request)
    return AuthTokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="Bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserSummary(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            phone=user.phone,
        )
    )


@router.post("/login", response_model=AuthTokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user, access_token, refresh_token = authenticate_user(db, request)
    return AuthTokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="Bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserSummary(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            phone=user.phone,
        )
    )


@router.post("/refresh", response_model=AuthTokenResponse)
def refresh(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    user, access_token, refresh_token = rotate_refresh_token(db, request.refresh_token)
    return AuthTokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="Bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserSummary(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            phone=user.phone,
        )
    )


@router.post("/logout", response_model=SuccessResponse)
def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    revoke_all_user_tokens(db, current_user.id)
    return SuccessResponse(message="Successfully logged out.")


@router.get("/me", response_model=UserDetailResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return UserDetailResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        role=current_user.role,
        phone=current_user.phone,
        created_at=current_user.created_at,
    )
