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

# The auto-fallback list. If a model hits a 429 (Quota) or 503 (Overloaded) error, 
# it will instantly jump to the next model without crashing.
MODELS_TO_TRY = [
    "gemini-3.5-flash", 
    "gemini-2.5-flash", 
    "gemini-flash-latest"
]

async def generate_ai_response(agent_username: str, user_message: str) -> str:
    """Generate a response using Gemini based on the agent's persona."""
    if not settings.gemini_api_key or not client:
        return f"Hello! I am {agent_username}. My AI capabilities are currently offline because the GEMINI_API_KEY is missing."

    system_instruction = AI_PERSONAS.get(agent_username, "You are a helpful AI assistant.")
    
    for model_name in MODELS_TO_TRY:
        try:
            response = await client.aio.models.generate_content(
                model=model_name,
                contents=user_message,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction
                )
            )
            return response.text
        except Exception as e:
            logger.warning(f"Model {model_name} failed: {e}. Trying next...")
            continue
            
    logger.error("All AI models failed.")
    return "I'm sorry, my systems are currently experiencing an error and I cannot respond properly."


async def generate_ai_response_stream(agent_username: str, user_message: str):
    """Generate a streamed response using Gemini based on the agent's persona."""
    if not settings.gemini_api_key or not client:
        yield f"Hello! I am {agent_username}. My AI capabilities are currently offline because the GEMINI_API_KEY is missing."
        return

    system_instruction = AI_PERSONAS.get(agent_username, "You are a helpful AI assistant.")
    
    for model_name in MODELS_TO_TRY:
        try:
            response_stream = await client.aio.models.generate_content_stream(
                model=model_name,
                contents=user_message,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction
                )
            )
            
            # Test if stream works by attempting to get the first chunk
            # If it fails, it will raise an exception and fall back to the next model
            first_chunk_received = False
            async for chunk in response_stream:
                first_chunk_received = True
                if chunk.text:
                    yield chunk.text
                    
            if first_chunk_received:
                return # Successfully streamed, exit the function
                
        except Exception as e:
            logger.warning(f"Model {model_name} stream failed: {e}. Trying next...")
            continue
            
    logger.error("All AI models failed to stream.")
    yield "I'm sorry, my systems are currently experiencing an error and I cannot respond properly."
