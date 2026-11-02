from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.planner_task import PlannerTask

router = APIRouter(prefix="/planner", tags=["Daily Planner"])

# Pydantic Schemas
class TaskCreate(BaseModel):
    user_id: int
    task_date: date
    title: str
    description: Optional[str] = None
    time_slot: Optional[str] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    time_slot: Optional[str] = None
    is_completed: Optional[bool] = None

# 1. DATE-WISE TASKS FETCH KARNA
@router.get("/")
def get_tasks_by_date(
    user_id: int = Query(..., description="Logged-in user id"),
    selected_date: date = Query(...),
    db: Session = Depends(get_db)
):
    tasks = db.query(PlannerTask).filter(
        PlannerTask.user_id == user_id,
        PlannerTask.task_date == selected_date
    ).order_by(PlannerTask.id.asc()).all()

    return [
        {
            "id": t.id,
            "user_id": t.user_id,
            "task_date": t.task_date.isoformat(),
            "title": t.title,
            "description": t.description,
            "time_slot": t.time_slot,
            "is_completed": t.is_completed,
        }
        for t in tasks
    ]

# 2. NEW TASK CREATE KARNA
@router.post("/", status_code=status.HTTP_201_CREATED)
def create_planner_task(task_in: TaskCreate, db: Session = Depends(get_db)):
    new_task = PlannerTask(
        user_id=task_in.user_id,
        task_date=task_in.task_date,
        title=task_in.title,
        description=task_in.description,
        time_slot=task_in.time_slot,
        is_completed=False
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return {
        "id": new_task.id,
        "user_id": new_task.user_id,
        "task_date": new_task.task_date.isoformat(),
        "title": new_task.title,
        "description": new_task.description,
        "time_slot": new_task.time_slot,
        "is_completed": new_task.is_completed,
    }

# 3. TASK STATUS / CONTENT UPDATE (TOGGLE COMPLETE)
@router.put("/{task_id}")
def update_task(task_id: int, task_in: TaskUpdate, db: Session = Depends(get_db)):
    task = db.query(PlannerTask).filter(PlannerTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if task_in.title is not None:
        task.title = task_in.title
    if task_in.description is not None:
        task.description = task_in.description
    if task_in.time_slot is not None:
        task.time_slot = task_in.time_slot
    if task_in.is_completed is not None:
        task.is_completed = task_in.is_completed

    db.commit()
    db.refresh(task)
    return {"success": True, "id": task.id, "is_completed": task.is_completed}

# 4. TASK DELETE KARNA
@router.delete("/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(PlannerTask).filter(PlannerTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    db.delete(task)
    db.commit()
    return {"success": True, "message": "Task deleted"}

# 5. TODAY SUMMARY
@router.get("/summary/today")
def get_today_planner_summary(
    user_id: int = Query(..., description="Logged-in user id"),
    today_date: date = Query(default_factory=date.today),
    db: Session = Depends(get_db)
):
    tasks = db.query(PlannerTask).filter(
        PlannerTask.user_id == user_id,
        PlannerTask.task_date == today_date
    ).all()

    total_tasks = len(tasks)
    completed_tasks = sum(1 for t in tasks if t.is_completed)
    remaining_tasks = total_tasks - completed_tasks
    
    percent_done = int((completed_tasks / total_tasks * 100)) if total_tasks > 0 else 0

    return {
        "active_date": today_date.isoformat(),
        "total_tasks": total_tasks,
        "completed_tasks": completed_tasks,
        "remaining_tasks": remaining_tasks,
        "percent_done": percent_done
    }