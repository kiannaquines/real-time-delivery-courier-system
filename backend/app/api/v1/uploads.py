from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.schemas.upload import SignedUploadUrlRequest, SignedUploadUrlResponse, FinalizeUploadRequest
from app.schemas.common import SuccessResponse
from app.services.storage_service import generate_signed_upload_url

router = APIRouter(prefix="/uploads", tags=["Uploads"])


@router.post("/signed-url", response_model=SignedUploadUrlResponse)
def get_signed_url(
    request: SignedUploadUrlRequest,
    current_user: User = Depends(require_admin)
):
    return generate_signed_upload_url(request)


@router.post("/finalize", response_model=SuccessResponse)
def finalize_upload(
    request: FinalizeUploadRequest,
    current_user: User = Depends(require_admin)
):
    # In production, verify file exists in Supabase storage bucket
    return SuccessResponse(message=f"Upload finalized for {request.object_path}")
