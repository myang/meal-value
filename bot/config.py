import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# --- Telegram ---
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
# Comma-separated Telegram user IDs allowed to use the bot (empty = allow all)
ALLOWED_USER_IDS = [
    int(uid.strip())
    for uid in os.getenv("ALLOWED_USER_IDS", "").split(",")
    if uid.strip()
]

# --- LLM Provider ---
# "openai" or "anthropic"
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "openai")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")

# --- Storage ---
DATA_DIR = Path(os.getenv("DATA_DIR", str(Path.home() / "MealData")))
PHOTO_DIR = DATA_DIR / "photos"
DB_PATH = DATA_DIR / "meals.db"

# --- Weekly Digest ---
WEEKLY_DIGEST_DAY = os.getenv("WEEKLY_DIGEST_DAY", "sunday")  # day of week
WEEKLY_DIGEST_HOUR = int(os.getenv("WEEKLY_DIGEST_HOUR", "20"))  # 24h format

# --- Nutrition Defaults ---
DAILY_CALORIE_TARGET = int(os.getenv("DAILY_CALORIE_TARGET", "2000"))

# Ensure directories exist
DATA_DIR.mkdir(parents=True, exist_ok=True)
PHOTO_DIR.mkdir(parents=True, exist_ok=True)
