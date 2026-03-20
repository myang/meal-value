#!/bin/bash
# Uninstall MealValue service and cron jobs
set -e

LABEL="com.mealvalue.bot"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "🍽  MealValue Service Uninstaller"
echo "================================="

# Stop and remove LaunchAgent
if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm "$PLIST_PATH"
    echo "✅ LaunchAgent removed"
else
    echo "ℹ️  No LaunchAgent found"
fi

# Remove cron jobs
CRON_MARKER="# MealValue digest"
(crontab -l 2>/dev/null | grep -v "$CRON_MARKER") | crontab -
echo "✅ Cron jobs removed"

echo ""
echo "🎉 Service uninstalled."
echo "Note: Your meal data in ~/MealData is preserved."
