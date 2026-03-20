import shutil
from datetime import datetime
from pathlib import Path

from config import PHOTO_DIR


def save_photo(photo_bytes: bytes, meal_id: int, layer_name: str) -> str:
    """Save a photo to the organized directory structure.

    Structure: ~/MealData/photos/YYYY/MM/DD/meal{id}_{layer}_{timestamp}.jpg
    Returns the relative path from PHOTO_DIR.
    """
    now = datetime.now()
    day_dir = PHOTO_DIR / now.strftime("%Y") / now.strftime("%m") / now.strftime("%d")
    day_dir.mkdir(parents=True, exist_ok=True)

    safe_layer = layer_name.replace(" ", "_").replace("/", "-")[:30]
    filename = f"meal{meal_id}_{safe_layer}_{now.strftime('%H%M%S')}.jpg"
    filepath = day_dir / filename

    filepath.write_bytes(photo_bytes)

    # Return path relative to PHOTO_DIR for DB storage
    return str(filepath.relative_to(PHOTO_DIR))


def get_photo_path(relative_path: str) -> Path:
    """Get the full filesystem path for a stored photo."""
    return PHOTO_DIR / relative_path


def get_photo_bytes(relative_path: str) -> bytes | None:
    """Read photo bytes from storage."""
    path = get_photo_path(relative_path)
    if path.exists():
        return path.read_bytes()
    return None


def get_all_photos_for_meal(meal_id: int, layers: list[dict]) -> list[Path]:
    """Get all photo paths for a meal's layers."""
    paths = []
    for layer in layers:
        if layer.get("photo_path"):
            p = get_photo_path(layer["photo_path"])
            if p.exists():
                paths.append(p)
    return paths


def get_storage_stats() -> dict:
    """Get storage usage statistics."""
    total_size = 0
    total_files = 0
    for f in PHOTO_DIR.rglob("*.jpg"):
        total_size += f.stat().st_size
        total_files += 1

    return {
        "total_photos": total_files,
        "total_size_mb": round(total_size / (1024 * 1024), 1),
        "storage_path": str(PHOTO_DIR),
    }
