import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
import bcrypt
import jwt

from app.core.config import settings


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def create_access_token(subject: str, role: str, extra_claims: Optional[Dict[str, Any]] = None) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    payload: Dict[str, Any] = {
        "sub": str(subject),
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
        "iss": "mns-delivery-api",
    }
    
    if extra_claims:
        payload.update(extra_claims)

    headers = {"kid": settings.JWT_KEY_ID}

    if settings.JWT_ALGORITHM.startswith("RS") and settings.JWT_SIGNING_PRIVATE_KEY:
        return jwt.encode(payload, settings.JWT_SIGNING_PRIVATE_KEY, algorithm=settings.JWT_ALGORITHM, headers=headers)
    else:
        return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm="HS256", headers=headers)


def decode_access_token(token: str) -> Dict[str, Any]:
    try:
        if settings.JWT_ALGORITHM.startswith("RS") and settings.JWT_VERIFYING_PUBLIC_KEY:
            payload = jwt.decode(
                token,
                settings.JWT_VERIFYING_PUBLIC_KEY,
                algorithms=[settings.JWT_ALGORITHM],
                issuer="mns-delivery-api"
            )
        else:
            payload = jwt.decode(
                token,
                settings.JWT_SECRET_KEY,
                algorithms=["HS256"],
                issuer="mns-delivery-api"
            )
        return payload
    except jwt.PyJWTError as e:
        raise ValueError(f"Invalid token: {str(e)}")


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(64)


def hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
