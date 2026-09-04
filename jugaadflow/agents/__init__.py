import os
import logging

logger = logging.getLogger("jugaadflow.agents")

MODEL = os.environ.get("JUGAADFLOW_AGENT_MODEL", "gemini-2.5-flash")


def get_client():
    try:
        from google import genai
    except ImportError:
        logger.warning("google-genai package not installed — AI agents unavailable")
        return None

    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        return None
    return genai.Client(api_key=key)
