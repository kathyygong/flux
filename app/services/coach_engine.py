from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models.activity import Activity
from app.models.ai_proposal import AIProposal
from app.models.biometric import Biometric
from app.models.training_plan import TrainingPlan
from app.models.user import User
from sqlalchemy import func as sa_func
from app.services.google_calendar_service import GoogleCalendarService
from app.services.reasoning import resolve_workout_conflict_with_ai


class CoachEngine:
    @staticmethod
    def _next_week_window(now: datetime | None = None) -> tuple[datetime, datetime]:
        now = now or datetime.now(timezone.utc)
        days_until_monday = (7 - now.weekday()) % 7
        if days_until_monday == 0:
            days_until_monday = 7
        start = (now + timedelta(days=days_until_monday)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        end = start + timedelta(days=7)
        return start, end

    @staticmethod
    def _serialize_workout(activity: Activity) -> dict[str, Any]:
        duration_minutes = 60
        if activity.actual_start_time and activity.original_start_time:
            duration_minutes = max(
                int((activity.actual_start_time - activity.original_start_time).total_seconds() // 60),
                15,
            )

        return {
            "activity_id": activity.id,
            "name": activity.name,
            "description": activity.description,
            "start_time": activity.original_start_time.isoformat(),
            "end_time": (activity.original_start_time + timedelta(minutes=duration_minutes)).isoformat(),
            "status": activity.status,
        }

    @staticmethod
    def calculate_hrv_throttle(db: Session, user_id: int, current_date: datetime | None = None) -> dict[str, Any]:
        if current_date is None:
            current_date = datetime.now(timezone.utc)
            
        three_months_ago = current_date - timedelta(days=90)
        
        avg_hrv_result = db.query(sa_func.avg(Biometric.hrv)).filter(
            Biometric.user_id == user_id,
            Biometric.recorded_date >= three_months_ago.date(),
            Biometric.recorded_date < current_date.date(),
            Biometric.hrv.is_not(None)
        ).scalar()
        
        latest_biometric = db.query(Biometric).filter(
            Biometric.user_id == user_id,
            Biometric.hrv.is_not(None)
        ).order_by(Biometric.recorded_date.desc()).first()
        
        if not latest_biometric or not avg_hrv_result:
            return {"should_throttle": False, "reason": "Insufficient HRV data"}
            
        avg_hrv = float(avg_hrv_result)
        latest_hrv = latest_biometric.hrv
        
        threshold = avg_hrv * 0.85
        
        should_throttle = latest_hrv < threshold
        
        return {
            "should_throttle": should_throttle,
            "latest_hrv": latest_hrv,
            "avg_hrv": avg_hrv,
            "threshold": threshold,
            "reason": f"HRV ({latest_hrv:.1f}) is >15% below 3-month avg ({avg_hrv:.1f})" if should_throttle else "HRV is normal"
        }

    @staticmethod
    def check_jet_lag(user: User, new_offset_minutes: int | None = None) -> bool:
        """
        Checks if the user has shifted timezones by > 3 hours.
        Updates the user's timezone if a shift is detected.
        Returns True if the user is in the 48-hour jet lag recovery window.
        """
        now = datetime.now(timezone.utc)
        
        # If new offset is provided, check for shift
        if new_offset_minutes is not None:
            if user.current_timezone_offset is None:
                user.current_timezone_offset = new_offset_minutes
            else:
                diff_minutes = abs(user.current_timezone_offset - new_offset_minutes)
                if diff_minutes >= 180: # 3 hours
                    user.last_timezone_update = now
                user.current_timezone_offset = new_offset_minutes
                
        # Check if we are inside the 48-hour recovery window
        if user.last_timezone_update:
            hours_since_shift = (now - user.last_timezone_update).total_seconds() / 3600
            if hours_since_shift <= 48:
                return True
                
        return False

    @staticmethod
    def lock_in_next_week_schedule(db: Session) -> dict[str, int]:
        next_week_start, next_week_end = CoachEngine._next_week_window()

        users = db.query(User).all()
        saved_proposals = 0
        checked_workouts = 0

        for user in users:
            access_token = user.google_access_token or settings.google_access_token
            busy_blocks = []
            
            if access_token:
                try:
                    busy_blocks = GoogleCalendarService.fetch_busy_blocks_between(
                        access_token=access_token,
                        time_min=next_week_start,
                        time_max=next_week_end,
                    )
                except Exception as e:
                    print(f"Error fetching calendar for user {user.id}: {e}")

            activities = (
                db.query(Activity)
                .join(TrainingPlan, Activity.training_plan_id == TrainingPlan.id)
                .options(joinedload(Activity.training_plan))
                .filter(TrainingPlan.user_id == user.id)
                .filter(Activity.original_start_time >= next_week_start)
                .filter(Activity.original_start_time < next_week_end)
                .all()
            )

            hrv_throttle_status = CoachEngine.calculate_hrv_throttle(db, user.id, next_week_start)
            recovery_score = 0.5 if hrv_throttle_status.get("should_throttle") else 1.0
            jet_lag_active = CoachEngine.check_jet_lag(user)

            for activity in activities:
                checked_workouts += 1
                workout = CoachEngine._serialize_workout(activity)
                
                outcome = resolve_workout_conflict_with_ai(
                    workout=workout,
                    calendar_events=busy_blocks,
                    recovery_score=recovery_score,
                    biometric_throttle=hrv_throttle_status,
                    jet_lag_active=jet_lag_active,
                )
                if not outcome["has_conflict"] or not outcome["proposal"]:
                    continue

                proposal = AIProposal(
                    training_plan_id=activity.training_plan_id,
                    proposal_type="schedule_conflict_resolution",
                    summary=outcome["proposal"]["short_rationale"],
                    context={
                        "activity_id": activity.id,
                        "workout": workout,
                        "calendar_conflict": outcome["conflict_details"].get("calendar_conflict"),
                        "biometric_conflict": outcome["conflict_details"].get("biometric_conflict"),
                        "jet_lag_active": jet_lag_active,
                        "ai_suggestion": outcome["proposal"]["new_parameters"],
                        "window": {
                            "start": next_week_start.isoformat(),
                            "end": next_week_end.isoformat(),
                        },
                    },
                )
                db.add(proposal)
                saved_proposals += 1

        db.commit()
        return {"checked_workouts": checked_workouts, "saved_proposals": saved_proposals}
