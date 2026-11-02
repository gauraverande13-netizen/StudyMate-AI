from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class PlannerTask(Base):
    __tablename__ = "planner_tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    task_date = Column(Date, nullable=False, index=True)  # Example: 2026-10-31
    title = Column(String(255), nullable=False)
    description = Column(String(500), nullable=True)
    time_slot = Column(String(50), nullable=True)  # Example: "10:00 AM - 11:30 AM"
    is_completed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())