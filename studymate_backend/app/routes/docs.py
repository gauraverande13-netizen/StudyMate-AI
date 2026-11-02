import os
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.document import Document
from app.schemas.doc import DocumentSummaryResponse
from app.service.pdf_parser import extract_text_from_file
from app.service.ai_tutor import summarize_document

from fastapi.responses import FileResponse

router = APIRouter(prefix="/docs", tags=["Documents & Summarizer"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".pdf", ".docx", ".txt"}


class TextSummaryRequest(BaseModel):
    text: str


@router.post("/upload")
async def upload_document(
    file: UploadFile = File(...),
    user_id: int = Form(...),
    db: Session = Depends(get_db)
):
    try:
        content = await file.read()
        text = extract_text_from_file(content, file.filename)
        
        if not text.strip():
            raise HTTPException(status_code=400, detail="Document madhun text extract karta aala nahi.")

        summary_data = await summarize_document(text)

        points_str = summary_data.get("key_points", "")
        if isinstance(points_str, list):
            points_str = "\n".join(points_str)

        saved_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(saved_path, "wb") as f:
            f.write(content)

        new_doc = Document(
            user_id=user_id,
            filename=file.filename,
            file_path=saved_path,
            summary=summary_data.get("summary", ""),
            key_points=points_str
        )
        db.add(new_doc)
        db.commit()
        db.refresh(new_doc)

        return {
            "success": True,
            "id": new_doc.id,
            "filename": new_doc.filename,
            "summary": new_doc.summary,
            "key_points": new_doc.key_points,
            "full_text": text,
            "file_url": f"/api/v1/docs/{new_doc.id}/file"
        }
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{doc_id}/file")
def get_document_file(doc_id: int, db: Session = Depends(get_db)):
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if not doc or not doc.file_path or not os.path.exists(doc.file_path):
        raise HTTPException(status_code=404, detail="File not found")
    media_type = "application/pdf" if doc.filename.lower().endswith(".pdf") else "application/octet-stream"
    return FileResponse(doc.file_path, media_type=media_type, filename=doc.filename)


@router.get("/{doc_id}/content")
def get_document_content(doc_id: int, db: Session = Depends(get_db)):
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    content_text = ""
    if doc.file_path and os.path.exists(doc.file_path):
        try:
            with open(doc.file_path, "rb") as f:
                file_bytes = f.read()
            content_text = extract_text_from_file(file_bytes, doc.filename)
        except Exception as e:
            content_text = f"Error reading text: {e}"
    return {
        "id": doc.id,
        "filename": doc.filename,
        "summary": doc.summary,
        "key_points": doc.key_points,
        "full_text": content_text,
        "file_url": f"/api/v1/docs/{doc.id}/file"
    }


@router.get("/{doc_id}", response_model=DocumentSummaryResponse)
def get_document(doc_id: int, db: Session = Depends(get_db)):
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc


@router.post("/summarize")
async def summarize_plain_text(payload: TextSummaryRequest):
    result = await summarize_document(text=payload.text)
    return result


@router.get("/", summary="Get Logged-in User Documents")
def get_user_documents(
    user_id: Optional[int] = Query(None, description="Logged-in user id"),
    db: Session = Depends(get_db)
):
    """
    Logged-in user ke dwara upload kiye gaye sabhi documents return karega.
    """
    if user_id is None:
        # Prevent returning any other user's documents if user_id is omitted
        return []

    docs = (
        db.query(Document)
        .filter(Document.user_id == user_id)
        .order_by(Document.id.desc())
        .all()
    )
    
    result = []
    for doc in docs:
        result.append({
            "id": doc.id,
            "filename": getattr(doc, "filename", "Untitled Document"),
            "summary": getattr(doc, "summary", ""),
            "key_points": getattr(doc, "key_points", ""),
            "created_at": getattr(doc, "created_at", None).isoformat() if getattr(doc, "created_at", None) else None,
            "file_url": f"/api/v1/docs/{doc.id}/file"
        })
    return result