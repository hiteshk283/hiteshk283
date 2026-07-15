import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("No API Key found in .env")
    exit(1)

try:
    client = genai.Client(api_key=api_key)
    models = list(client.models.list())
    for m in models:
        if 'gemini' in m.name.lower():
            print(f"Found: {m.name}")
except Exception as e:
    print(f"Error listing models: {e}")
