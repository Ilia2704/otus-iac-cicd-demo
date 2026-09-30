import os
import re

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
OLLAMA_MODEL = "qwen3:0.6b"

app = FastAPI(title="Qwen3 Sentiment Demo", version="1.0.0")


class SentimentRequest(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class SentimentResponse(BaseModel):
    label: str


def normalize_label(raw: str) -> str:
    match = re.search(r"\b(POSITIVE|NEGATIVE|NEUTRAL)\b", raw.upper())
    if not match:
        raise ValueError(f"Unexpected model output: {raw!r}")
    return match.group(1)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/sentiment", response_model=SentimentResponse)
async def sentiment(request: SentimentRequest):
    prompt = (
        "You are a sentiment classifier.\n\n"
        "Classify the text as exactly one of:\n\n"
        "POSITIVE\n"
        "NEGATIVE\n"
        "NEUTRAL\n\n"
        "Return only one uppercase label.\n\n"
        f"Text:\n{request.text}"
    )

    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "think": False,
        "options": {"temperature": 0, "num_predict": 8},
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(f"{OLLAMA_URL}/api/generate", json=payload)
            response.raise_for_status()
        raw = response.json()["response"]
        label = normalize_label(raw)
    except (httpx.HTTPError, KeyError, ValueError) as exc:
        raise HTTPException(status_code=502, detail=f"Ollama inference failed: {exc}") from exc

    return SentimentResponse(label=label)
