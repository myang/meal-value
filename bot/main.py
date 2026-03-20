#!/usr/bin/env python3
"""MealValue Telegram Bot — meal nutrition tracker powered by LLM vision."""

import logging
from io import BytesIO

from telegram import (
    Update, InlineKeyboardButton, InlineKeyboardMarkup, InputMediaPhoto,
)
from telegram.ext import (
    Application, CommandHandler, MessageHandler, CallbackQueryHandler,
    ConversationHandler, ContextTypes, filters,
)
from telegram.constants import ParseMode

from config import TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS
from database import (
    init_db, create_meal, add_layer, add_food_item, update_meal_score,
    get_meal, delete_meal,
)
from photo_storage import save_photo, get_photo_bytes
from llm_analyzer import analyze_photo
from nutrition_advisor import (
    score_meal, format_meal_summary, format_today_summary,
    format_period_summary, get_llm_advice, get_llm_meal_feedback,
    get_week_meals, get_month_meals,
)

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

# Conversation states
CHOOSE_TYPE, ADD_LAYERS, CONFIRM_SAVE = range(3)


# --- Auth ---

def authorized(func):
    """Decorator to restrict bot access to allowed user IDs."""
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        user_id = update.effective_user.id
        if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
            await update.message.reply_text("⛔ You are not authorized to use this bot.")
            return
        return await func(update, context)
    return wrapper


# --- Command handlers ---

@authorized
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🍽 *Welcome to MealValue!*\n\n"
        "I help you track meal nutrition by analyzing food photos with AI.\n\n"
        "*Commands:*\n"
        "/meal — Record a new meal (photo by photo)\n"
        "/quick — Quick: just send a photo, I'll analyze it\n"
        "/today — Today's nutrition summary\n"
        "/week — Weekly summary\n"
        "/month — Monthly summary\n"
        "/advice — Get personalized nutrition advice\n"
        "/history — Recent meal history\n"
        "/stats — Storage stats\n"
        "/help — Show this message\n\n"
        "Or just *send a food photo* anytime for quick analysis!",
        parse_mode=ParseMode.MARKDOWN,
    )


@authorized
async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await cmd_start(update, context)


# --- Quick photo analysis (just send a photo) ---

@authorized
async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle a photo sent outside of a conversation — quick analysis."""
    msg = await update.message.reply_text("🔍 Analyzing your food photo...")

    photo = update.message.photo[-1]  # highest resolution
    file = await photo.get_file()
    bio = BytesIO()
    await file.download_to_memory(bio)
    photo_bytes = bio.getvalue()

    caption = update.message.caption or ""
    context_text = f"Meal photo. User note: {caption}" if caption else "A meal photo"

    try:
        result = await analyze_photo(photo_bytes, context_text)
    except Exception as e:
        logger.error(f"Photo analysis failed: {e}")
        await msg.edit_text(f"❌ Analysis failed: {e}\n\nTry /meal for structured recording.")
        return

    # Save to database
    meal_type = "meal"
    if caption:
        for t in ["breakfast", "lunch", "dinner", "snack"]:
            if t in caption.lower():
                meal_type = t
                break

    meal_id = create_meal(meal_type=meal_type, notes=caption)
    layer_name = caption or "Main"
    rel_path = save_photo(photo_bytes, meal_id, layer_name)
    layer_id = add_layer(meal_id, layer_name, photo_path=rel_path)

    for food in result.get("foods", []):
        add_food_item(layer_id, **food)

    meal = get_meal(meal_id)
    score = score_meal(meal)
    update_meal_score(meal_id, score)
    meal["score"] = score

    summary = format_meal_summary(meal)

    # Get quick LLM feedback
    try:
        feedback = await get_llm_meal_feedback(meal)
        summary += f"\n\n💡 *Feedback:*\n{feedback}"
    except Exception:
        pass

    await msg.edit_text(summary, parse_mode=ParseMode.MARKDOWN)


# --- Structured meal recording conversation ---

@authorized
async def cmd_meal(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Start structured meal recording."""
    keyboard = [
        [
            InlineKeyboardButton("🌅 Breakfast", callback_data="type_breakfast"),
            InlineKeyboardButton("☀️ Lunch", callback_data="type_lunch"),
        ],
        [
            InlineKeyboardButton("🌙 Dinner", callback_data="type_dinner"),
            InlineKeyboardButton("🥕 Snack", callback_data="type_snack"),
        ],
    ]
    await update.message.reply_text(
        "🍽 *New Meal*\n\nWhat type of meal?",
        reply_markup=InlineKeyboardMarkup(keyboard),
        parse_mode=ParseMode.MARKDOWN,
    )
    return CHOOSE_TYPE


