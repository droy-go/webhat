#!/usr/bin/env python3
"""
WebHat Category Icon Generator

Generates category icons for the WebHat StoryPack platform.
Categories: action, horror, fantasy, scifi, comedy, education, kids
"""

import os
import argparse
from PIL import Image, ImageDraw, ImageFont
from typing import Tuple, Optional


# Category definitions with colors and symbols
CATEGORIES = {
    "action": {
        "color": "#E74C3C",  # Red
        "bg_color": "#2C1A1A",
        "symbol": "⚔️",
        "text": "ACTION",
        "gradient": [(231, 76, 60), (192, 57, 43)],
    },
    "horror": {
        "color": "#8E44AD",  # Purple
        "bg_color": "#1A1A2E",
        "symbol": "🦇",
        "text": "HORROR",
        "gradient": [(142, 68, 173), (108, 52, 131)],
    },
    "fantasy": {
        "color": "#3498DB",  # Blue
        "bg_color": "#1A2A3A",
        "symbol": "🐉",
        "text": "FANTASY",
        "gradient": [(52, 152, 219), (41, 128, 185)],
    },
    "scifi": {
        "color": "#00BCD4",  # Cyan
        "bg_color": "#0A1A2A",
        "symbol": "🚀",
        "text": "SCI-FI",
        "gradient": [(0, 188, 212), (0, 150, 170)],
    },
    "comedy": {
        "color": "#F1C40F",  # Yellow
        "bg_color": "#2A2A1A",
        "symbol": "😄",
        "text": "COMEDY",
        "gradient": [(241, 196, 15), (211, 172, 13)],
    },
    "education": {
        "color": "#27AE60",  # Green
        "bg_color": "#1A2A1A",
        "symbol": "📚",
        "text": "EDUCATION",
        "gradient": [(39, 174, 96), (30, 132, 73)],
    },
    "kids": {
        "color": "#FF6B9D",  # Pink
        "bg_color": "#2A1A2A",
        "symbol": "🧸",
        "text": "KIDS",
        "gradient": [(255, 107, 157), (220, 80, 130)],
    },
}


def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def create_gradient_background(
    size: Tuple[int, int],
    color1: Tuple[int, int, int],
    color2: Tuple[int, int, int],
) -> Image.Image:
    """Create a vertical gradient background."""
    image = Image.new("RGB", size)
    draw = ImageDraw.Draw(image)

    for y in range(size[1]):
        ratio = y / size[1]
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (size[0], y)], fill=(r, g, b))

    return image


def add_glow_effect(
    image: Image.Image,
    color: Tuple[int, int, int],
    radius: int = 20,
) -> Image.Image:
    """Add a glow effect around the image edges."""
    # Create a larger image for the glow
    glow_size = (image.width + radius * 2, image.height + radius * 2)
    glow = Image.new("RGBA", glow_size, (0, 0, 0, 0))

    # Paste the original image in the center
    glow.paste(image, (radius, radius), image if image.mode == "RGBA" else None)

    # Apply blur for glow effect (simplified)
    return glow


def draw_rounded_rectangle(
    draw: ImageDraw.Draw,
    bbox: Tuple[int, int, int, int],
    radius: int,
    fill: Optional[Tuple[int, int, int]] = None,
    outline: Optional[Tuple[int, int, int]] = None,
    width: int = 1,
) -> None:
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = bbox

    # Draw main rectangle
    if fill:
        draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
        draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)

    # Draw corners
    if fill:
        draw.ellipse([x1, y1, x1 + radius * 2, y1 + radius * 2], fill=fill)
        draw.ellipse([x2 - radius * 2, y1, x2, y1 + radius * 2], fill=fill)
        draw.ellipse([x1, y2 - radius * 2, x1 + radius * 2, y2], fill=fill)
        draw.ellipse([x2 - radius * 2, y2 - radius * 2, x2, y2], fill=fill)

    if outline:
        # Draw outline arcs
        draw.arc([x1, y1, x1 + radius * 2, y1 + radius * 2], 180, 270, fill=outline, width=width)
        draw.arc([x2 - radius * 2, y1, x2, y1 + radius * 2], 270, 360, fill=outline, width=width)
        draw.arc([x1, y2 - radius * 2, x1 + radius * 2, y2], 90, 180, fill=outline, width=width)
        draw.arc([x2 - radius * 2, y2 - radius * 2, x2, y2], 0, 90, fill=outline, width=width)

        # Draw outline lines
        draw.line([x1 + radius, y1, x2 - radius, y1], fill=outline, width=width)
        draw.line([x1 + radius, y2, x2 - radius, y2], fill=outline, width=width)
        draw.line([x1, y1 + radius, x1, y2 - radius], fill=outline, width=width)
        draw.line([x2, y1 + radius, x2, y2 - radius], fill=outline, width=width)


