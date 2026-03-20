#!/bin/bash
# MealValue Setup Script for Mac Mini
set -e

echo "🍽  MealValue Setup"
echo "==================="
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required. Install with: brew install python3"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✅ Python $PYTHON_VERSION found"

# Create virtual environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
echo "✅ Virtual environment activated"

# Install dependencies
echo "📦 Installing dependencies..."
pip install -q -r "$PROJECT_DIR/bot/requirements.txt"
echo "✅ Dependencies installed"

# Create .env if not exists
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    cp "$PROJECT_DIR/.env.example" "$ENV_FILE"
    echo ""
    echo "⚙️  Created .env file. Please edit it with your settings:"
    echo "   $ENV_FILE"
    echo ""
    echo "   Required:"
    echo "   - TELEGRAM_BOT_TOKEN  (get from @BotFather on Telegram)"
    echo "   - ALLOWED_USER_IDS    (get from @userinfobot on Telegram)"
    echo "   - OPENAI_API_KEY      (from platform.openai.com)"
    echo ""
else
    echo "✅ .env file exists"
fi

# Create data directory
DATA_DIR="${DATA_DIR:-$HOME/MealData}"
mkdir -p "$DATA_DIR/photos"
echo "✅ Data directory: $DATA_DIR"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To start the bot:"
echo "  cd $PROJECT_DIR"
echo "  source venv/bin/activate"
echo "  python bot/main.py"
echo ""
echo "To run as a background service, see: scripts/install_service.sh"
