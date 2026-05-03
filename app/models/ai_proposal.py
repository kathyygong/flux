from typing import Optional, Dict, List, Any
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.models.base import Base


class AIProposal(Base):
    __tablename__ = "ai_proposals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    training_plan_id: Mapped[int] = mapped_column(
        ForeignKey("training_plans.id"), nullable=False, index=True
    )
    proposal_type: Mapped[str] = mapped_column(String(80), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    context: Mapped[Dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    training_plan: Mapped["TrainingPlan"] = relationship(back_populates="ai_proposals")
