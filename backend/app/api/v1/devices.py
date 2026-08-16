import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.misc import DeviceToken
from app.schemas.rider import DeviceTokenRequest
from app.schemas.common import SuccessResponse

router = APIRouter(prefix="/devices", tags=["Devices"])


@router.post("/token", response_model=SuccessResponse)
def register_token(
    request: DeviceTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    token_record = db.query(DeviceToken).filter(DeviceToken.token == request.token).first()
    if token_record:
        token_record.user_id = current_user.id
        token_record.platform = request.platform
    else:
        token_record = DeviceToken(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            token=request.token,
            platform=request.platform,
        )
        db.add(token_record)

    db.commit()
    return SuccessResponse(message="Device token registered.")