async def meal_type_chosen(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle meal type selection."""
    query = update.callback_query
    await query.answer()

    meal_type = query.data.replace("type_", "")
    meal_id = create_meal(meal_type=meal_type)
    context.user_data["meal_id"] = meal_id
    context.user_data["layer_count"] = 0

    await query.edit_message_text(
        f"✅ Started *{meal_type}* recording.\n\n"
        "Now send photos of your food, layer by layer:\n"
        "1️⃣ First photo = base layer (e.g., vegetables)\n"
        "2️⃣ Next photo = next layer (e.g., grains)\n"
        "3️⃣ Keep going until done\n\n"
        "📸 *Send your first food photo now!*\n\n"
        "You can add a caption to name the layer (e.g., \"vegetables base\").\n"
        "When done, tap /done to save the meal.",
        parse_mode=ParseMode.MARKDOWN,
    )
    return ADD_LAYERS


async def receive_layer_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Receive a photo for a meal layer."""
    meal_id = context.user_data.get("meal_id")
    if not meal_id:
        await update.message.reply_text("No active meal. Use /meal to start.")
        return ADD_LAYERS

    layer_count = context.user_data.get("layer_count", 0)
    caption = update.message.caption or ""

    # Auto-name layers
    if caption:
        layer_name = caption
    else:
        default_names = ["Base layer", "Middle layer", "Top layer", "Extra layer"]
        layer_name = default_names[min(layer_count, len(default_names) - 1)]

    msg = await update.message.reply_text(f"🔍 Analyzing *{layer_name}*...", parse_mode=ParseMode.MARKDOWN)

    # Download photo
    photo = update.message.photo[-1]
    file = await photo.get_file()
    bio = BytesIO()
    await file.download_to_memory(bio)
    photo_bytes = bio.getvalue()

    # Save photo
    rel_path = save_photo(photo_bytes, meal_id, layer_name)

    # Analyze with LLM
    try:
        result = await analyze_photo(photo_bytes, f"{layer_name} of a meal")
        ai_raw = str(result)
    except Exception as e:
        logger.error(f"Layer analysis failed: {e}")
        await msg.edit_text(
            f"⚠️ Couldn't analyze *{layer_name}*: {e}\n"
            "Photo saved. Send next layer or /done to finish.",
            parse_mode=ParseMode.MARKDOWN,
        )
        # Still save the layer without food items
        add_layer(meal_id, layer_name, photo_path=rel_path)
        context.user_data["layer_count"] = layer_count + 1
        return ADD_LAYERS

    # Save layer and food items
    layer_id = add_layer(meal_id, layer_name, photo_path=rel_path, ai_raw=ai_raw)
    for food in result.get("foods", []):
        add_food_item(layer_id, **food)

    context.user_data["layer_count"] = layer_count + 1

    # Format layer results
    foods_text = "\n".join(
        f"  • {f['name']} — {f.get('portion_desc', '')} ({f['calories']:.0f} kcal)"
        for f in result.get("foods", [])
    )
    desc = result.get("meal_description", "")

    await msg.edit_text(
        f"✅ *{layer_name}* — {desc}\n\n"
        f"Detected foods:\n{foods_text}\n\n"
        f"📸 Send next layer photo, or /done to save meal.",
        parse_mode=ParseMode.MARKDOWN,
    )
    return ADD_LAYERS


async def cmd_done(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Finish recording and save the meal."""
    meal_id = context.user_data.get("meal_id")
    if not meal_id:
        await update.message.reply_text("No active meal recording.")
        return ConversationHandler.END

    meal = get_meal(meal_id)
    if not meal or not meal.get("layers"):
        await update.message.reply_text("No layers recorded. Meal discarded.")
        delete_meal(meal_id)
        context.user_data.clear()
        return ConversationHandler.END

    # Score the meal
    score = score_meal(meal)
    update_meal_score(meal_id, score)
    meal["score"] = score

    summary = format_meal_summary(meal)

    # Get LLM feedback
    try:
        feedback = await get_llm_meal_feedback(meal)
        summary += f"\n\n💡 *Feedback:*\n{feedback}"
    except Exception:
        pass

    await update.message.reply_text(
        f"🎉 *Meal saved!*\n\n{summary}",
        parse_mode=ParseMode.MARKDOWN,
    )

    context.user_data.clear()
    return ConversationHandler.END


async def cmd_cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Cancel current meal recording."""
    meal_id = context.user_data.get("meal_id")
    if meal_id:
        delete_meal(meal_id)
    context.user_data.clear()
    await update.message.reply_text("❌ Meal recording cancelled.")
    return ConversationHandler.END


# --- Summary commands ---

@authorized
async def cmd_today(update: Update, context: ContextTypes.DEFAULT_TYPE):
    summary = format_today_summary()
    await update.message.reply_text(summary, parse_mode=ParseMode.MARKDOWN)


@authorized
async def cmd_week(update: Update, context: ContextTypes.DEFAULT_TYPE):
    meals = get_week_meals()
    summary = format_period_summary(meals, "Weekly")
    await update.message.reply_text(summary, parse_mode=ParseMode.MARKDOWN)


@authorized
async def cmd_month(update: Update, context: ContextTypes.DEFAULT_TYPE):
    meals = get_month_meals()
    summary = format_period_summary(meals, "Monthly")
    await update.message.reply_text(summary, parse_mode=ParseMode.MARKDOWN)


@authorized
async def cmd_advice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Get LLM-powered nutrition advice."""
    keyboard = [
        [
            InlineKeyboardButton("📅 This Week", callback_data="advice_week"),
            InlineKeyboardButton("📆 This Month", callback_data="advice_month"),
        ],
    ]
    await update.message.reply_text(
        "📊 Analyze which period?",
        reply_markup=InlineKeyboardMarkup(keyboard),
    )


async def advice_period_chosen(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    period = query.data.replace("advice_", "")
    await query.edit_message_text(f"🤔 Analyzing your {period}'s meals with AI...")

    try:
        advice = await get_llm_advice(period)
        await query.edit_message_text(
            f"💡 *Nutrition Advice ({period}):*\n\n{advice}",
            parse_mode=ParseMode.MARKDOWN,
        )
    except Exception as e:
        await query.edit_message_text(f"❌ Failed to generate advice: {e}")


@authorized
async def cmd_history(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show recent meal history."""
    meals = get_week_meals()
    if not meals:
        await update.message.reply_text("No meals recorded this week.")
        return

    lines = ["📋 *Recent Meals:*\n"]
    for meal in meals[-10:]:  # last 10
        score_emoji = "🟢" if meal.get("score", 0) >= 70 else "🟡" if meal.get("score", 0) >= 50 else "🔴"
        food_count = sum(len(l.get("food_items", [])) for l in meal.get("layers", []))
        calories = sum(
            item.get("calories", 0)
            for l in meal.get("layers", [])
            for item in l.get("food_items", [])
        )
        lines.append(
            f"{score_emoji} *{meal['meal_type'].title()}* {meal['date']} {meal['time']} — "
            f"{calories:.0f} kcal, {food_count} items, score {meal.get('score', 0)}"
        )

    lines.append(f"\n_{len(meals)} meals this week_")
    await update.message.reply_text("\n".join(lines), parse_mode=ParseMode.MARKDOWN)


@authorized
async def cmd_stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show storage statistics."""
    from photo_storage import get_storage_stats
    from database import get_all_meals

    stats = get_storage_stats()
    all_meals = get_all_meals()

    await update.message.reply_text(
        "📊 *Storage Stats:*\n\n"
        f"Total meals: {len(all_meals)}\n"
        f"Total photos: {stats['total_photos']}\n"
        f"Photo storage: {stats['total_size_mb']} MB\n"
        f"Path: `{stats['storage_path']}`",
        parse_mode=ParseMode.MARKDOWN,
    )


# --- Free-form questions about diet ---

@authorized
async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle free-form text questions about diet."""
    text = update.message.text.strip()

    # Check if it looks like a diet/food question
    food_keywords = [
        "diet", "eat", "food", "nutrition", "meal", "calorie", "protein",
        "health", "weight", "vitamin", "should i", "what about", "how",
        "analyze", "review", "suggest", "advice", "improve", "better",
    ]
    is_food_question = any(kw in text.lower() for kw in food_keywords)

    if not is_food_question:
        await update.message.reply_text(
            "I'm your meal tracker! Send a food photo, or try:\n"
            "/meal — Record a meal\n"
            "/today — Today's summary\n"
            "/advice — Get nutrition advice\n\n"
            "Or ask me any question about your diet!"
        )
        return

    msg = await update.message.reply_text("🤔 Thinking...")

    # Build context from recent meals
    from database import get_week_meals, export_all_as_json
    meals = get_week_meals()
    from nutrition_advisor import format_period_summary
    context_data = format_period_summary(meals, "this week") if meals else "No recent meals recorded."

    try:
        from llm_analyzer import ask_llm
        response = await ask_llm(
            f"The user asks about their diet: \"{text}\"\n\n"
            "Answer based on their recent meal data. Be helpful and specific.",
            context_data,
        )
        await msg.edit_text(response, parse_mode=ParseMode.MARKDOWN)
    except Exception as e:
        await msg.edit_text(f"Sorry, couldn't process that: {e}")


# --- Main ---

def main():
    init_db()

    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    # Structured meal recording conversation
    meal_conv = ConversationHandler(
        entry_points=[CommandHandler("meal", cmd_meal)],
        states={
            CHOOSE_TYPE: [CallbackQueryHandler(meal_type_chosen, pattern=r"^type_")],
            ADD_LAYERS: [
                MessageHandler(filters.PHOTO, receive_layer_photo),
                CommandHandler("done", cmd_done),
            ],
        },
        fallbacks=[CommandHandler("cancel", cmd_cancel)],
        per_user=True,
    )

    app.add_handler(meal_conv)

    # Simple commands
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("help", cmd_help))
    app.add_handler(CommandHandler("today", cmd_today))
    app.add_handler(CommandHandler("week", cmd_week))
    app.add_handler(CommandHandler("month", cmd_month))
    app.add_handler(CommandHandler("advice", cmd_advice))
    app.add_handler(CommandHandler("history", cmd_history))
    app.add_handler(CommandHandler("stats", cmd_stats))

    # Callback queries
    app.add_handler(CallbackQueryHandler(advice_period_chosen, pattern=r"^advice_"))

    # Quick photo analysis (outside conversation)
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    # Free-form text questions
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    logger.info("MealValue bot starting...")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
