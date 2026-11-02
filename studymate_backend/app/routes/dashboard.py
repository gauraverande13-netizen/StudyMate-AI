from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.document import Document
from app.models.flashcard import Flashcard
from app.models.planner_task import PlannerTask

router = APIRouter(prefix="/dashboard", tags=["Dashboard & Activity"])

class RecentWorkItem(BaseModel):
    id: str
    title: str
    subtitle: str
    badge_text: str
    badge_type: str
    status_tag: str

class DashboardResponse(BaseModel):
    full_name: str
    streak_count: int
    goals_completed: int
    total_goals: int
    completion_percentage: int
    recent_works: List[RecentWorkItem]

@router.get("/summary", response_model=DashboardResponse)
def get_dashboard_summary(
    user_id: Optional[int] = Query(None, description="Logged-in user id"),
    db: Session = Depends(get_db)
):
    if not user_id:
        return {
            "full_name": "Student",
            "streak_count": 1,
            "goals_completed": 0,
            "total_goals": 0,
            "completion_percentage": 0,
            "recent_works": []
        }

    # 1. User Info
    user = db.query(User).filter(User.id == user_id).first()
    full_name = user.full_name if user else "Student"

    # 2. Today's Planner Goals
    today_tasks = db.query(PlannerTask).filter(
        PlannerTask.user_id == user_id,
        PlannerTask.task_date == date.today()
    ).all()

    total_goals = len(today_tasks)
    goals_completed = sum(1 for t in today_tasks if t.is_completed)
    completion_percentage = int((goals_completed / total_goals * 100)) if total_goals > 0 else 0

    # 3. User's Recent Works (Documents and Flashcards)
    recent_works = []
    
    recent_docs = db.query(Document).filter(
        Document.user_id == user_id
    ).order_by(Document.id.desc()).limit(3).all()

    for doc in recent_docs:
        badge = "PDF" if doc.filename.lower().endswith(".pdf") else "DOC"
        recent_works.append(
            RecentWorkItem(
                id=f"doc_{doc.id}",
                title=doc.filename,
                subtitle="Summarized Document",
                badge_text=badge,
                badge_type="green",
                status_tag="Summarized"
            )
        )

    recent_cards = db.query(Flashcard).filter(
        Flashcard.user_id == user_id
    ).order_by(Flashcard.id.desc()).limit(2).all()

    for card in recent_cards:
        recent_works.append(
            RecentWorkItem(
                id=f"card_{card.id}",
                title=card.subject or "Flashcards",
                subtitle=f"Q: {card.question[:28]}...",
                badge_text="FC",
                badge_type="purple",
                status_tag="Flashcard"
            )
        )

    return {
        "full_name": full_name,
        "streak_count": 1 if total_goals > 0 or recent_works else 0,
        "goals_completed": goals_completed,
        "total_goals": total_goals,
        "completion_percentage": completion_percentage,
        "recent_works": recent_works
    }