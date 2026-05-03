from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

celery_app = Celery(
    "flux",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

celery_app.conf.timezone = settings.celery_timezone
celery_app.conf.beat_schedule = {
    "weekly-coach-lock-in-sunday-evening": {
        "task": "app.tasks.weekly_coach_lock_in",
        "schedule": crontab(day_of_week="sun", hour=19, minute=0),
    }
}

celery_app.autodiscover_tasks(["app"])
