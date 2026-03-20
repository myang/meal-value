#!/usr/bin/env python3
"""Weekly digest script — run via cron to send scheduled nutrition summaries."""

import asyncio
import logging
import sys

from telegram import Bot
from telegram.constants import ParseMode

from config import TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS
from database import init_db, get_week_meals, get_month_meals
from nutrition_advisor import format_period_summary, get_llm_advice

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def send_weekly_digest():
    """Generate and send weekly digest to all allowed users."""
    init_db()
    bot = Bot(token=TELEGRAM_BOT_TOKEN)

    if not ALLOWED_USER_IDS:
        logger.error("No ALLOWED_USER_IDS configured — don't know who to send digest to.")
        return

    # Generate weekly summary
    meals = get_week_meals()
    summary = format_period_summary(meals, "Weekly")

    # Generate LLM advice
    advice = ""
    if meals:
        try:
            advice = await get_llm_advice("week")
        except Exception as e:
            logger.error(f"Failed to generate advice: {e}")
            advice = "(Could not generate AI advice this week)"

    message = f"📬 *Weekly Nutrition Digest*\n\n{summary}"
    if advice:
        message += f"\n\n💡 *AI Advice:*\n{advice}"

    # Send to all allowed users
    for user_id in ALLOWED_USER_IDS:
        try:
            await bot.send_message(
                chat_id=user_id,
                text=message,
                parse_mode=ParseMode.MARKDOWN,
            )
            logger.info(f"Sent weekly digest to user {user_id}")
        except Exception as e:
            logger.error(f"Failed to send digest to {user_id}: {e}")


async def send_monthly_digest():
    """Generate and send monthly digest."""
    init_db()
    bot = Bot(token=TELEGRAM_BOT_TOKEN)

    if not ALLOWED_USER_IDS:
        return

    meals = get_month_meals()
    summary = format_period_summary(meals, "Monthly")

    advice = ""
    if meals:
        try:
            advice = await get_llm_advice("month")
        except Exception as e:
            logger.error(f"Failed to generate monthly advice: {e}")

    message = f"📬 *Monthly Nutrition Digest*\n\n{summary}"
    if advice:
        message += f"\n\n💡 *AI Advice:*\n{advice}"

    for user_id in ALLOWED_USER_IDS:
        try:
            await bot.send_message(
                chat_id=user_id,
                text=message,
                parse_mode=ParseMode.MARKDOWN,
            )
        except Exception as e:
            logger.error(f"Failed to send monthly digest to {user_id}: {e}")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "week"
    if mode == "month":
        asyncio.run(send_monthly_digest())
    else:
        asyncio.run(send_weekly_digest())
