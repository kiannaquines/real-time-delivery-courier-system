import os
from typing import List
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    APP_ENV: str = "development"
    API_BASE_URL: str = "http://localhost:8000"
    
    # Database (uses absolute path for local SQLite persistence)
    DATABASE_URL: str = f"sqlite:///{os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'mns_delivery.db'))}"
    DIRECT_DATABASE_URL: str = f"sqlite:///{os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'mns_delivery.db'))}"
    
    # Supabase
    SUPABASE_URL: str = "https://example.supabase.co"
    SUPABASE_PUBLISHABLE_KEY: str = "dummy-anon-key"
    SUPABASE_SECRET_KEY: str = "dummy-service-role-key"
    SUPABASE_STORAGE_BUCKET: str = "menu-images"
    
    # Security / JWT
    JWT_ALGORITHM: str = "HS256"
    JWT_SECRET_KEY: str = "insecure-default-secret-key-change-in-production-mns-2026"
    JWT_SIGNING_PRIVATE_KEY: str = ""
    JWT_VERIFYING_PUBLIC_KEY: str = ""
    JWT_KEY_ID: str = "mns-key-1"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Pricing & Delivery
    BASE_DELIVERY_FEE: float = 49.00
    PER_KM_DELIVERY_FEE: float = 12.00
    
    # Integrations
    MAPBOX_SECRET_TOKEN: str = "dummy-mapbox-token"
    FIREBASE_SERVICE_ACCOUNT_B64: str = ""
    
    # CORS & Web
    ALLOWED_ORIGINS: List[str] = ["*"]
    ADMIN_WEB_URL: str = "http://localhost:3000"
    
    # Maintenance
    CRON_SECRET: str = "mns-cron-secret-key"
    LOCATION_RETENTION_DAYS: int = 30

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        return ["*"]


settings = Settings()
