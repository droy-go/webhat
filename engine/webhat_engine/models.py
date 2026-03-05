"""
Data models for WebHat stories.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from enum import Enum


class BubbleStyle(Enum):
    SPEECH = "speech"
    THOUGHT = "thought"
    NARRATION = "narration"
    SHOUT = "shout"
    WHISPER = "whisper"


class TransitionType(Enum):
    FADE = "fade"
    SLIDE_LEFT = "slide_left"
    SLIDE_RIGHT = "slide_right"
    SLIDE_UP = "slide_up"
    SLIDE_DOWN = "slide_down"
    ZOOM_IN = "zoom_in"
    ZOOM_OUT = "zoom_out"
    NONE = "none"


class InteractionType(Enum):
    CHOICE = "choice"
    HOTSPOT = "hotspot"
    TIMER = "timer"
    SWIPE = "swipe"


@dataclass
class Position:
    x: int
    y: int


@dataclass
class Size:
    width: int
    height: int


@dataclass
class Bounds:
    x: int
    y: int
    width: int
    height: int

    def contains(self, point: Position) -> bool:
        return (
            self.x <= point.x <= self.x + self.width
            and self.y <= point.y <= self.y + self.height
        )


@dataclass
class SpeechBubble:
    id: str
    text: str
    character: Optional[str] = None
    position: Position = field(default_factory=lambda: Position(0, 0))
    style: BubbleStyle = BubbleStyle.SPEECH
    font_size: int = 16
    color: str = "#000000"
    background_color: Optional[str] = None
    max_width: int = 300


@dataclass
class Panel:
    id: str
    bounds: Bounds
    speech_bubbles: List[SpeechBubble] = field(default_factory=list)
    hotspots: List['Hotspot'] = field(default_factory=list)


@dataclass
class Hotspot:
    id: str
    bounds: Bounds
    action: str
    target: Optional[str] = None
    tooltip: Optional[str] = None


@dataclass
class ChoiceOption:
    text: str
    target: str
    condition: Optional[str] = None


@dataclass
class Interaction:
    id: str
    type: InteractionType
    trigger: Bounds
    options: List[ChoiceOption] = field(default_factory=list)
    action: Optional[str] = None
    delay: int = 0  # milliseconds for timer


@dataclass
class AudioConfig:
    bgm: Optional[str] = None
    bgm_loop: bool = True
    bgm_volume: float = 0.7
    sfx: List[str] = field(default_factory=list)
    voice: Optional[str] = None


@dataclass
class Transition:
    in_type: TransitionType = TransitionType.FADE
    out_type: TransitionType = TransitionType.FADE
    duration: int = 500  # milliseconds


@dataclass
class Page:
    id: str
    chapter_id: str
    image_path: str
    width: int
    height: int
    panels: List[Panel] = field(default_factory=list)
    audio: AudioConfig = field(default_factory=AudioConfig)
    transition: Transition = field(default_factory=Transition)
    interactions: List[Interaction] = field(default_factory=list)
    next_page: Optional[str] = None
    prev_page: Optional[str] = None


@dataclass
class Chapter:
    id: str
    title: str
    pages: List[str] = field(default_factory=list)
    description: Optional[str] = None


@dataclass
class Character:
    id: str
    name: str
    color: str = "#000000"
    avatar_path: Optional[str] = None


@dataclass
class AudioTrack:
    id: str
    file_path: str
    loop: bool = False
    volume: float = 1.0


@dataclass
class Manifest:
    format_version: str
    id: str
    title: str
    author: str
    version: str
    description: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    categories: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    language: str = "en"
    rating: str = "everyone"
    pages_count: int = 0
    has_audio: bool = False
    has_interactions: bool = False
    cover_image: Optional[str] = None
    thumbnail: Optional[str] = None


@dataclass
class WebHatStory:
    manifest: Manifest
    chapters: Dict[str, Chapter] = field(default_factory=dict)
    pages: Dict[str, Page] = field(default_factory=dict)
    characters: Dict[str, Character] = field(default_factory=dict)
    audio_tracks: Dict[str, AudioTrack] = field(default_factory=dict)
    variables: Dict[str, Any] = field(default_factory=dict)

    def get_page(self, page_id: str) -> Optional[Page]:
        return self.pages.get(page_id)

    def get_chapter(self, chapter_id: str) -> Optional[Chapter]:
        return self.chapters.get(chapter_id)

    def get_character(self, character_id: str) -> Optional[Character]:
        return self.characters.get(character_id)

    def get_first_page(self) -> Optional[Page]:
        for chapter in self.chapters.values():
            if chapter.pages:
                return self.pages.get(chapter.pages[0])
        return None

    def get_next_page(self, current_page_id: str) -> Optional[Page]:
        page = self.pages.get(current_page_id)
        if page and page.next_page:
            return self.pages.get(page.next_page)
        return None

    def get_prev_page(self, current_page_id: str) -> Optional[Page]:
        page = self.pages.get(current_page_id)
        if page and page.prev_page:
            return self.pages.get(page.prev_page)
        return None
