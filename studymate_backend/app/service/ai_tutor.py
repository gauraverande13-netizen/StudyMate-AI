import json
import asyncio
from google import genai
from google.genai import types
from google.genai.errors import ServerError, ClientError
from fastapi import HTTPException
from app.core.config import settings

api_key = settings.GEMINI_API_KEY.strip().strip('"').strip("'")
if not api_key:
    raise RuntimeError("GEMINI_API_KEY सापडली नाही. कृपया .env फाईल तपासा.")

client = genai.Client(api_key=api_key)

FALLBACK_MODELS = [
    "gemini-3.8-flash",
    "gemini-3.5-flash",
    "gemini-flash-latest",
]


async def ask_ai_tutor(user_message: str, chat_history: list = None, document_context: str = "") -> str:
    """AI Tutor चॅट रिस्पॉन्स जनरेट करणे (Automatic Fallback & Retry सह + Uploaded Document Context)"""
    system_instruction = (
        "You are StudyMate AI, a friendly and highly knowledgeable academic tutor for college students. "
        "You have direct access to the student's uploaded documents, notes, resumes, and study materials provided in the context below. "
        "When the student asks questions about their uploaded PDF, document, resume, or any subject matter, ALWAYS answer "
        "thoroughly, accurately, and helpfully using the provided document context. "
        "Never say you cannot see or access their uploaded documents if the document context is provided below."
    )
    if document_context:
        prompt = (
            f"{system_instruction}\n\n"
            f"=== STUDENT'S UPLOADED DOCUMENTS CONTEXT ===\n"
            f"{document_context}\n"
            f"============================================\n\n"
            f"Student Question: {user_message}\n\n"
            f"Answer:"
        )
    else:
        prompt = f"{system_instruction}\n\nStudent Question: {user_message}\n\nAnswer:"

    config = types.GenerateContentConfig(
        max_output_tokens=1000,
        temperature=0.7,
    )

    last_error = ""

    for model_name in FALLBACK_MODELS:
        for attempt in range(2):
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=config
                )
                if response.text:
                    return response.text
            except ServerError as e:
                last_error = str(e)
                await asyncio.sleep(1)
            except ClientError as e:
                last_error = str(e)
                break
            except Exception as e:
                last_error = str(e)
                break

    return f"AI Server is currently busy. Please tap send again. (Error: {last_error})"


async def summarize_document(text: str) -> dict:
    """PDF/Text ki fast summary aur key points banana"""
    truncated_text = text[:6000]

    prompt = f"""
You are an academic summarizer. Read the text and return strictly a valid JSON object.
Do not write markdown formatting outside the JSON.

{{
  "summary": "Concise summary in 2 paragraphs",
  "key_points": [
    "Key point 1",
    "Key point 2",
    "Key point 3"
  ]
}}

Text:
{truncated_text}
"""

    for model_name in FALLBACK_MODELS:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    max_output_tokens=600,
                    temperature=0.5,
                )
            )
            
            clean_text = response.text.strip()
            if clean_text.startswith("```"):
                clean_text = clean_text.split("```")[1]
                if clean_text.startswith("json"):
                    clean_text = clean_text[4:]
            clean_text = clean_text.strip()

            data = json.loads(clean_text)
            return {
                "summary": data.get("summary", "Summary available."),
                "key_points": data.get("key_points", [])
            }
        except Exception as e:
            print(f"Error in summarize_document with {model_name}: {e}")
            continue

    # Clean fallback based on actual extracted document lines
    lines = [line.strip() for line in text.split("\n") if line.strip() and len(line.strip()) > 10]
    preview_summary = " ".join(lines[:4]) if lines else "Document uploaded successfully."
    key_points = lines[4:9] if len(lines) >= 9 else ["Document processed", "Key insights available in full text"]
    return {
        "summary": preview_summary,
        "key_points": key_points
    }

async def generate_flashcards_from_text(text: str, count: int = 5) -> list[dict]:
    """मजकुरावरून रिव्हिजन फ्लॅशकार्ड्स तयार करणे"""
    truncated_text = text[:12000]

    prompt = f"""
    Based on the following content, generate {count} flashcards for student revision.
    Return strictly a JSON array of objects with keys "question" and "answer".

    Content:
    {truncated_text}

    Format strictly as:
    [
        {{"question": "What is ...?", "answer": "..."}}
    ]
    """

    for model_name in FALLBACK_MODELS:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt
            )
            clean_text = response.text.strip().replace("```json", "").replace("```", "")
            return json.loads(clean_text)
        except Exception:
            continue

    return []