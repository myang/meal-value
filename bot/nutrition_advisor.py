"""Nutrition analysis, scoring, and LLM-powered diet advice."""

import json
from database import (
    aggregate_nutrition, daily_breakdown,
    get_week_meals, get_month_meals, get_today_meals,
)
from llm_analyzer import ask_llm
from config import DAILY_CALORIE_TARGET


def score_meal(meal: dict) -> int:
    """Calculate a nutrition quality score (0–100) for a meal."""
    totals = aggregate_nutrition([meal])
    cal = totals["calories"]
    if cal == 0:
        return 0

    score = 50.0

    # Protein ratio (target ~25-35% of calories from protein)
    prot_ratio = (totals["protein"] * 4) / cal
    if 0.25 <= prot_ratio <= 0.35:
        score += 15
    elif prot_ratio >= 0.15:
        score += 8

    # Fiber bonus (target ~9g per meal = 28g/day / 3)
    if totals["fiber"] >= 9:
        score += 10
    elif totals["fiber"] >= 5:
        score += 5

    # Vegetable presence
    has_veg = any(
        item.get("category") == "Vegetable"
        for layer in meal.get("layers", [])
        for item in layer.get("food_items", [])
    )
    if has_veg:
        score += 10

    # Saturated fat penalty
    if cal > 0 and (totals["sat_fat"] * 9) / cal > 0.10:
        score -= 10

    # Sodium penalty (target < 767mg per meal = 2300/3)
    if totals["sodium"] > 1100:
        score -= 10

    # Sugar penalty
    if totals["sugar"] > 17:  # ~50g/day / 3
        score -= 10

    # Variety bonus
    categories = set(
        item.get("category", "Other")
        for layer in meal.get("layers", [])
        for item in layer.get("food_items", [])
    )
    if len(categories) >= 4:
        score += 10
    elif len(categories) >= 3:
        score += 5

    return max(0, min(100, int(score)))


def format_meal_summary(meal: dict) -> str:
    """Format a single meal into a readable text summary."""
    totals = aggregate_nutrition([meal])
    lines = [
        f"🍽 *{meal['meal_type'].title()}* — {meal['date']} {meal['time']}",
        f"Score: {'⭐' * (meal.get('score', 0) // 20)} {meal.get('score', 0)}/100",
        "",
        f"🔥 {totals['calories']:.0f} kcal  |  "
        f"🥩 {totals['protein']:.0f}g protein  |  "
        f"🍚 {totals['carbs']:.0f}g carbs  |  "
        f"🧈 {totals['fat']:.0f}g fat",
    ]

    if totals["fiber"] > 0:
        lines.append(f"🌾 {totals['fiber']:.0f}g fiber  |  🧂 {totals['sodium']:.0f}mg sodium")

    for layer in meal.get("layers", []):
        lines.append(f"\n📸 *{layer['name']}*:")
        for item in layer.get("food_items", []):
            conf = f" ({item['confidence']*100:.0f}%)" if item.get("confidence", 1) < 1 else ""
            lines.append(
                f"  • {item['name']} — {item['portion_desc'] or f'{item[\"portion_grams\"]:.0f}g'}"
                f" ({item['calories']:.0f} kcal){conf}"
            )

    if meal.get("notes"):
        lines.append(f"\n📝 {meal['notes']}")

    return "\n".join(lines)


def format_today_summary() -> str:
    """Format today's nutrition summary."""
    meals = get_today_meals()
    if not meals:
        return "No meals recorded today yet."

    totals = aggregate_nutrition(meals)
    avg_score = sum(m.get("score", 0) for m in meals) // len(meals) if meals else 0
    remaining = max(0, DAILY_CALORIE_TARGET - totals["calories"])

    lines = [
        "📊 *Today's Summary*",
        f"Meals: {len(meals)}  |  Avg Score: {avg_score}/100",
        "",
        f"🔥 Calories: {totals['calories']:.0f} / {DAILY_CALORIE_TARGET} kcal"
        f" ({remaining:.0f} remaining)",
        f"🥩 Protein: {totals['protein']:.0f}g",
        f"🍚 Carbs: {totals['carbs']:.0f}g",
        f"🧈 Fat: {totals['fat']:.0f}g",
        f"🌾 Fiber: {totals['fiber']:.0f}g",
    ]

    progress = min(totals["calories"] / DAILY_CALORIE_TARGET, 1.0)
    bar_len = 20
    filled = int(bar_len * progress)
    bar = "█" * filled + "░" * (bar_len - filled)
    lines.append(f"\n[{bar}] {progress*100:.0f}%")

    return "\n".join(lines)


