import os
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.chat import ChatSession, ChatMessage
from app.models.document import Document
from app.schemas.chat import ChatPromptRequest, MessageResponse, ChatSessionResponse
from app.service.ai_tutor import ask_ai_tutor
from app.service.pdf_parser import extract_text_from_file

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

    # 2. Build document context from user's uploaded files in DB
    user_docs = db.query(Document).filter(
        Document.user_id == effective_user_id
    ).order_by(Document.id.desc()).all()

    docs_context = ""
    if user_docs:
        doc_parts = []
        for doc in user_docs[:5]:
            doc_body = ""
            if doc.file_path and os.path.exists(doc.file_path):
                try:
                    with open(doc.file_path, "rb") as f:
                        doc_body = extract_text_from_file(f.read(), doc.filename)
                except Exception:
                    pass
            if not doc_body:
                summary_text = doc.summary or "No summary available"
                key_pts = doc.key_points or ""
                doc_body = f"Summary: {summary_text}\nKey Points:\n{key_pts}"

            doc_parts.append(f"DOCUMENT NAME: {doc.filename}\nCONTENT:\n{doc_body[:3500]}")

        docs_context = "\n\n".join(doc_parts)

    # 3. Get AI reply with document context
    ai_reply = await ask_ai_tutor(user_message=payload.message, document_context=docs_context)

    # 4. Save AI message
    ai_msg = ChatMessage(session_id=session.id, sender="ai", content=ai_reply)
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)

    return ai_msg
