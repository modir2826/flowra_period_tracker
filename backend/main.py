from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import httpx
from pathlib import Path
from typing import List

app = FastAPI(title="Flowra AI Insights")


class HealthLog(BaseModel):
    timestamp: str
    mood: int
    energy: int
    painIntensity: int
    painLocation: str = ""
    notes: str = ""


class Cycle(BaseModel):
    id: str | None = None
    lastPeriodDate: str
    cycleLength: int
    periodLength: int


class AIRequest(BaseModel):
    logs: list[HealthLog]
    cycles: list[Cycle]


@app.post("/ai/insights")
async def ai_insights(req: AIRequest):
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY not set on server")

    # Build a short prompt with aggregated info
    # NOTE: keep prompt concise to avoid large token usage
    total_logs = len(req.logs)
    avg_mood = (sum([l.mood for l in req.logs]) / total_logs) if total_logs else None
    avg_energy = (sum([l.energy for l in req.logs]) / total_logs) if total_logs else None
    avg_pain = (sum([l.painIntensity for l in req.logs]) / total_logs) if total_logs else None

    prompt_lines = [
        f"You are a health insights assistant.",
        f"Total logs: {total_logs}",
    ]
    if avg_mood is not None:
        prompt_lines.append(f"Average mood: {avg_mood:.2f}")
    if avg_energy is not None:
        prompt_lines.append(f"Average energy: {avg_energy:.2f}")
    if avg_pain is not None:
        prompt_lines.append(f"Average pain: {avg_pain:.2f}")

    # Provide recent notes if available
    recent_notes = [l.notes for l in req.logs if l.notes]
    if recent_notes:
        prompt_lines.append("Recent notes: ")
        prompt_lines.extend([f"- {n}" for n in recent_notes[-5:]])

    # Add simple cycle summary
    if req.cycles:
        avg_cycle_len = sum([c.cycleLength for c in req.cycles]) / len(req.cycles)
        prompt_lines.append(f"Average cycle length (records): {avg_cycle_len:.1f} days")

    prompt_lines.append("Provide 3 concise personalized insights and 3 practical suggestions for self-care and safety." )
    prompt = "\n".join(prompt_lines)

    # Call OpenAI Chat Completions (GPT-4o style if available) via REST
    url = "https://api.openai.com/v1/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    body = {
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 450,
        "temperature": 0.7,
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=headers, json=body)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=f"AI API error: {resp.text}")
        data = resp.json()
        try:
            text = data["choices"][0]["message"]["content"]
        except Exception:
            raise HTTPException(status_code=502, detail="Unexpected AI response")

    return {"insights": text}


# --- Trusted contacts sync endpoints (simple file-backed storage) ---

DATA_DIR = Path(__file__).resolve().parent / 'data'
DATA_DIR.mkdir(exist_ok=True)


class Contact(BaseModel):
    id: str | None = None
    name: str
    phone: str
    relation: str | None = None
    trusted: bool | None = False


@app.get("/trusted/{uid}")
async def get_trusted(uid: str) -> List[Contact]:
    f = DATA_DIR / f"trusted_{uid}.json"
    if not f.exists():
        return []
    import json
    data = json.loads(f.read_text(encoding="utf-8"))
    return [Contact(**c) for c in data]


@app.post("/trusted/{uid}")
async def set_trusted(uid: str, contacts: List[Contact]):
    f = DATA_DIR / f"trusted_{uid}.json"
    import json
    f.write_text(json.dumps([c.dict() for c in contacts], ensure_ascii=False), encoding="utf-8")
    return {"status": "ok", "count": len(contacts)}


# --- SOS trigger endpoint (stub/sends via provider if configured) ---

class SosRequest(BaseModel):
    contacts: List[Contact]
    message: str | None = None


@app.post("/sos/{uid}")
async def trigger_sos(uid: str, req: SosRequest):
    # Try to use Twilio if configured, otherwise simulate
    TW_SID = os.getenv("TWILIO_SID")
    TW_TOKEN = os.getenv("TWILIO_TOKEN")
    FROM_NUMBER = os.getenv("TWILIO_FROM")
    sent = []
    if TW_SID and TW_TOKEN and FROM_NUMBER:
        # send SMS via Twilio REST API
        async with httpx.AsyncClient() as client:
            for c in req.contacts:
                to = c.phone
                body = req.message or f"Emergency alert from Flowra user {uid}"
                payload = {"From": FROM_NUMBER, "To": to, "Body": body}
                url = f"https://api.twilio.com/2010-04-01/Accounts/{TW_SID}/Messages.json"
                resp = await client.post(url, data=payload, auth=(TW_SID, TW_TOKEN))
                sent.append({"to": to, "status": resp.status_code})
    else:
        # Simulate sending
        for c in req.contacts:
            sent.append({"to": c.phone, "status": "simulated"})

    return {"status": "ok", "sent": sent}
