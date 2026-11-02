from datetime import datetime
from pydantic import BaseModel, ConfigDict


class FlashcardBase(BaseModel):
    subject: str = "General"
    question: str
    answer: str


class FlashcardCreate(FlashcardBase):
    user_id: int | None = None
    document_id: int | None = None


class FlashcardUpdate(BaseModel):
    subject: str | None = None
    question: str | None = None
    answer: str | None = None


class FlashcardGenerateRequest(BaseModel):
    user_id: int | None = None
    document_id: int | None = None
    topic: str | None = None
    count: int = 5


class FlashcardResponse(FlashcardBase):
    id: int
    user_id: int | None = None
    document_id: int | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)