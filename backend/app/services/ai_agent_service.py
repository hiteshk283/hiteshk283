import google.generativeai as genai
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize Gemini if key is provided
if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)
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
    if not settings.gemini_api_key:
        return f"Hello! I am {agent_username}. My AI capabilities are currently offline because the GEMINI_API_KEY is missing."

    system_instruction = AI_PERSONAS.get(agent_username, "You are a helpful AI assistant.")
    
    try:
        # Use gemini-1.5-flash as it is fast and has a good free tier
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=system_instruction
        )
        
        # Note: Depending on the generativeai version, generating a response is synchronous.
        # Running it in an executor would be better for a production FastAPI app, but for now we'll call it directly.
        response = model.generate_content(user_message)
        return response.text
    except Exception as e:
        logger.error(f"Error generating AI response: {e}")
        return "I'm sorry, my systems are currently experiencing an error and I cannot respond properly."