def generate_icon(
    category: str,
    size: Tuple[int, int] = (512, 512),
    output_dir: str = "icons",
) -> str:
    """
    Generate an icon for a category.

    Args:
        category: Category name (action, horror, fantasy, scifi, comedy, education, kids)
        size: Output image size (width, height)
        output_dir: Directory to save the icon

    Returns:
        Path to the generated icon
    """
    if category not in CATEGORIES:
        raise ValueError(f"Unknown category: {category}. Available: {list(CATEGORIES.keys())}")

    cat_info = CATEGORIES[category]
    os.makedirs(output_dir, exist_ok=True)

    # Create base image with gradient
    image = create_gradient_background(size, cat_info["gradient"][0], cat_info["gradient"][1])
    draw = ImageDraw.Draw(image)

    # Add decorative elements
    center_x, center_y = size[0] // 2, size[1] // 2

    # Draw outer ring
    ring_margin = 40
    draw.ellipse(
        [ring_margin, ring_margin, size[0] - ring_margin, size[1] - ring_margin],
        outline=(255, 255, 255, 128),
        width=4,
    )

    # Draw inner circle background
    circle_margin = 80
    draw.ellipse(
        [circle_margin, circle_margin, size[0] - circle_margin, size[1] - circle_margin],
        fill=(0, 0, 0, 100),
    )

    # Try to load a font, fallback to default
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 120)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 48)
    except:
        try:
            font_large = ImageFont.truetype("arial.ttf", 120)
            font_small = ImageFont.truetype("arial.ttf", 48)
        except:
            font_large = ImageFont.load_default()
            font_small = font_large

    # Draw symbol (emoji)
    symbol = cat_info["symbol"]
    bbox = draw.textbbox((0, 0), symbol, font=font_large)
    symbol_width = bbox[2] - bbox[0]
    symbol_height = bbox[3] - bbox[1]
    symbol_x = center_x - symbol_width // 2
    symbol_y = center_y - symbol_height // 2 - 40
    draw.text((symbol_x, symbol_y), symbol, font=font_large, fill=(255, 255, 255))

    # Draw category text
    text = cat_info["text"]
    bbox = draw.textbbox((0, 0), text, font=font_small)
    text_width = bbox[2] - bbox[0]
    text_x = center_x - text_width // 2
    text_y = size[1] - 100
    draw.text((text_x, text_y), text, font=font_small, fill=(255, 255, 255))

    # Save the icon
    output_path = os.path.join(output_dir, f"{category}.png")
    image.save(output_path, "PNG")

    return output_path


def generate_all_icons(
    size: Tuple[int, int] = (512, 512),
    output_dir: str = "icons",
) -> list:
    """Generate icons for all categories."""
    generated = []
    for category in CATEGORIES.keys():
        path = generate_icon(category, size, output_dir)
        generated.append(path)
        print(f"Generated: {path}")
    return generated


def generate_favicon(output_dir: str = "icons") -> str:
    """Generate a favicon for the WebHat platform."""
    os.makedirs(output_dir, exist_ok=True)

    size = (256, 256)
    image = Image.new("RGB", size, (99, 102, 241))  # Primary color
    draw = ImageDraw.Draw(image)

    # Try to load font
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 160)
    except:
        font = ImageFont.load_default()

    # Draw "W" letter
    text = "W"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (size[0] - text_width) // 2
    y = (size[1] - text_height) // 2 - 10

    draw.text((x, y), text, font=font, fill=(255, 255, 255))

    # Save favicon
    favicon_path = os.path.join(output_dir, "favicon.png")
    image.save(favicon_path, "PNG")

    # Also save as ICO
    ico_path = os.path.join(output_dir, "favicon.ico")
    image.save(ico_path, "ICO")

    return favicon_path


def main():
    parser = argparse.ArgumentParser(
        description="Generate category icons for WebHat StoryPack"
    )
    parser.add_argument(
        "--category",
        "-c",
        choices=list(CATEGORIES.keys()) + ["all"],
        default="all",
        help="Category to generate icon for (default: all)",
    )
    parser.add_argument(
        "--size",
        "-s",
        type=int,
        nargs=2,
        default=[512, 512],
        metavar=("WIDTH", "HEIGHT"),
        help="Icon size (default: 512 512)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="icons",
        help="Output directory (default: icons)",
    )
    parser.add_argument(
        "--favicon",
        "-f",
        action="store_true",
        help="Also generate favicon",
    )

    args = parser.parse_args()

    if args.category == "all":
        print("Generating all category icons...")
        generated = generate_all_icons(tuple(args.size), args.output)
        print(f"\nGenerated {len(generated)} icons in '{args.output}'")
    else:
        path = generate_icon(args.category, tuple(args.size), args.output)
        print(f"Generated: {path}")

    if args.favicon:
        favicon_path = generate_favicon(args.output)
        print(f"Generated favicon: {favicon_path}")


if __name__ == "__main__":
    main()
