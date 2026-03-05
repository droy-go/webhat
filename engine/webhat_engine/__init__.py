"""
WebHat Engine - Python library for loading and rendering .webhat files.
"""

__version__ = "1.0.0"

from .loader import WebHatLoader
from .renderer import WebHatRenderer
from .player import AudioPlayer
from .events import EventManager
from .models import WebHatStory, Page, Panel, SpeechBubble

__all__ = [
    "WebHatLoader",
    "WebHatRenderer",
    "AudioPlayer",
    "EventManager",
    "WebHatStory",
    "Page",
    "Panel",
    "SpeechBubble",
]
