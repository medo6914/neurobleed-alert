import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class LLMGateway:
    """Unified LLM gateway. Provider chain: Ollama (local, free) -> OpenAI -> Gemini -> HuggingFace.
    Returns graceful error responses when no provider is configured."""

    def __init__(self) -> None:
        self._client: httpx.AsyncClient | None = None

    @property
    def client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0))
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    def providers_available(self) -> list[str]:
        providers = []
        if settings.OLLAMA_BASE_URL:
            providers.append("ollama")
        if settings.OPENAI_API_KEY:
            providers.append("openai")
        if settings.GEMINI_API_KEY:
            providers.append("gemini")
        if settings.HUGGINGFACE_API_KEY:
            providers.append("huggingface")
        return providers

    async def chat(
        self, system_prompt: str, user_message: str, provider: str | None = None
    ) -> dict[str, Any]:
        order = [provider] if provider else self.providers_available()
        order = [p for p in order if p]
        if not order:
            return {
                "ok": False,
                "message": "No LLM provider configured. Install Ollama locally (free, no API key) or add OPENAI_API_KEY / GEMINI_API_KEY / HUGGINGFACE_API_KEY.",
                "provider": None,
            }

        errors = []
        for name in order:
            try:
                result = await self._call_provider(name, system_prompt, user_message)
                if result.get("ok"):
                    result["provider"] = name
                    return result
                errors.append(f"{name}: {result.get('message')}")
            except Exception as e:
                logger.warning("LLM provider %s failed: %s", name, e)
                errors.append(f"{name}: {e}")

        return {
            "ok": False,
            "message": "; ".join(errors),
            "provider": None,
        }

    async def _call_provider(
        self, name: str, system_prompt: str, user_message: str
    ) -> dict[str, Any]:
        if name == "ollama":
            return await self._ollama(system_prompt, user_message)
        if name == "openai":
            return await self._openai(system_prompt, user_message)
        if name == "gemini":
            return await self._gemini(system_prompt, user_message)
        if name == "huggingface":
            return await self._huggingface(system_prompt, user_message)
        return {"ok": False, "message": f"Unknown provider {name}"}

    async def _ollama(self, system_prompt: str, user_message: str) -> dict[str, Any]:
        base = settings.OLLAMA_BASE_URL.rstrip("/")
        try:
            resp = await self.client.post(
                f"{base}/api/chat",
                json={
                    "model": settings.OLLAMA_MODEL,
                    "stream": False,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_message},
                    ],
                },
            )
            resp.raise_for_status()
            data = resp.json()
            content = data.get("message", {}).get("content", "")
            return {
                "ok": True,
                "content": content,
                "model": f"ollama/{settings.OLLAMA_MODEL}",
            }
        except Exception as e:
            return {"ok": False, "message": f"Ollama not reachable at {base}: {e}"}

    async def _openai(self, system_prompt: str, user_message: str) -> dict[str, Any]:
        resp = await self.client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
            json={
                "model": settings.OPENAI_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
            },
        )
        resp.raise_for_status()
        data = resp.json()
        return {
            "ok": True,
            "content": data["choices"][0]["message"]["content"],
            "model": settings.OPENAI_MODEL,
        }

    async def _gemini(self, system_prompt: str, user_message: str) -> dict[str, Any]:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_MODEL}:generateContent"
        resp = await self.client.post(
            url,
            params={"key": settings.GEMINI_API_KEY},
            json={
                "system_instruction": {"parts": [{"text": system_prompt}]},
                "contents": [{"role": "user", "parts": [{"text": user_message}]}],
            },
        )
        resp.raise_for_status()
        data = resp.json()
        content = data["candidates"][0]["content"]["parts"][0]["text"]
        return {"ok": True, "content": content, "model": settings.GEMINI_MODEL}

    async def _huggingface(
        self, system_prompt: str, user_message: str
    ) -> dict[str, Any]:
        prompt = f"{system_prompt}\n\nUser: {user_message}\nAssistant:"
        resp = await self.client.post(
            f"https://api-inference.huggingface.co/models/{settings.HUGGINGFACE_MODEL}",
            headers={"Authorization": f"Bearer {settings.HUGGINGFACE_API_KEY}"},
            json={"inputs": prompt, "parameters": {"max_new_tokens": 500}},
        )
        resp.raise_for_status()
        data = resp.json()
        if isinstance(data, list) and data:
            content = data[0].get("generated_text", "")
            content = content[len(prompt) :].strip()
            return {"ok": True, "content": content, "model": settings.HUGGINGFACE_MODEL}
        return {"ok": False, "message": "Unexpected HuggingFace response"}


llm_gateway = LLMGateway()
