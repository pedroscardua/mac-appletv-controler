#!/usr/bin/env python3
"""Generate app icon for Apple TV Remote using Pillow."""

import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ICONSET_DIR = Path("Resources/icon.iconset")


def create_icon(size):
    """Create a single icon image at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = size * 0.12
    w = size - 2 * margin
    h = size - 2 * margin
    x0, y0 = margin, margin
    x1, y1 = margin + w, margin + h

    # Rounded rectangle background (dark, like Apple TV remote)
    radius = size * 0.22
    # Main body
    draw.rounded_rectangle(
        [x0, y0, x1, y1],
        radius=radius,
        fill=(30, 30, 30, 255),
    )

    # Inner touch surface (slightly lighter)
    inner_margin = size * 0.22
    inner_radius = size * 0.16
    draw.rounded_rectangle(
        [
            x0 + inner_margin,
            y0 + inner_margin * 0.8,
            x1 - inner_margin,
            y1 - inner_margin * 1.6,
        ],
        radius=inner_radius,
        fill=(55, 55, 55, 255),
        outline=(80, 80, 80, 255),
        width=max(1, size // 128),
    )

    # D-pad cross lines
    cx = size / 2
    cy = size * 0.48
    dpad_size = w * 0.28
    line_w = max(2, size // 64)

    # Vertical line
    draw.rounded_rectangle(
        [cx - dpad_size * 0.18, cy - dpad_size * 0.65, cx + dpad_size * 0.18, cy + dpad_size * 0.65],
        radius=line_w // 2,
        fill=(130, 130, 130, 200),
    )
    # Horizontal line
    draw.rounded_rectangle(
        [cx - dpad_size * 0.65, cy - dpad_size * 0.18, cx + dpad_size * 0.65, cy + dpad_size * 0.18],
        radius=line_w // 2,
        fill=(130, 130, 130, 200),
    )

    # Center circle
    circle_r = dpad_size * 0.2
    draw.ellipse(
        [cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r],
        fill=(180, 180, 180, 255),
    )

    # Bottom buttons
    button_area_top = y1 - inner_margin * 1.4
    btn_y = button_area_top + (y1 - button_area_top) * 0.5
    btn_r = size * 0.05

    # Three dots at bottom
    for bx in [cx - w * 0.12, cx, cx + w * 0.12]:
        draw.ellipse(
            [bx - btn_r * 0.6, btn_y - btn_r * 0.6, bx + btn_r * 0.6, btn_y + btn_r * 0.6],
            fill=(140, 140, 140, 200),
        )

    # Top bar (like the Siri Remote)
    top_bar_h = size * 0.04
    draw.rounded_rectangle(
        [x0 + inner_margin, y0 + inner_margin * 0.3, x1 - inner_margin, y0 + inner_margin * 0.3 + top_bar_h],
        radius=top_bar_h // 2,
        fill=(80, 80, 80, 200),
    )

    return img


def generate_iconset():
    """Generate all icon sizes for macOS .icns."""
    ICONSET_DIR.mkdir(parents=True, exist_ok=True)

    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    for filename, size in sizes.items():
        icon = create_icon(size)
        path = ICONSET_DIR / filename
        icon.save(path, "PNG")
        print(f"  {filename} ({size}x{size})")

    # Use iconutil to create .icns
    icns_path = Path("Resources/AppleTVRemote.icns")
    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET_DIR), "-o", str(icns_path)],
        check=True,
    )
    print(f"\nCreated: {icns_path}")

    # Clean up iconset (optional)
    import shutil
    shutil.rmtree(ICONSET_DIR)
    print("Cleaned up iconset")


if __name__ == "__main__":
    os.chdir(Path(__file__).parent.parent)
    generate_iconset()
