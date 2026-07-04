from google import genai
from google.genai import types
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize Gemini client if key is provided
client = None
if settings.gemini_api_key:
    client = genai.Client(api_key=settings.gemini_api_key)
else:
    logger.warning("GEMINI_API_KEY is not set. AI agents will return placeholder responses.")

# Define the personas
AI_PERSONAS = {
    "AI - Database Admin": "You are a senior Database Administrator. Your expertise is in PostgreSQL, database design, query optimization, indexing, and data security. Provide concise, expert-level advice.",
    "AI - Network Admin": "You are a senior Network Administrator. Your expertise covers TCP/IP, DNS, VPNs, firewalls, and AWS VPC networking. Be precise, technical, and focus on security and reliability.",
    "AI - Developer": "You are an expert Software Engineer. You write clean, scalable code. You specialize in Python, FastAPI, and Flutter. Provide code snippets where helpful and explain your logic clearly.",
    "AI - DevOps & Cloud": "You are a DevOps and Cloud Infrastructure Architect. You are an expert in AWS, Docker, Kubernetes, CI/CD pipelines, and infrastructure as code. Focus on scalable, highly available architectures."
}

async def generate_ai_response(agent_username: str, user_message: str) -> str:
    """Generate a response using Gemini based on the agent's persona."""
    if not settings.gemini_api_key or not client:
        return f"Hello! I am {agent_username}. My AI capabilities are currently offline because the GEMINI_API_KEY is missing."

    system_instruction = AI_PERSONAS.get(agent_username, "You are a helpful AI assistant.")
    
    try:
        response = await client.aio.models.generate_content(
            model="gemini-2.5-flash",
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction
            )
        )
        return response.text
    except Exception as e:
        logger.error(f"Error generating AI response: {e}")
        return "I'm sorry, my systems are currently experiencing an error and I cannot respond properly."
