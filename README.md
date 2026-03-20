# MealValue

A meal nutrition tracker that runs on your Mac Mini. Take food photos on your iPhone, send them via Telegram, and get AI-powered nutrition analysis, scoring, and personalized diet advice — all with your data stored privately at home.

## How It Works

```
┌─────────────┐    photo via Telegram     ┌──────────────────────┐
│   iPhone    │ ────────────────────────→  │     Mac Mini         │
│             │                            │                      │
│  • Camera   │                            │  • Telegram Bot      │
│  • Telegram │ ←────────────────────────  │  • LLM Analysis      │
│             │    analysis + advice       │  • SQLite + Photos   │
└─────────────┘                            │  • Weekly Digests    │
                                           └──────────────────────┘
```

1. **Take a photo** of your meal on iPhone
2. **Send it via Telegram** to your bot (with optional caption like "lunch" or "vegetables base")
3. **AI analyzes** the photo — identifies foods, estimates portions and nutrition
4. **Data is stored** locally on your Mac Mini (SQLite DB + organized photo files)
5. **Ask anytime** — "/week", "/advice", or free-form diet questions
6. **Weekly digest** — automatic Sunday summary with AI-powered advice

## Features

- **Layer-by-layer recording** — `/meal` starts a structured session: photograph each layer (vegetables base, protein top, etc.)
- **Quick capture** — just send any food photo for instant analysis
- **Dual LLM support** — OpenAI (GPT-4o) or Anthropic (Claude) for food recognition
- **Nutrition scoring** — 0-100 quality score based on protein balance, fiber, variety, sodium, etc.
- **Weekly & monthly summaries** — daily calorie breakdown, macro splits, score trends
- **AI diet advice** — personalized recommendations based on your eating patterns
- **Free-form questions** — ask "Am I getting enough protein?" and get answers based on your data
- **Private storage** — all data stays on your Mac Mini, accessible via OpenClaw
- **Auto weekly digest** — cron job sends nutrition reports every Sunday

## Telegram Commands

| Command | Description |
|---------|-------------|
| `/meal` | Start structured meal recording (layer by layer) |
| `/today` | Today's nutrition summary |
| `/week` | Weekly summary with daily breakdown |
| `/month` | Monthly summary |
| `/advice` | Get AI-powered nutrition advice |
| `/history` | Recent meal history |
| `/stats` | Storage statistics |
| Send photo | Quick analysis of any food photo |
| Send text | Ask any diet/nutrition question |

## Setup on Mac Mini

### 1. Prerequisites

```bash
# Python 3.10+ required
python3 --version
```

### 2. Create Telegram Bot

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow prompts
3. Copy the bot token

### 3. Get Your Telegram User ID

1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. Copy the user ID number

### 4. Install

```bash
git clone <this-repo> ~/meal-value
cd ~/meal-value
./scripts/setup.sh
```

### 5. Configure

Edit `.env` with your keys:

```bash
nano .env
```

Required settings:
```
TELEGRAM_BOT_TOKEN=your_bot_token
ALLOWED_USER_IDS=your_telegram_id
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key
```

### 6. Run

```bash
# Manual start
source venv/bin/activate
python bot/main.py

# Or install as auto-starting service (recommended)
./scripts/install_service.sh
```

This installs:
- **LaunchAgent** — bot auto-starts on login, restarts on crash
- **Weekly cron** — sends digest every Sunday at 8 PM
- **Monthly cron** — sends monthly summary on the 1st

### Service Management

```bash
# View logs
tail -f ~/MealData/bot.log

# Stop bot
launchctl unload ~/Library/LaunchAgents/com.mealvalue.bot.plist

# Start bot
launchctl load ~/Library/LaunchAgents/com.mealvalue.bot.plist

# Uninstall everything
./scripts/uninstall_service.sh
```

## Data Storage

All data is stored locally in `~/MealData/`:

```
~/MealData/
├── meals.db              # SQLite database (all nutrition data)
├── photos/               # Organized meal photos
│   └── 2026/
│       └── 03/
│           └── 20/
│               ├── meal1_vegetables_base_120530.jpg
│               └── meal1_protein_top_120545.jpg
├── bot.log               # Bot output log
└── bot_error.log         # Error log
```

### Accessing Data via OpenClaw

Since the data lives on your Mac Mini, you can access it through OpenClaw:
- Query the SQLite database directly
- Ask OpenClaw to analyze your meal history
- Export data as JSON: the database module has `export_all_as_json()`

## iOS Shortcut (Optional)

For even faster capture, create an iOS Shortcut:

1. Open **Shortcuts** app on iPhone
2. Create new shortcut:
   - **Take Photo** (front camera off, show preview on)
   - **Ask for Input** → "Meal type?" (text)
   - **Get Contents of URL**:
     - URL: `https://api.telegram.org/bot<YOUR_TOKEN>/sendPhoto`
     - Method: POST
     - Form: `chat_id` = your ID, `photo` = photo, `caption` = input
3. Add to Home Screen for one-tap meal capture

## Architecture

```
bot/
├── main.py               # Telegram bot entry point + handlers
├── config.py             # Environment configuration
├── database.py           # SQLite schema + CRUD + aggregation
├── photo_storage.py      # Organized file storage for photos
├── llm_analyzer.py       # OpenAI/Claude Vision photo analysis
├── nutrition_advisor.py  # Scoring, summaries, LLM advice
├── weekly_digest.py      # Cron script for scheduled reports
└── requirements.txt      # Python dependencies

scripts/
├── setup.sh              # First-time setup
├── install_service.sh    # Install as macOS service + cron
└── uninstall_service.sh  # Clean uninstall
```

## Using Claude Instead of ChatGPT

Change in `.env`:
```
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-your-key
ANTHROPIC_MODEL=claude-sonnet-4-20250514
```

Both providers use the same photo analysis prompt and produce identical JSON output.
