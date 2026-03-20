"""LLM-based food photo analysis supporting both OpenAI and Anthropic."""

import base64
import json
import logging

from config import (
    LLM_PROVIDER, OPENAI_API_KEY, OPENAI_MODEL,
    ANTHROPIC_API_KEY, ANTHROPIC_MODEL,
)

logger = logging.getLogger(__name__)

ANALYSIS_PROMPT = """You are a nutrition analysis expert. Analyze this food photo and identify all visible food items.

Context: {context}

For each food item, estimate the portion size and provide nutrition information.

Respond ONLY with valid JSON in this exact format (no markdown, no extra text):
{{
  "foods": [
    {{
      "name": "food name",
      "category": "Vegetable|Fruit|Protein|Grain|Dairy|Fat|Sauce|Beverage|Other",
      "portion_grams": 150.0,
      "portion_desc": "1 cup or descriptive portion",
      "confidence": 0.85,
      "calories": 200.0,
      "protein": 25.0,
      "carbs": 10.0,
      "fat": 8.0,
      "fiber": 2.0,
      "sugar": 1.0,
      "sodium": 400.0,
      "cholesterol": 70.0,
      "sat_fat": 2.5
    }}
  ],
  "meal_description": "Brief overall description of the meal/layer",
  "health_notes": "Brief note on nutritional quality"
}}

Be as accurate as possible with portion estimation based on visual cues.
Use standard USDA nutrition data as reference."""


async def analyze_photo(photo_bytes: bytes, context: str = "A meal photo") -> dict:
    """Analyze a food photo using the configured LLM provider.

    Returns parsed JSON dict with 'foods', 'meal_description', 'health_notes'.
    """
    if LLM_PROVIDER == "anthropic":
        return await _analyze_with_anthropic(photo_bytes, context)
    else:
        return await _analyze_with_openai(photo_bytes, context)


async def _analyze_with_openai(photo_bytes: bytes, context: str) -> dict:
    import httpx

    b64 = base64.b64encode(photo_bytes).decode()
    prompt = ANALYSIS_PROMPT.format(context=context)

    payload = {
        "model": OPENAI_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{b64}",
                            "detail": "high",
                        },
                    },
                ],
            }
        ],
        "max_tokens": 2000,
        "temperature": 0.3,
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENAI_API_KEY}",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()

    content = data["choices"][0]["message"]["content"]
    return _parse_response(content)


async def _analyze_with_anthropic(photo_bytes: bytes, context: str) -> dict:
    import httpx

    b64 = base64.b64encode(photo_bytes).decode()
    prompt = ANALYSIS_PROMPT.format(context=context)

    payload = {
        "model": ANTHROPIC_MODEL,
        "max_tokens": 2000,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": b64,
                        },
                    },
                    {"type": "text", "text": prompt},
                ],
            }
        ],
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()

    content = data["content"][0]["text"]
    return _parse_response(content)


def _parse_response(text: str) -> dict:
    """Extract JSON from LLM response, handling markdown code blocks."""
    text = text.strip()

    # Strip markdown code fences
    if text.startswith("```"):
        lines = text.split("\n")
        # Remove first line (```json or ```) and last line (```)
        lines = [l for l in lines if not l.strip().startswith("```")]
        text = "\n".join(lines)

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try to find JSON object in text
        start = text.find("{")
        end = text.rfind("}") + 1
        if start >= 0 and end > start:
            return json.loads(text[start:end])
        raise ValueError(f"Could not parse LLM response as JSON: {text[:200]}")


async def ask_llm(prompt: str, context_data: str = "") -> str:
    """Send a text-only prompt to the LLM and return the response.

    Used for diet analysis, advice, and summaries.
    """
    if LLM_PROVIDER == "anthropic":
        return await _ask_anthropic(prompt, context_data)
    else:
        return await _ask_openai(prompt, context_data)


async def _ask_openai(prompt: str, context_data: str) -> str:
    import httpx

    messages = []
    if context_data:
        messages.append({"role": "system", "content": f"Here is the user's meal data:\n{context_data}"})
    messages.append({"role": "user", "content": prompt})

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENAI_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": OPENAI_MODEL,
                "messages": messages,
                "max_tokens": 3000,
                "temperature": 0.7,
            },
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


async def _ask_anthropic(prompt: str, context_data: str) -> str:
    import httpx

    full_prompt = prompt
    if context_data:
        full_prompt = f"Here is the user's meal data:\n{context_data}\n\n{prompt}"

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json",
            },
            json={
                "model": ANTHROPIC_MODEL,
                "max_tokens": 3000,
                "messages": [{"role": "user", "content": full_prompt}],
            },
        )
        resp.raise_for_status()
        return resp.json()["content"][0]["text"]
