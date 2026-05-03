from datetime import date, datetime, timedelta, timezone
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import random

from app.core.db import get_db
from app.models.training_plan import TrainingPlan
from app.models.activity import Activity
from app.services.training_plan_service import TrainingPlanService

router = APIRouter(prefix="/training-plans", tags=["training-plans"])


class TrainingPlanCreate(BaseModel):
    user_id: int
    name: str = Field(min_length=1, max_length=150)
    goal_race: str = Field(min_length=1, max_length=100)
    race_distance: str = Field(min_length=1, max_length=50)  # e.g. "5K", "10K", "Half Marathon", "Marathon"
    start_date: str  # ISO date string
    end_date: str  # ISO date string
    description: str | None = None


class TrainingPlanRead(BaseModel):
    id: int
    name: str
    goal_race: str
    weeks: int
    description: str | None = None

    class Config:
        from_attributes = True


# --- AI Plan Generation Logic ---

WORKOUT_TEMPLATES = {
    "5K": {
        "easy": ["Easy Run – 30 min conversational pace", "Recovery Jog – 25 min very easy"],
        "tempo": ["Tempo Run – 20 min warm-up, 15 min at threshold, 10 min cool-down"],
        "interval": ["Track Intervals – 6x800m at 5K pace, 90s rest", "Fartlek – 40 min with 6x2 min surges"],
        "long": ["Long Run – 45-60 min steady", "Progressive Long Run – 50 min, last 15 min at tempo"],
    },
    "10K": {
        "easy": ["Easy Run – 40 min conversational pace", "Recovery Run – 30 min very easy"],
        "tempo": ["Tempo Run – 15 min warm-up, 20 min at threshold, 10 min cool-down"],
        "interval": ["Cruise Intervals – 4x1 mile at 10K pace, 60s rest", "Fartlek – 50 min with 8x90s surges"],
        "long": ["Long Run – 60-75 min steady", "Progressive Long Run – 70 min, last 20 min at tempo"],
    },
    "Half Marathon": {
        "easy": ["Easy Run – 45 min conversational pace", "Recovery Run – 35 min very easy"],
        "tempo": ["Tempo Run – 15 min warm-up, 25 min at half marathon pace, 10 min cool-down"],
        "interval": ["Threshold Intervals – 3x2 miles at HM pace, 2 min rest", "Hill Repeats – 8x90s uphill, jog down"],
        "long": ["Long Run – 80-100 min steady", "Long Run with Finish Fast – 90 min, last 3 miles at HM pace"],
    },
    "Marathon": {
        "easy": ["Easy Run – 50 min conversational pace", "Recovery Run – 40 min very easy"],
        "tempo": ["Marathon Pace Run – 10 miles at goal marathon pace"],
        "interval": ["Threshold Intervals – 4x1.5 miles at HM pace", "Yasso 800s – 10x800m at goal time"],
        "long": ["Long Run – 120-150 min steady", "Long Run with MP Finish – 20 miles, last 6 at marathon pace"],
    },
}


def generate_ai_plan(distance: str, start_date: date, end_date: date):
    """Generate a structured training plan based on race distance and date range."""
    templates = WORKOUT_TEMPLATES.get(distance, WORKOUT_TEMPLATES["10K"])
    
    activities = []
    current = start_date
    day_counter = 0
    
    # Weekly pattern: Mon=Easy, Tue=Interval, Wed=Easy, Thu=Tempo, Fri=Rest, Sat=Long, Sun=Rest
    week_pattern = ["easy", "interval", "easy", "tempo", "rest", "long", "rest"]
    
    while current <= end_date:
        day_type = week_pattern[day_counter % 7]
        
        if day_type == "rest":
            activities.append({
                "name": "Rest Day",
                "description": "Active recovery – focus on mobility, foam rolling, and hydration.",
                "date": current,
                "duration": 0,
            })
        else:
            workout = random.choice(templates[day_type])
            type_label = day_type.capitalize()
            activities.append({
                "name": f"{type_label} – {workout.split('–')[0].strip() if '–' in workout else workout}",
                "description": workout,
                "date": current,
                "duration": 60 if day_type != "long" else 90,
            })
        
        current += timedelta(days=1)
        day_counter += 1
    
    return activities


