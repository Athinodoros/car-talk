#!/usr/bin/env python3
"""
Generate app icon PNGs for Car Post All.

Creates two 1024x1024 PNG files:
  - app_icon.png           — Full icon with blue circle background, white car+envelope design
  - app_icon_foreground.png — Same design on transparent background (Android adaptive icon foreground)

Requirements: Pillow (pip install Pillow)

Usage:
    python scripts/generate_icon.py
"""

import math
import os
from PIL import Image, ImageDraw

ICON_SIZE = 1024
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "mobile", "assets", "icon")

# Material Blue 500
BG_COLOR = (33, 150, 243)       # #2196F3
WHITE = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def draw_icon_content(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw the car + envelope design centered in the canvas.

    The design is a stylized car silhouette viewed from behind with a small
    envelope/message badge, conveying 'car messaging'.
    """
    cx, cy = size // 2, size // 2

    # --- Car body (rear view silhouette) ---
    # The car is drawn as a simplified rear-view shape: roof, body, wheels.

    # Scale factor — keep artwork within inner 66% for adaptive icon safe zone
    s = size * 0.30  # half-width of car body

    # Roof (trapezoid)
    roof_top_y = cy - s * 0.95
    roof_bot_y = cy - s * 0.40
    roof_top_half = s * 0.55
    roof_bot_half = s * 0.85

    roof = [
        (cx - roof_top_half, roof_top_y),
        (cx + roof_top_half, roof_top_y),
        (cx + roof_bot_half, roof_bot_y),
        (cx - roof_bot_half, roof_bot_y),
    ]
    draw.polygon(roof, fill=WHITE)

    # Window inside roof (dark cutout — use a slightly darker shade for contrast)
    win_inset = s * 0.10
    win_top_y = roof_top_y + win_inset * 1.5
    win_bot_y = roof_bot_y - win_inset * 0.8
    # Interpolate widths at the window edges
    t_top = (win_top_y - roof_top_y) / (roof_bot_y - roof_top_y)
    t_bot = (win_bot_y - roof_top_y) / (roof_bot_y - roof_top_y)
    win_top_half = roof_top_half + t_top * (roof_bot_half - roof_top_half) - win_inset
    win_bot_half = roof_top_half + t_bot * (roof_bot_half - roof_top_half) - win_inset

    window = [
        (cx - win_top_half, win_top_y),
        (cx + win_top_half, win_top_y),
        (cx + win_bot_half, win_bot_y),
        (cx - win_bot_half, win_bot_y),
    ]
    draw.polygon(window, fill=BG_COLOR)

    # Body (rounded rectangle from below roof to bottom)
    body_top_y = roof_bot_y - s * 0.05
    body_bot_y = cy + s * 0.55
    body_half = s * 0.95
    body_radius = s * 0.12

    draw.rounded_rectangle(
        [cx - body_half, body_top_y, cx + body_half, body_bot_y],
        radius=int(body_radius),
        fill=WHITE,
    )

    # Tail lights (two small red-ish rectangles near top of body)
    light_w = s * 0.18
    light_h = s * 0.10
    light_y = body_top_y + s * 0.12
    light_inset = s * 0.15
    # Left tail light
    draw.rounded_rectangle(
        [cx - body_half + light_inset, light_y,
         cx - body_half + light_inset + light_w, light_y + light_h],
        radius=int(s * 0.03),
        fill=(244, 67, 54),  # Material Red
    )
    # Right tail light
    draw.rounded_rectangle(
        [cx + body_half - light_inset - light_w, light_y,
         cx + body_half - light_inset, light_y + light_h],
        radius=int(s * 0.03),
        fill=(244, 67, 54),
    )

    # License plate area (small white rectangle with darker outline in center of body)
    plate_w = s * 0.50
    plate_h = s * 0.16
    plate_y = body_bot_y - s * 0.30
    draw.rounded_rectangle(
        [cx - plate_w / 2, plate_y, cx + plate_w / 2, plate_y + plate_h],
        radius=int(s * 0.04),
        fill=WHITE,
        outline=BG_COLOR,
        width=max(2, int(s * 0.02)),
    )

    # Wheels (two dark circles at bottom corners)
    wheel_r = s * 0.18
    wheel_y = body_bot_y + wheel_r * 0.30
    wheel_offset = body_half - s * 0.20
    draw.ellipse(
        [cx - wheel_offset - wheel_r, wheel_y - wheel_r,
         cx - wheel_offset + wheel_r, wheel_y + wheel_r],
        fill=(66, 66, 66),
    )
    draw.ellipse(
        [cx + wheel_offset - wheel_r, wheel_y - wheel_r,
         cx + wheel_offset + wheel_r, wheel_y + wheel_r],
        fill=(66, 66, 66),
    )
    # Wheel hubcaps
    hub_r = wheel_r * 0.45
    draw.ellipse(
        [cx - wheel_offset - hub_r, wheel_y - hub_r,
         cx - wheel_offset + hub_r, wheel_y + hub_r],
        fill=(180, 180, 180),
    )
    draw.ellipse(
        [cx + wheel_offset - hub_r, wheel_y - hub_r,
         cx + wheel_offset + hub_r, wheel_y + hub_r],
        fill=(180, 180, 180),
    )

    # --- Envelope / Message badge (bottom-right) ---
    badge_cx = cx + s * 0.70
    badge_cy = cy + s * 0.65
    badge_r = s * 0.38

    # Badge circle background (white with slight shadow)
    draw.ellipse(
        [badge_cx - badge_r - 2, badge_cy - badge_r - 2,
         badge_cx + badge_r + 2, badge_cy + badge_r + 2],
        fill=(200, 200, 200),  # subtle shadow
    )
    draw.ellipse(
        [badge_cx - badge_r, badge_cy - badge_r,
         badge_cx + badge_r, badge_cy + badge_r],
        fill=WHITE,
    )

    # Envelope inside badge
    env_w = badge_r * 1.20
    env_h = badge_r * 0.85
    env_left = badge_cx - env_w / 2
    env_top = badge_cy - env_h / 2
    env_right = badge_cx + env_w / 2
    env_bot = badge_cy + env_h / 2
    line_w = max(2, int(s * 0.025))

    # Envelope body
    draw.rounded_rectangle(
        [env_left, env_top, env_right, env_bot],
        radius=int(badge_r * 0.08),
        fill=BG_COLOR,
    )

    # Envelope flap (V shape)
    draw.line(
        [(env_left, env_top), (badge_cx, badge_cy + env_h * 0.05), (env_right, env_top)],
        fill=WHITE,
        width=line_w,
    )


def generate_app_icon() -> None:
    """Generate app_icon.png — blue circle background with design."""
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Blue circle background (fills most of the canvas)
    margin = ICON_SIZE * 0.02
    draw.ellipse(
        [margin, margin, ICON_SIZE - margin, ICON_SIZE - margin],
        fill=BG_COLOR,
    )

    draw_icon_content(draw, ICON_SIZE)

    # Convert to RGB (no transparency) for the main icon
    bg = Image.new("RGB", (ICON_SIZE, ICON_SIZE), WHITE)
    bg.paste(img, mask=img.split()[3])

    path = os.path.join(OUTPUT_DIR, "app_icon.png")
    bg.save(path, "PNG")
    print(f"Created {path}")


def generate_foreground() -> None:
    """Generate app_icon_foreground.png — transparent background with design."""
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # Blue circle (slightly smaller to fit in adaptive icon safe zone)
    margin = ICON_SIZE * 0.10
    draw.ellipse(
        [margin, margin, ICON_SIZE - margin, ICON_SIZE - margin],
        fill=BG_COLOR,
    )

    draw_icon_content(draw, ICON_SIZE)

    path = os.path.join(OUTPUT_DIR, "app_icon_foreground.png")
    img.save(path, "PNG")
    print(f"Created {path}")


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    generate_app_icon()
    generate_foreground()
    print("\nDone! Now run: cd mobile && dart run flutter_launcher_icons")
