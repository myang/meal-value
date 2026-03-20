import sqlite3
import json
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional
from contextlib import contextmanager

from config import DB_PATH


@contextmanager
def get_db():
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db():
    """Create database tables if they don't exist."""
    with get_db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS meals (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                meal_type   TEXT NOT NULL DEFAULT 'meal',
                date        TEXT NOT NULL,
                time        TEXT NOT NULL,
                notes       TEXT DEFAULT '',
                score       INTEGER DEFAULT 0,
                created_at  TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS layers (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                meal_id     INTEGER NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
                name        TEXT NOT NULL DEFAULT 'Layer',
                order_idx   INTEGER NOT NULL DEFAULT 0,
                photo_path  TEXT DEFAULT '',
                ai_raw      TEXT DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS food_items (
                id              INTEGER PRIMARY KEY AUTOINCREMENT,
                layer_id        INTEGER NOT NULL REFERENCES layers(id) ON DELETE CASCADE,
                name            TEXT NOT NULL,
                category        TEXT NOT NULL DEFAULT 'Other',
                portion_grams   REAL NOT NULL DEFAULT 100,
                portion_desc    TEXT DEFAULT '',
                confidence      REAL DEFAULT 1.0,
                calories        REAL DEFAULT 0,
                protein         REAL DEFAULT 0,
                carbs           REAL DEFAULT 0,
                fat             REAL DEFAULT 0,
                fiber           REAL DEFAULT 0,
                sugar           REAL DEFAULT 0,
                sodium          REAL DEFAULT 0,
                cholesterol     REAL DEFAULT 0,
                sat_fat         REAL DEFAULT 0
            );

            CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
            CREATE INDEX IF NOT EXISTS idx_layers_meal ON layers(meal_id);
            CREATE INDEX IF NOT EXISTS idx_food_items_layer ON food_items(layer_id);
        """)


# --- Meal CRUD ---

def create_meal(meal_type: str = "meal", notes: str = "") -> int:
    """Create a new meal record. Returns meal ID."""
    now = datetime.now()
    with get_db() as conn:
        cur = conn.execute(
            "INSERT INTO meals (meal_type, date, time, notes) VALUES (?, ?, ?, ?)",
            (meal_type, now.strftime("%Y-%m-%d"), now.strftime("%H:%M"), notes),
        )
        return cur.lastrowid


def add_layer(meal_id: int, name: str, photo_path: str = "", ai_raw: str = "") -> int:
    """Add a layer to a meal. Returns layer ID."""
    with get_db() as conn:
        # Get next order index
        row = conn.execute(
            "SELECT COALESCE(MAX(order_idx), -1) + 1 AS next_idx FROM layers WHERE meal_id = ?",
            (meal_id,),
        ).fetchone()
        order_idx = row["next_idx"]
        cur = conn.execute(
            "INSERT INTO layers (meal_id, name, order_idx, photo_path, ai_raw) VALUES (?, ?, ?, ?, ?)",
            (meal_id, name, order_idx, photo_path, ai_raw),
        )
        return cur.lastrowid


def add_food_item(layer_id: int, **kwargs) -> int:
    """Add a food item to a layer. Returns item ID."""
    cols = [
        "name", "category", "portion_grams", "portion_desc", "confidence",
        "calories", "protein", "carbs", "fat", "fiber", "sugar",
        "sodium", "cholesterol", "sat_fat",
    ]
    values = {c: kwargs.get(c, 0) for c in cols}
    values["name"] = kwargs.get("name", "Unknown")
    values["category"] = kwargs.get("category", "Other")
    values["portion_desc"] = kwargs.get("portion_desc", "")
    values["confidence"] = kwargs.get("confidence", 1.0)

    placeholders = ", ".join(f":{c}" for c in cols)
    col_names = ", ".join(cols)

    with get_db() as conn:
        cur = conn.execute(
            f"INSERT INTO food_items (layer_id, {col_names}) VALUES (:layer_id, {placeholders})",
            {"layer_id": layer_id, **values},
        )
        return cur.lastrowid


def update_meal_score(meal_id: int, score: int):
    with get_db() as conn:
        conn.execute("UPDATE meals SET score = ? WHERE id = ?", (score, meal_id))


# --- Query helpers ---

def get_meal(meal_id: int) -> Optional[dict]:
    """Get a full meal with layers and food items."""
    with get_db() as conn:
        meal = conn.execute("SELECT * FROM meals WHERE id = ?", (meal_id,)).fetchone()
        if not meal:
            return None

        meal = dict(meal)
        layers = conn.execute(
            "SELECT * FROM layers WHERE meal_id = ? ORDER BY order_idx", (meal_id,)
        ).fetchall()

        meal["layers"] = []
        for layer in layers:
            layer = dict(layer)
            items = conn.execute(
                "SELECT * FROM food_items WHERE layer_id = ?", (layer["id"],)
            ).fetchall()
            layer["food_items"] = [dict(item) for item in items]
            meal["layers"].append(layer)

        return meal


def get_meals_in_range(start_date: str, end_date: str) -> list[dict]:
    """Get all meals between start_date and end_date (inclusive, YYYY-MM-DD)."""
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM meals WHERE date >= ? AND date <= ? ORDER BY date, time",
            (start_date, end_date),
        ).fetchall()

    return [get_meal(row["id"]) for row in rows]


def get_today_meals() -> list[dict]:
    today = date.today().isoformat()
    return get_meals_in_range(today, today)


def get_week_meals() -> list[dict]:
    today = date.today()
    start = (today - timedelta(days=6)).isoformat()
    return get_meals_in_range(start, today.isoformat())


def get_month_meals() -> list[dict]:
    today = date.today()
    start = (today - timedelta(days=29)).isoformat()
    return get_meals_in_range(start, today.isoformat())


def get_all_meals() -> list[dict]:
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM meals ORDER BY date DESC, time DESC").fetchall()
    return [get_meal(row["id"]) for row in rows]


def delete_meal(meal_id: int):
    with get_db() as conn:
        conn.execute("DELETE FROM meals WHERE id = ?", (meal_id,))


# --- Aggregation helpers ---

def aggregate_nutrition(meals: list[dict]) -> dict:
    """Sum up nutrition across all meals."""
    totals = {
        "calories": 0, "protein": 0, "carbs": 0, "fat": 0,
        "fiber": 0, "sugar": 0, "sodium": 0, "cholesterol": 0, "sat_fat": 0,
    }
    for meal in meals:
        for layer in meal.get("layers", []):
            for item in layer.get("food_items", []):
                for key in totals:
                    totals[key] += item.get(key, 0)
    return totals


def daily_breakdown(meals: list[dict]) -> dict[str, dict]:
    """Group meals by date and return per-day nutrition totals."""
    by_date: dict[str, list[dict]] = {}
    for meal in meals:
        d = meal["date"]
        by_date.setdefault(d, []).append(meal)

    result = {}
    for d, day_meals in sorted(by_date.items()):
        totals = aggregate_nutrition(day_meals)
        totals["meal_count"] = len(day_meals)
        totals["avg_score"] = (
            sum(m.get("score", 0) for m in day_meals) // len(day_meals)
            if day_meals else 0
        )
        result[d] = totals
    return result


def export_all_as_json() -> str:
    """Export entire database as JSON string."""
    meals = get_all_meals()
    return json.dumps(meals, indent=2, default=str)
