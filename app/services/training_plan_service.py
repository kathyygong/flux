from sqlalchemy.orm import Session

from app.models.training_plan import TrainingPlan


class TrainingPlanService:
    @staticmethod
    def list_plans(db: Session) -> list[TrainingPlan]:
        return db.query(TrainingPlan).order_by(TrainingPlan.created_at.desc()).all()

    @staticmethod
    def create_plan(
        db: Session,
        name: str,
        goal_race: str,
        weeks: int,
        description: str | None = None,
    ) -> TrainingPlan:
        plan = TrainingPlan(
            name=name,
            goal_race=goal_race,
            weeks=weeks,
            description=description,
        )
        db.add(plan)
        db.commit()
        db.refresh(plan)
        return plan
