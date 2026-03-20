#!/bin/bash
# Install MealValue as a macOS LaunchAgent (auto-start on login)
# and set up weekly digest cron job.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_PYTHON="$PROJECT_DIR/venv/bin/python"
LABEL="com.mealvalue.bot"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "🍽  MealValue Service Installer"
echo "================================"

# Check venv exists
if [ ! -f "$VENV_PYTHON" ]; then
    echo "❌ Virtual environment not found. Run setup.sh first."
    exit 1
fi

# --- LaunchAgent for the bot ---

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$VENV_PYTHON</string>
        <string>$PROJECT_DIR/bot/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/MealData/bot.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/MealData/bot_error.log</string>
</dict>
</plist>
EOF

echo "✅ LaunchAgent created: $PLIST_PATH"

# Load the service
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
echo "✅ Bot service started (auto-starts on login)"

# --- Cron for weekly digest ---

DIGEST_CMD="$VENV_PYTHON $PROJECT_DIR/bot/weekly_digest.py week"
MONTHLY_CMD="$VENV_PYTHON $PROJECT_DIR/bot/weekly_digest.py month"

# Add cron jobs (Sunday 8pm weekly, 1st of month 8pm monthly)
CRON_MARKER="# MealValue digest"
(crontab -l 2>/dev/null | grep -v "$CRON_MARKER") | cat - << EOF | crontab -
0 20 * * 0 cd $PROJECT_DIR && $DIGEST_CMD $CRON_MARKER
0 20 1 * * cd $PROJECT_DIR && $MONTHLY_CMD $CRON_MARKER
EOF

echo "✅ Weekly digest: Sunday 8:00 PM"
echo "✅ Monthly digest: 1st of month 8:00 PM"

echo ""
echo "🎉 Service installed!"
echo ""
echo "Useful commands:"
echo "  View logs:     tail -f ~/MealData/bot.log"
echo "  Stop bot:      launchctl unload $PLIST_PATH"
echo "  Start bot:     launchctl load $PLIST_PATH"
echo "  Test digest:   $DIGEST_CMD"
