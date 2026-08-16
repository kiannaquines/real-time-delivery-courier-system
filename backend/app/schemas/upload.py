from pydantic import BaseModel


class SignedUploadUrlRequest(BaseModel):
    filename: str
    content_type: str
    size_bytes: int


class SignedUploadUrlResponse(BaseModel):
    upload_url: str
    object_path: str
    public_url: str
    expires_in: int


class FinalizeUploadRequest(BaseModel):
    object_path: str


class CronJobResponse(BaseModel):
    processed_count: int
    failed_count: int
