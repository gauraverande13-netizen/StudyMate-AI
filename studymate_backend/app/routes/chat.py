from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.chat import ChatSession, ChatMessage
from app.schemas.chat import ChatPromptRequest, MessageResponse, ChatSessionResponse
from app.service.ai_tutor import ask_ai_tutor

router = APIRouter(prefix="/chat", tags=["AI Tutor Chat"])


@router.post("/session", response_model=ChatSessionResponse)
def create_session(
    title: str = "New Study Session",
    user_id: Optional[int] = Query(None),
    db: Session = Depends(get_db)
):
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    session = ChatSession(user_id=user_id, title=title)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.post("/message", response_model=MessageResponse)
async def send_message(
    payload: ChatPromptRequest,
    user_id: Optional[int] = Query(None),
    db: Session = Depends(get_db)
):
    effective_user_id = payload.user_id or user_id
    if not effective_user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    session = None
    if payload.session_id:
        session = db.query(ChatSession).filter(
            ChatSession.id == payload.session_id,
            ChatSession.user_id == effective_user_id
        ).first()
    
    if not session:
        session = ChatSession(user_id=effective_user_id, title=payload.message[:30])
        db.add(session)
        db.commit()
        db.refresh(session)

    # 1. Save user message
    user_msg = ChatMessage(session_id=session.id, sender="user", content=payload.message)
    db.add(user_msg)
    db.commit()

    # 2. Get AI reply
    ai_reply = await ask_ai_tutor(user_message=payload.message)

    # 3. Save AI message
    ai_msg = ChatMessage(session_id=session.id, sender="ai", content=ai_reply)
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)

    return ai_msg