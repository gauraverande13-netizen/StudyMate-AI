from datetime import datetime
from pydantic import BaseModel, ConfigDict


class DocumentBase(BaseModel):
    filename: str


class DocumentCreate(DocumentBase):
    file_path: str


class DocumentSummaryResponse(DocumentBase):
    id: int
    summary: str | None = None
    key_points: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)