import hashlib
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.models.training_plan import TrainingPlan

router = APIRouter(prefix="/auth", tags=["auth"])

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

class SignupRequest(BaseModel):
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str
    
class GoogleAuthRequest(BaseModel):
    email: str
    
class ProfileUpdateRequest(BaseModel):
    full_name: str | None = None
    profile_picture: str | None = None

def provision_dummy_plan(db: Session, user_id: int):
    plan = TrainingPlan(
        user_id=user_id,
        name="Base Building",
        goal_race="General Fitness",
        weeks=12,
        description="A dynamically generated base building plan."
    )
    db.add(plan)
    db.commit()

@router.post("/signup")
def signup(request: SignupRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    if user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    user = User(
        email=request.email, 
        password_hash=hash_password(request.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    provision_dummy_plan(db, user.id)
    
    return {"status": "success", "data": {"id": user.id, "email": user.email, "full_name": user.full_name, "is_new": True}}

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    if not user or user.password_hash != hash_password(request.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
        
    return {"status": "success", "data": {"id": user.id, "email": user.email, "full_name": user.full_name, "is_new": False}}

from fastapi.responses import RedirectResponse
import json
from urllib import request, error
from app.services.google_calendar_service import GoogleCalendarService

@router.get("/google/login")
def google_auth_start():
    oauth_url = GoogleCalendarService.build_oauth_url(
        state="auth",
        redirect_uri="http://localhost:8000/api/v1/auth/google/callback",
        scopes="https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/calendar.readonly"
    )
    return RedirectResponse(url=oauth_url)

@router.get("/google/callback")
def google_auth_callback(code: str, db: Session = Depends(get_db)):
    try:
        token_response = GoogleCalendarService.exchange_code_for_token(
            code=code,
            redirect_uri="http://localhost:8000/api/v1/auth/google/callback"
        )
        access_token = token_response.get("access_token")
        refresh_token = token_response.get("refresh_token")
        
        # Fetch user info from Google
        req = request.Request(
            url="https://www.googleapis.com/oauth2/v2/userinfo",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        with request.urlopen(req) as response:
            user_info = json.loads(response.read().decode("utf-8"))
            
        email = user_info.get("email")
        full_name = user_info.get("name")
        
        user = db.query(User).filter(User.email == email).first()
        is_new = False
        if not user:
            is_new = True
            user = User(email=email, full_name=full_name)
            db.add(user)
            db.commit()
            db.refresh(user)
            provision_dummy_plan(db, user.id)
            
        # Update tokens (this connects the calendar)
        user.google_access_token = access_token
        if refresh_token:
            user.google_refresh_token = refresh_token
        db.commit()
            
        return RedirectResponse(url=f"/?user_id={user.id}&email={user.email}&is_new={str(is_new).lower()}&full_name={full_name or ''}")
        
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

@router.put("/profile/{user_id}")
def update_profile(user_id: int, request: ProfileUpdateRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if request.full_name is not None:
        user.full_name = request.full_name
    if request.profile_picture is not None:
        user.profile_picture = request.profile_picture
        
    db.commit()
    db.refresh(user)
    
    return {"status": "success", "data": {"id": user.id, "full_name": user.full_name}}