@router.get("", response_model=list[TrainingPlanRead])
def list_training_plans(db: Session = Depends(get_db)) -> list[TrainingPlanRead]:
    return TrainingPlanService.list_plans(db)


@router.get("/user/{user_id}")
def get_user_plan(user_id: int, db: Session = Depends(get_db)):
    plan = db.query(TrainingPlan).filter(TrainingPlan.user_id == user_id).first()
    if not plan:
        return {"status": "success", "data": None}
    
    # Calculate start/end from activities
    activities = db.query(Activity).filter(Activity.training_plan_id == plan.id).order_by(Activity.original_start_time).all()
    start_date = activities[0].original_start_time.date().isoformat() if activities else None
    end_date = activities[-1].original_start_time.date().isoformat() if activities else None
    
    return {
        "status": "success",
        "data": {
            "id": plan.id,
            "name": plan.name,
            "goal_race": plan.goal_race,
            "race_distance": plan.description.split("|")[0].strip() if plan.description and "|" in plan.description else plan.goal_race,
            "weeks": plan.weeks,
            "start_date": start_date,
            "end_date": end_date,
        }
    }


@router.post("", response_model=TrainingPlanRead)
def create_training_plan(
    payload: TrainingPlanCreate,
    db: Session = Depends(get_db),
) -> TrainingPlanRead:
    start = date.fromisoformat(payload.start_date)
    end = date.fromisoformat(payload.end_date)
    weeks = max(1, (end - start).days // 7)
    
    # Delete existing plan for user first
    existing = db.query(TrainingPlan).filter(TrainingPlan.user_id == payload.user_id).all()
    for p in existing:
        db.delete(p)
    db.flush()
    
    plan = TrainingPlan(
        user_id=payload.user_id,
        name=payload.name,
        goal_race=payload.goal_race,
        weeks=weeks,
        description=f"{payload.race_distance} | {payload.start_date} to {payload.end_date}",
    )
    db.add(plan)
    db.flush()
    
    # Generate AI activities
    ai_activities = generate_ai_plan(payload.race_distance, start, end)
    for act in ai_activities:
        db_activity = Activity(
            training_plan_id=plan.id,
            name=act["name"],
            description=act["description"],
            original_start_time=datetime.combine(act["date"], datetime.min.time()).replace(tzinfo=timezone.utc),
            status="scheduled",
        )
        db.add(db_activity)
    
    db.commit()
    db.refresh(plan)
    return plan


@router.put("/{plan_id}")
def update_training_plan(
    plan_id: int,
    payload: TrainingPlanCreate,
    db: Session = Depends(get_db),
):
    plan = db.query(TrainingPlan).filter(TrainingPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    
    start = date.fromisoformat(payload.start_date)
    end = date.fromisoformat(payload.end_date)
    weeks = max(1, (end - start).days // 7)
    
    plan.name = payload.name
    plan.goal_race = payload.goal_race
    plan.weeks = weeks
    plan.description = f"{payload.race_distance} | {payload.start_date} to {payload.end_date}"
    
    # Delete old activities and regenerate
    db.query(Activity).filter(Activity.training_plan_id == plan.id).delete()
    
    ai_activities = generate_ai_plan(payload.race_distance, start, end)
    for act in ai_activities:
        db_activity = Activity(
            training_plan_id=plan.id,
            name=act["name"],
            description=act["description"],
            original_start_time=datetime.combine(act["date"], datetime.min.time()).replace(tzinfo=timezone.utc),
            status="scheduled",
        )
        db.add(db_activity)
    
    db.commit()
    db.refresh(plan)
    return {"status": "success", "data": {"id": plan.id, "name": plan.name}}

