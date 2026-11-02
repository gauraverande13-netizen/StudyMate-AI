from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.flashcard import Flashcard
from app.models.document import Document
from app.schemas.flashcard import (
    FlashcardCreate,
    FlashcardUpdate,
    FlashcardResponse,
    FlashcardGenerateRequest,
)
from app.service.pdf_parser import extract_text_from_pdf
from app.service.ai_tutor import generate_flashcards_from_text

router = APIRouter(prefix="/flashcards", tags=["Flashcards"])


@router.get("/", response_model=List[FlashcardResponse])
def get_flashcards(
    user_id: Optional[int] = Query(None, description="Logged-in user id"),
    db: Session = Depends(get_db),
):
    query = db.query(Flashcard)
    if user_id is not None:
        query = query.filter(Flashcard.user_id == user_id)
    else:
        # Return empty list when no user_id is specified to prevent data leakage between users
        return []

    return query.order_by(Flashcard.id.desc()).all()


@router.post("/", response_model=FlashcardResponse, status_code=status.HTTP_201_CREATED)
def create_flashcard(
    card: FlashcardCreate,
    user_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    target_user_id = card.user_id or user_id
    if not target_user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    new_card = Flashcard(
        user_id=target_user_id,
        document_id=card.document_id,
        subject=card.subject,
        question=card.question,
        answer=card.answer,
    )
    db.add(new_card)
    db.commit()
    db.refresh(new_card)
    return new_card


@router.post("/generate", response_model=List[FlashcardResponse])
async def generate_cards_from_doc(
    request: FlashcardGenerateRequest,
    user_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    target_user_id = request.user_id or user_id
    if not target_user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    if not request.document_id:
        raise HTTPException(status_code=400, detail="document_id is required")

    doc = db.query(Document).filter(
        Document.id == request.document_id,
        Document.user_id == target_user_id,
    ).first()
    if not doc:
        # Fallback if document not scoped
        doc = db.query(Document).filter(Document.id == request.document_id).first()
        if not doc:
            raise HTTPException(status_code=404, detail="Document not found")

    text = extract_text_from_pdf(doc.file_path)
    generated_data = await generate_flashcards_from_text(text, count=request.count)

    saved_cards = []
    for item in generated_data:
        card = Flashcard(
            user_id=target_user_id,
            document_id=doc.id,
            subject=doc.filename.replace(".pdf", ""),
            question=item.get("question", ""),
            answer=item.get("answer", ""),
        )
        db.add(card)
        saved_cards.append(card)

    db.commit()
    for card in saved_cards:
        db.refresh(card)
    return saved_cards


@router.put("/{card_id}", response_model=FlashcardResponse)
def update_flashcard(
    card_id: int,
    card_in: FlashcardUpdate,
    db: Session = Depends(get_db),
):
    card = db.query(Flashcard).filter(Flashcard.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Flashcard not found")

    if card_in.subject is not None:
        card.subject = card_in.subject
    if card_in.question is not None:
        card.question = card_in.question
    if card_in.answer is not None:
        card.answer = card_in.answer

    db.commit()
    db.refresh(card)
    return card


@router.delete("/{card_id}")
def delete_flashcard(card_id: int, db: Session = Depends(get_db)):
    card = db.query(Flashcard).filter(Flashcard.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Flashcard not found")

    db.delete(card)
    db.commit()
    return {"success": True, "message": "Card deleted from database"}