def format_period_summary(meals: list[dict], period_label: str) -> str:
    """Format a weekly or monthly summary."""
    if not meals:
        return f"No meals recorded for {period_label}."

    totals = aggregate_nutrition(meals)
    breakdown = daily_breakdown(meals)
    days_with_data = len(breakdown)
    avg_score = sum(m.get("score", 0) for m in meals) // len(meals) if meals else 0

    avg_cal = totals["calories"] / days_with_data if days_with_data else 0
    avg_prot = totals["protein"] / days_with_data if days_with_data else 0

    # Macro split
    total_macro_cal = (totals["protein"] * 4) + (totals["carbs"] * 4) + (totals["fat"] * 9)
    prot_pct = (totals["protein"] * 4 / total_macro_cal * 100) if total_macro_cal else 0
    carb_pct = (totals["carbs"] * 4 / total_macro_cal * 100) if total_macro_cal else 0
    fat_pct = (totals["fat"] * 9 / total_macro_cal * 100) if total_macro_cal else 0

    lines = [
        f"📊 *{period_label} Summary*",
        f"Period: {days_with_data} days with data  |  {len(meals)} total meals",
        f"Avg Score: {'⭐' * (avg_score // 20)} {avg_score}/100",
        "",
        "📈 *Daily Averages:*",
        f"  🔥 Calories: {avg_cal:.0f} kcal (target: {DAILY_CALORIE_TARGET})",
        f"  🥩 Protein: {avg_prot:.0f}g",
        f"  🍚 Carbs: {totals['carbs']/days_with_data:.0f}g" if days_with_data else "",
        f"  🧈 Fat: {totals['fat']/days_with_data:.0f}g" if days_with_data else "",
        "",
        f"⚖️ *Macro Split:* P {prot_pct:.0f}% | C {carb_pct:.0f}% | F {fat_pct:.0f}%",
        "",
        "📅 *Daily Breakdown:*",
    ]

    for d, stats in breakdown.items():
        emoji = "🟢" if stats["avg_score"] >= 70 else "🟡" if stats["avg_score"] >= 50 else "🔴"
        lines.append(
            f"  {emoji} {d}: {stats['calories']:.0f} kcal, "
            f"{stats['protein']:.0f}g P, "
            f"{stats['meal_count']} meals, "
            f"score {stats['avg_score']}"
        )

    return "\n".join(lines)


async def get_llm_advice(period: str = "week") -> str:
    """Get personalized nutrition advice from the LLM based on meal history."""
    if period == "month":
        meals = get_month_meals()
        label = "past 30 days"
    else:
        meals = get_week_meals()
        label = "past 7 days"

    if not meals:
        return f"No meal data for the {label}. Start recording meals to get advice!"

    # Build context for LLM
    summary = format_period_summary(meals, label)
    totals = aggregate_nutrition(meals)
    breakdown = daily_breakdown(meals)

    context = json.dumps({
        "period": label,
        "total_meals": len(meals),
        "days_with_data": len(breakdown),
        "daily_calorie_target": DAILY_CALORIE_TARGET,
        "totals": totals,
        "daily_breakdown": breakdown,
        "meals": [
            {
                "date": m["date"],
                "time": m["time"],
                "type": m["meal_type"],
                "score": m.get("score", 0),
                "foods": [
                    {"name": item["name"], "category": item["category"],
                     "calories": item["calories"], "protein": item["protein"],
                     "carbs": item["carbs"], "fat": item["fat"]}
                    for layer in m.get("layers", [])
                    for item in layer.get("food_items", [])
                ],
            }
            for m in meals
        ],
    }, default=str)

    prompt = f"""Based on the meal data for the {label}, provide personalized nutrition advice.

Include:
1. What the user is doing well (positive reinforcement)
2. Top 3 specific improvements they should make
3. Specific food suggestions to address any nutritional gaps
4. Any patterns you notice (e.g., skipping meals, late eating, repetitive foods)
5. A brief overall assessment

Keep it conversational, practical, and encouraging. Use emojis sparingly.
Format with clear sections using bold headers."""

    return await ask_llm(prompt, context)


async def get_llm_meal_feedback(meal: dict) -> str:
    """Get immediate feedback on a just-recorded meal."""
    summary = format_meal_summary(meal)
    totals = aggregate_nutrition([meal])

    prompt = f"""Give brief, helpful feedback on this meal I just ate:

{summary}

In 2-3 sentences: Is this meal well-balanced? What's good about it? One thing to improve next time?
Keep it encouraging and practical."""

    return await ask_llm(prompt, json.dumps(totals))
