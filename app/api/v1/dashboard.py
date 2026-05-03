from datetime import date, datetime, timezone, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.activity import Activity
from app.models.ai_proposal import AIProposal
from app.models.training_plan import TrainingPlan
from app.models.user import User
from app.models.biometric import Biometric

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

class ProposalActionRequest(BaseModel):
    action: str  # "accept" or "reject"

@router.get("/{user_id}")
def get_dashboard(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Get active training plan
    plan = db.query(TrainingPlan).filter(TrainingPlan.user_id == user.id).first()
    
    today = datetime.now(timezone.utc).date()
    
    dashboard_data = {
        "user": {
            "full_name": user.full_name,
            "email": user.email,
            "profile_picture": user.profile_picture
        },
        "readiness": {
            "score": 100,
            "label": "Optimal",
            "colorClass": "text-success"
        },
        "completion_pct": 0,
        "streak": 0,
        "todays_plan": None,
        "plan_meta": None,
        "ai_proposal": {"exists": False}
    }
    
    if plan:
        # Plan Metadata
        target_date = plan.created_at + timedelta(weeks=plan.weeks) if plan.created_at and plan.weeks else None
        dashboard_data["plan_meta"] = {
            "goal": plan.goal_race,
            "target_date": target_date.isoformat() if target_date else None,
            "total_weeks": plan.weeks,
        }

        # Completion PCT
        total_activities = db.query(Activity).filter(Activity.training_plan_id == plan.id).count()
        completed_activities = db.query(Activity).filter(
            Activity.training_plan_id == plan.id,
            Activity.status == "completed"
        ).count()
        if total_activities > 0:
            dashboard_data["completion_pct"] = int((completed_activities / total_activities) * 100)
            
        # Today's Plan
        all_activities = db.query(Activity).filter(
            Activity.training_plan_id == plan.id
        ).order_by(Activity.original_start_time).all()
        
        # Calculate completed weeks — count full 7-day blocks from plan start that are in the past
        if all_activities:
            plan_start = all_activities[0].original_start_time.date()
            days_elapsed = (today - plan_start).days
            completed_weeks = max(0, days_elapsed // 7)
        else:
            completed_weeks = 0
        
        dashboard_data["plan_meta"]["completed_weeks"] = completed_weeks
        
        # Weekly mileage from actual completed activities (group by week number)
        weekly_mileage = {}
        if all_activities:
            plan_start = all_activities[0].original_start_time.date()
            for a in all_activities:
                if a.status == "completed":
                    week_num = (a.original_start_time.date() - plan_start).days // 7
                    weekly_mileage[week_num] = weekly_mileage.get(week_num, 0) + 1  # count completed sessions as proxy
            
        # Build ordered weekly mileage list for the chart (only past weeks)
        mileage_labels = []
        mileage_data = []
        for w in range(max(completed_weeks, 1)):
            mileage_labels.append(f"Week {w + 1}")
            mileage_data.append(weekly_mileage.get(w, 0))
        
        dashboard_data["weekly_mileage"] = {
            "labels": mileage_labels,
            "data": mileage_data,
        }
        
        # Training log — all past activities
        past_activities = [a for a in all_activities if a.original_start_time.date() <= today]
        dashboard_data["training_log"] = []
        for a in sorted(past_activities, key=lambda x: x.original_start_time, reverse=True):
            dashboard_data["training_log"].append({
                "id": a.id,
                "title": a.name,
                "description": a.description or "",
                "date": a.original_start_time.isoformat(),
                "status": a.status,
            })
        
        todays_activity = [a for a in all_activities if a.original_start_time.date() == today]
        
        if todays_activity:
            activity = todays_activity[0]
            dashboard_data["todays_plan"] = {
                "id": activity.id,
                "type": activity.name.split(" ")[0] if " " in activity.name else activity.name,
                "title": activity.name,
                "description": activity.description or "No description",
                "duration": "60",
                "status": activity.status
            }
            
        # Plan Activities (Next 30 days)
        thirty_days_later = today + timedelta(days=30)
        upcoming_activities = [a for a in all_activities if today <= a.original_start_time.date() <= thirty_days_later]
        
        dashboard_data["plan_activities"] = []
        for a in sorted(upcoming_activities, key=lambda x: x.original_start_time):
            dashboard_data["plan_activities"].append({
                "id": a.id,
                "type": a.name.split(" ")[0] if " " in a.name else a.name,
                "title": a.name,
                "description": a.description or "No description",
                "duration": "60",
                "date": a.original_start_time.isoformat(),
                "status": a.status
            })
        
        # Pending AI Proposal
        proposal = db.query(AIProposal).filter(
            AIProposal.training_plan_id == plan.id,
            AIProposal.status == "pending"
        ).order_by(AIProposal.created_at.desc()).first()
        
        if proposal:
            dashboard_data["ai_proposal"] = {
                "exists": True,
                "id": proposal.id,
                "reason": proposal.summary,
                "suggestion": proposal.context.get("ai_suggestion", {}).get("description", "Suggested change")
            }
            
        # Resiliency Heatmap & Stats
        # For calendar view, we want everything in the current month (or just everything, the frontend filters)
        current_year = today.year
        current_month = today.month
        
        past_activities = [a for a in all_activities if a.original_start_time.year == current_year and a.original_start_time.month == current_month]
        
        accepted_proposals = db.query(AIProposal).filter(
            AIProposal.training_plan_id == plan.id,
            AIProposal.status == "accepted"
        ).all()
        
        # Build a set of activity IDs that were adapted
        adapted_activity_ids = set()
        for p in accepted_proposals:
            act_id = p.context.get("activity_id")
            if act_id:
                adapted_activity_ids.add(act_id)
                
        heatmap = []
        original_count = 0
        adapted_count = 0
        skipped_count = 0
        
        for a in sorted(past_activities, key=lambda x: x.original_start_time):
            # Only count stats for dates up to today, future dates remain un-colored
            is_past_or_today = a.original_start_time.date() <= today
            state = "scheduled"
            
            if is_past_or_today:
                if a.status == "completed":
                    if a.id in adapted_activity_ids:
                        state = "adapted"
                        adapted_count += 1
                    else:
                        state = "original"
                        original_count += 1
                elif a.original_start_time.date() < today:
                    state = "skipped"
                    skipped_count += 1
                    
            if state != "scheduled":
                heatmap.append({
                    "date": a.original_start_time.date().isoformat(),
                    "state": state
                })
            
        total_past = original_count + adapted_count + skipped_count
        saved_pct = int((adapted_count / total_past) * 100) if total_past > 0 else 0
        skipped_pct = int((skipped_count / total_past) * 100) if total_past > 0 else 0
        
        dashboard_data["resiliency"] = {
            "heatmap": heatmap,
            "saved_pct": saved_pct,
            "skipped_pct": skipped_pct,
            "original_count": original_count,
            "adapted_count": adapted_count,
            "skipped_count": skipped_count
        }
            
    # Mock Readiness based on latest biometric if exists
    latest_bio = db.query(Biometric).filter(Biometric.user_id == user_id).order_by(Biometric.recorded_date.desc()).first()
    if latest_bio and latest_bio.hrv:
        dashboard_data["readiness"]["score"] = 85
        dashboard_data["readiness"]["label"] = "Recovery Optimized"
        
    return {"status": "success", "data": dashboard_data}


@router.post("/proposal/{proposal_id}/action")
def handle_proposal_action(proposal_id: int, request: ProposalActionRequest, db: Session = Depends(get_db)):
    proposal = db.query(AIProposal).filter(AIProposal.id == proposal_id).first()
    if not proposal:
        raise HTTPException(status_code=404, detail="Proposal not found")
        
    if request.action == "accept":
        proposal.status = "accepted"
        # Extract the activity_id from context and update it
        activity_id = proposal.context.get("activity_id")
        if activity_id:
            activity = db.query(Activity).filter(Activity.id == activity_id).first()
            if activity:
                suggestion = proposal.context.get("ai_suggestion", {})
                if "name" in suggestion:
                    activity.name = suggestion["name"]
                if "description" in suggestion:
                    activity.description = suggestion["description"]
                # For MVP we just update description and name
    elif request.action == "reject":
        proposal.status = "rejected"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    db.commit()
    return {"status": "success", "message": f"Proposal {request.action}ed"}

@router.post("/activity/{activity_id}/complete")
def complete_activity(activity_id: int, db: Session = Depends(get_db)):
    activity = db.query(Activity).filter(Activity.id == activity_id).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
        
    activity.status = "completed"
    activity.actual_start_time = datetime.now(timezone.utc)
    db.commit()
    return {"status": "success"}
