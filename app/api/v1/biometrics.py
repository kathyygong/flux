from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.biometric import Biometric
from app.models.user import User

router = APIRouter(prefix="/biometrics", tags=["biometrics"])


class BiometricPayload(BaseModel):
    user_id: int
    recorded_date: date
    hrv: float | None = None
    sleep_duration_min: int | None = None
    resting_hr: int | None = None
    source: str | None = "Apple Health"


@router.post("")
def ingest_biometrics(payload: BiometricPayload, db: Session = Depends(get_db)):
    # Verify user exists
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if entry already exists for this date and user
    existing_entry = db.query(Biometric).filter(
        Biometric.user_id == payload.user_id,
        Biometric.recorded_date == payload.recorded_date
    ).first()

    if existing_entry:
        # Update existing
        if payload.hrv is not None:
            existing_entry.hrv = payload.hrv
        if payload.sleep_duration_min is not None:
            existing_entry.sleep_duration_min = payload.sleep_duration_min
        if payload.resting_hr is not None:
            existing_entry.resting_hr = payload.resting_hr
        existing_entry.source = payload.source
        biometric = existing_entry
    else:
        # Create new
        biometric = Biometric(
            user_id=payload.user_id,
            recorded_date=payload.recorded_date,
            hrv=payload.hrv,
            sleep_duration_min=payload.sleep_duration_min,
            resting_hr=payload.resting_hr,
            source=payload.source
        )
        db.add(biometric)

    db.commit()
    db.refresh(biometric)

    return {
        "status": "success",
        "data": {
            "id": biometric.id,
            "recorded_date": biometric.recorded_date,
            "hrv": biometric.hrv,
            "sleep_duration_min": biometric.sleep_duration_min,
            "resting_hr": biometric.resting_hr,
            "source": biometric.source
        }
    }


@router.get("/{user_id}")
def get_user_biometrics(user_id: int, limit: int = 7, db: Session = Depends(get_db)):
    biometrics = db.query(Biometric).filter(
        Biometric.user_id == user_id
    ).order_by(Biometric.recorded_date.desc()).limit(limit).all()

    return {
        "status": "success",
        "data": [
            {
                "id": b.id,
                "recorded_date": b.recorded_date,
                "hrv": b.hrv,
                "sleep_duration_min": b.sleep_duration_min,
                "resting_hr": b.resting_hr,
                "source": b.source
            } for b in biometrics
        ]
    }
