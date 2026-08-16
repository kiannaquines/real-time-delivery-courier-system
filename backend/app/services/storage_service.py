import uuid
from typing import Tuple
from fastapi import HTTPException, status
from app.core.config import settings
from app.schemas.upload import SignedUploadUrlRequest, SignedUploadUrlResponse

ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"]
MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


def generate_signed_upload_url(request: SignedUploadUrlRequest) -> SignedUploadUrlResponse:
    if request.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported content type '{request.content_type}'. Allowed: {ALLOWED_MIME_TYPES}"
        )

    if request.size_bytes > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File exceeds maximum size of 5 MB."
        )

    ext = "jpg"
    if "png" in request.content_type:
        ext = "png"
    elif "webp" in request.content_type:
        ext = "webp"

    object_id = str(uuid.uuid4())
    object_path = f"uploads/{object_id}.{ext}"

    # Supabase signed upload endpoint structure
    supabase_url = settings.SUPABASE_URL.rstrip("/")
    bucket = settings.SUPABASE_STORAGE_BUCKET
    upload_url = f"{supabase_url}/storage/v1/object/upload/sign/{bucket}/{object_path}"
    public_url = f"{supabase_url}/storage/v1/object/public/{bucket}/{object_path}"

    return SignedUploadUrlResponse(
        upload_url=upload_url,
        object_path=object_path,
        public_url=public_url,
        expires_in=900,  # 15 minutes
    )
