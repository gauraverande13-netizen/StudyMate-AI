from datetime import datetime
from pydantic import BaseModel, ConfigDict


class MessageBase(BaseModel):
    sender: str
    content: str


class MessageResponse(MessageBase):
    id: int
    session_id: int | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ChatSessionCreate(BaseModel):
    title: str = "New Study Session"
    user_id: int | None = None


class ChatSessionResponse(BaseModel):
    id: int
    user_id: int | None = None
    title: str
    created_at: datetime
    messages: list[MessageResponse] = []

    model_config = ConfigDict(from_attributes=True)


class ChatPromptRequest(BaseModel):
    user_id: int | None = None
    session_id: int | None = None
    message: str