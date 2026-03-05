"""
WebHat renderer - handles rendering comic pages with speech bubbles and effects.
"""

import os
from typing import Optional, Tuple, List
from PIL import Image, ImageDraw, ImageFont
import io

from .models import Page, SpeechBubble, Panel, BubbleStyle, Position, Bounds


class WebHatRenderer:
    """Renders WebHat comic pages."""

    def __init__(self, base_path: str = ""):
        self.base_path = base_path
        self.font_cache: dict = {}
        self.default_font_size = 16

    def render_page(
        self,
        page: Page,
        show_bubbles: bool = True,
        highlight_panel: Optional[str] = None,
        scale: float = 1.0
    ) -> Image.Image:
        """
        Render a complete page with all elements.

        Args:
            page: The page to render
            show_bubbles: Whether to show speech bubbles
            highlight_panel: Panel ID to highlight (optional)
            scale: Scale factor for output

        Returns:
            PIL Image of the rendered page
        """
        # Load base image
        image_path = os.path.join(self.base_path, page.image_path)
        if not os.path.exists(image_path):
            # Create placeholder image
            base_image = Image.new('RGB', (page.width, page.height), '#CCCCCC')
        else:
            base_image = Image.open(image_path).convert('RGBA')

        # Scale if needed
        if scale != 1.0:
            new_size = (
                int(base_image.width * scale),
                int(base_image.height * scale)
            )
            base_image = base_image.resize(new_size, Image.Resampling.LANCZOS)

        # Create drawing layer
        overlay = Image.new('RGBA', base_image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        # Draw panels
        for panel in page.panels:
            self._draw_panel(draw, panel, scale, panel.id == highlight_panel)

        # Draw speech bubbles
        if show_bubbles:
            for panel in page.panels:
                for bubble in panel.speech_bubbles:
                    self._draw_speech_bubble(draw, bubble, scale)

        # Composite layers
        result = Image.alpha_composite(base_image.convert('RGBA'), overlay)
        return result.convert('RGB')

    def render_panel(
        self,
        page: Page,
        panel_id: str,
        show_bubbles: bool = True,
        scale: float = 1.0
    ) -> Optional[Image.Image]:
        """
        Render a single panel from a page.

        Args:
            page: The page containing the panel
            panel_id: ID of the panel to render
            show_bubbles: Whether to show speech bubbles
            scale: Scale factor

        Returns:
            PIL Image of the panel or None if not found
        """
        panel = None
        for p in page.panels:
            if p.id == panel_id:
                panel = p
                break

        if not panel:
            return None

        # Load base image
        image_path = os.path.join(self.base_path, page.image_path)
        if not os.path.exists(image_path):
            return None

        base_image = Image.open(image_path).convert('RGBA')

        # Crop to panel bounds
        bounds = panel.bounds
        cropped = base_image.crop((
            bounds.x, bounds.y,
            bounds.x + bounds.width,
            bounds.y + bounds.height
        ))

        # Scale if needed
        if scale != 1.0:
            new_size = (
                int(cropped.width * scale),
                int(cropped.height * scale)
            )
            cropped = cropped.resize(new_size, Image.Resampling.LANCZOS)

        # Draw bubbles
        if show_bubbles:
            overlay = Image.new('RGBA', cropped.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(overlay)

            for bubble in panel.speech_bubbles:
                # Adjust bubble position relative to panel
                adjusted_bubble = self._adjust_bubble_position(bubble, bounds)
                self._draw_speech_bubble(draw, adjusted_bubble, scale)

            cropped = Image.alpha_composite(cropped, overlay)

        return cropped.convert('RGB')

    def _draw_panel(
        self,
        draw: ImageDraw.Draw,
        panel: Panel,
        scale: float,
        highlight: bool = False
    ):
        """Draw a panel border."""
        bounds = panel.bounds
        x = int(bounds.x * scale)
        y = int(bounds.y * scale)
        width = int(bounds.width * scale)
        height = int(bounds.height * scale)

        # Draw panel border
        border_color = (255, 255, 0, 200) if highlight else (0, 0, 0, 128)
        border_width = 3 if highlight else 1

        draw.rectangle(
            [x, y, x + width, y + height],
            outline=border_color,
            width=border_width
        )

    def _draw_speech_bubble(
        self,
        draw: ImageDraw.Draw,
        bubble: SpeechBubble,
        scale: float
    ):
        """Draw a speech bubble with text."""
        x = int(bubble.position.x * scale)
        y = int(bubble.position.y * scale)
        font_size = int(bubble.font_size * scale)
        max_width = int(bubble.max_width * scale)

        # Get font
        font = self._get_font(font_size)

        # Wrap text
        lines = self._wrap_text(bubble.text, font, max_width)

        # Calculate text dimensions
        line_heights = []
        total_width = 0
        for line in lines:
            bbox = draw.textbbox((0, 0), line, font=font)
            line_height = bbox[3] - bbox[1]
            line_width = bbox[2] - bbox[0]
            line_heights.append(line_height)
            total_width = max(total_width, line_width)

        total_height = sum(line_heights) + (len(lines) - 1) * 4

        # Bubble padding
        padding = int(10 * scale)
        bubble_width = total_width + padding * 2
        bubble_height = total_height + padding * 2

        # Draw bubble background
        bg_color = bubble.background_color or self._get_default_bubble_color(bubble.style)
        rgb_color = self._hex_to_rgb(bg_color)
        rgba_color = (*rgb_color, 230)

        # Draw bubble shape based on style
        if bubble.style == BubbleStyle.THOUGHT:
            self._draw_thought_bubble(
                draw, x, y, bubble_width, bubble_height, rgba_color, scale
            )
        elif bubble.style == BubbleStyle.SHOUT:
            self._draw_shout_bubble(
                draw, x, y, bubble_width, bubble_height, rgba_color, scale
            )
        else:
            self._draw_speech_bubble_shape(
                draw, x, y, bubble_width, bubble_height, rgba_color, scale
            )

        # Draw text
        text_color = self._hex_to_rgb(bubble.color)
        current_y = y + padding
        for i, line in enumerate(lines):
            draw.text((x + padding, current_y), line, font=font, fill=text_color)
            current_y += line_heights[i] + 4

    def _draw_speech_bubble_shape(
        self,
        draw: ImageDraw.Draw,
        x: int,
        y: int,
        width: int,
        height: int,
        color: Tuple[int, int, int, int],
        scale: float
    ):
        """Draw standard speech bubble with tail."""
        # Main bubble
        draw.rounded_rectangle(
            [x, y, x + width, y + height],
            radius=int(10 * scale),
            fill=color,
            outline=(0, 0, 0, 200),
            width=int(2 * scale)
        )

        # Tail
        tail_size = int(15 * scale)
        tail_points = [
            (x + width // 2, y + height),
            (x + width // 2 - tail_size, y + height + tail_size),
            (x + width // 2 + tail_size, y + height + tail_size),
        ]
        draw.polygon(tail_points, fill=color, outline=(0, 0, 0, 200))

    def _draw_thought_bubble(
        self,
        draw: ImageDraw.Draw,
        x: int,
        y: int,
        width: int,
        height: int,
        color: Tuple[int, int, int, int],
        scale: float
    ):
        """Draw thought bubble with bubbles."""
        # Main bubble
        draw.ellipse(
            [x, y, x + width, y + height],
            fill=color,
            outline=(0, 0, 0, 200),
            width=int(2 * scale)
        )

        # Thought bubbles
        bubble_sizes = [int(12 * scale), int(8 * scale), int(5 * scale)]
        bubble_y = y + height
        for size in bubble_sizes:
            bubble_x = x + width // 2 - size // 2
            draw.ellipse(
                [bubble_x, bubble_y, bubble_x + size, bubble_y + size],
                fill=color,
                outline=(0, 0, 0, 200),
                width=1
            )
            bubble_y += size + int(3 * scale)

    def _draw_shout_bubble(
        self,
        draw: ImageDraw.Draw,
        x: int,
        y: int,
        width: int,
        height: int,
        color: Tuple[int, int, int, int],
        scale: float
    ):
        """Draw shout bubble with jagged edges."""
        # Create jagged polygon
        points = []
        num_points = 16
        cx = x + width // 2
        cy = y + height // 2
        rx = width // 2
        ry = height // 2

        for i in range(num_points):
            angle = (2 * 3.14159 * i) / num_points
            # Alternate between inner and outer radius for jagged effect
            r = rx if i % 2 == 0 else rx * 0.85
            px = cx + r * (rx / ry if rx > ry else 1) * (1 if i < num_points // 2 or i > num_points * 3 // 4 else -1)
            py = cy + ry * (ry / rx if ry > rx else 1) * (1 if i < num_points // 2 else -1)
            points.append((px, py))

        draw.polygon(points, fill=color, outline=(0, 0, 0, 200))

    def _wrap_text(self, text: str, font: ImageFont.FreeTypeFont, max_width: int) -> List[str]:
        """Wrap text to fit within max_width."""
        words = text.split()
        lines = []
        current_line = []

        for word in words:
            test_line = ' '.join(current_line + [word])
            # Use a simple approximation for text width
            test_width = len(test_line) * font.size * 0.6

            if test_width <= max_width:
                current_line.append(word)
            else:
                if current_line:
                    lines.append(' '.join(current_line))
                current_line = [word]

        if current_line:
            lines.append(' '.join(current_line))

        return lines if lines else [text]

    def _get_font(self, size: int) -> ImageFont.FreeTypeFont:
        """Get cached font or create new one."""
        if size not in self.font_cache:
            try:
                # Try to load a system font
                self.font_cache[size] = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
            except:
                try:
                    self.font_cache[size] = ImageFont.truetype("arial.ttf", size)
                except:
                    self.font_cache[size] = ImageFont.load_default()
        return self.font_cache[size]

    def _get_default_bubble_color(self, style: BubbleStyle) -> str:
        """Get default background color for bubble style."""
        colors = {
            BubbleStyle.SPEECH: "#FFFFFF",
            BubbleStyle.THOUGHT: "#F0F0F0",
            BubbleStyle.NARRATION: "#FFF8DC",
            BubbleStyle.SHOUT: "#FFE4E1",
            BubbleStyle.WHISPER: "#E6E6FA",
        }
        return colors.get(style, "#FFFFFF")

    def _hex_to_rgb(self, hex_color: str) -> Tuple[int, int, int]:
        """Convert hex color to RGB tuple."""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

    def _adjust_bubble_position(self, bubble: SpeechBubble, panel_bounds: Bounds) -> SpeechBubble:
        """Adjust bubble position relative to panel."""
        from copy import copy
        adjusted = copy(bubble)
        adjusted.position = Position(
            x=bubble.position.x - panel_bounds.x,
            y=bubble.position.y - panel_bounds.y
        )
        return adjusted

    def render_to_bytes(
        self,
        page: Page,
        format: str = "PNG",
        **kwargs
    ) -> bytes:
        """Render page to bytes."""
        image = self.render_page(page, **kwargs)
        buffer = io.BytesIO()
        image.save(buffer, format=format)
        return buffer.getvalue()
