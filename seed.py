from datetime import datetime, timedelta, timezone

from app.core.db import SessionLocal, init_db
from app.models.activity import Activity
from app.models.training_plan import TrainingPlan
from app.models.user import User


def seed() -> None:
    init_db()

    db = SessionLocal()
    try:
        email = "runner@example.com"
        user = db.query(User).filter(User.email == email).first()

        if user is None:
            user = User(email=email, full_name="Demo Runner")
            db.add(user)
            db.flush()

        existing_plan = (
            db.query(TrainingPlan)
            .filter(TrainingPlan.user_id == user.id, TrainingPlan.name == "12-Week Marathon Plan")
            .first()
        )
        if existing_plan is not None:
            print("Seed skipped: dummy marathon plan already exists.")
            return

        plan = TrainingPlan(
            user_id=user.id,
            name="12-Week Marathon Plan",
            goal_race="Marathon",
            weeks=12,
            description="Dummy marathon plan for local development and testing.",
        )
        db.add(plan)
        db.flush()

        start_date = datetime.now(timezone.utc).replace(hour=6, minute=0, second=0, microsecond=0)

        for week in range(1, 13):
            activity_date = start_date + timedelta(days=(week - 1) * 7)
            activity = Activity(
                training_plan_id=plan.id,
                name=f"Week {week} Long Run",
                description=f"Steady endurance run for week {week}.",
                original_start_time=activity_date,
                actual_start_time=None,
                status="scheduled",
            )
            db.add(activity)

        db.commit()
        print("Seed complete: created one user with a 12-week marathon plan.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
