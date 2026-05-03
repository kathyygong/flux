from app.celery_app import celery_app
from app.core.db import SessionLocal
from app.services.coach_engine import CoachEngine


@celery_app.task(name="app.tasks.weekly_coach_lock_in")
def weekly_coach_lock_in() -> dict[str, int]:
    db = SessionLocal()
    try:
        return CoachEngine.lock_in_next_week_schedule(db)
    finally:
        db.close()
