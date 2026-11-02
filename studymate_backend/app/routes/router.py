from fastapi import APIRouter
from app.routes import auth, docs, flashcards, chat, planner, dashboard

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(docs.router)
api_router.include_router(flashcards.router)
api_router.include_router(chat.router)
api_router.include_router(planner.router)
api_router.include_router(dashboard.router)