"""
WebHat file loader - handles loading and parsing .webhat files.
"""

import json
import zipfile
import tempfile
import os
from pathlib import Path
from typing import Optional, Dict, Any
import shutil

from .models import (
    WebHatStory, Manifest, Chapter, Page, Panel, SpeechBubble,
    Character, AudioTrack, AudioConfig, Transition, Interaction,
    ChoiceOption, Hotspot, Position, Bounds, BubbleStyle,
    TransitionType, InteractionType
)


class WebHatLoader:
    """Loads and parses .webhat files."""

    def __init__(self):
        self.temp_dir: Optional[str] = None
        self.extracted_path: Optional[str] = None

    def load(self, file_path: str) -> WebHatStory:
        """
        Load a .webhat file and return a WebHatStory object.

        Args:
            file_path: Path to the .webhat file

        Returns:
            WebHatStory object

        Raises:
            FileNotFoundError: If file doesn't exist
            ValueError: If file is invalid
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"WebHat file not found: {file_path}")

        # Create temp directory for extraction
        self.temp_dir = tempfile.mkdtemp(prefix="webhat_")
        self.extracted_path = os.path.join(self.temp_dir, "extracted")
        os.makedirs(self.extracted_path)

        try:
            # Extract ZIP file
            with zipfile.ZipFile(file_path, 'r') as zip_ref:
                zip_ref.extractall(self.extracted_path)

            # Load manifest
            manifest = self._load_manifest()

            # Load story
            story = self._load_story(manifest)

            return story

        except Exception as e:
            self.cleanup()
            raise ValueError(f"Failed to load WebHat file: {e}") from e

    def _load_manifest(self) -> Manifest:
        """Load manifest.json file."""
        manifest_path = os.path.join(self.extracted_path, "manifest.json")

        if not os.path.exists(manifest_path):
            raise ValueError("manifest.json not found in WebHat package")

        with open(manifest_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        return Manifest(
            format_version=data.get("format_version", "1.0.0"),
            id=data.get("id", ""),
            title=data.get("title", "Untitled"),
            author=data.get("author", "Unknown"),
            version=data.get("version", "1.0.0"),
            description=data.get("description"),
            created_at=data.get("created_at"),
            updated_at=data.get("updated_at"),
            categories=data.get("categories", []),
            tags=data.get("tags", []),
            language=data.get("language", "en"),
            rating=data.get("rating", "everyone"),
            pages_count=data.get("pages_count", 0),
            has_audio=data.get("has_audio", False),
            has_interactions=data.get("has_interactions", False),
            cover_image=data.get("cover_image"),
            thumbnail=data.get("thumbnail"),
        )

    def _load_story(self, manifest: Manifest) -> WebHatStory:
        """Load story.json file."""
        story_path = os.path.join(self.extracted_path, "story.json")

        if not os.path.exists(story_path):
            raise ValueError("story.json not found in WebHat package")

        with open(story_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        story = WebHatStory(manifest=manifest)

        # Load chapters
        if "chapters" in data:
            for chapter_data in data["chapters"]:
                chapter = self._parse_chapter(chapter_data)
                story.chapters[chapter.id] = chapter

        # Load pages
        if "pages" in data:
            for page_id, page_data in data["pages"].items():
                page = self._parse_page(page_id, page_data)
                story.pages[page_id] = page

        # Load characters
        if "characters" in data:
            for char_id, char_data in data["characters"].items():
                character = self._parse_character(char_id, char_data)
                story.characters[char_id] = character

        # Load audio tracks
        if "audio_tracks" in data:
            for track_id, track_data in data["audio_tracks"].items():
                track = self._parse_audio_track(track_id, track_data)
                story.audio_tracks[track_id] = track

        # Load variables
        if "variables" in data:
            story.variables = data["variables"]

        return story

    def _parse_chapter(self, data: Dict[str, Any]) -> Chapter:
        """Parse chapter data."""
        return Chapter(
            id=data.get("id", ""),
            title=data.get("title", "Untitled Chapter"),
            pages=data.get("pages", []),
            description=data.get("description"),
        )

    def _parse_page(self, page_id: str, data: Dict[str, Any]) -> Page:
        """Parse page data."""
        # Parse panels
        panels = []
        for panel_data in data.get("panels", []):
            panel = self._parse_panel(panel_data)
            panels.append(panel)

        # Parse audio config
        audio_data = data.get("audio", {})
        audio = AudioConfig(
            bgm=audio_data.get("bgm"),
            bgm_loop=audio_data.get("bgm_loop", True),
            bgm_volume=audio_data.get("bgm_volume", 0.7),
            sfx=audio_data.get("sfx", []),
            voice=audio_data.get("voice"),
        )

        # Parse transition
        transition_data = data.get("transitions", {})
        transition = Transition(
            in_type=TransitionType(transition_data.get("in", "fade")),
            out_type=TransitionType(transition_data.get("out", "fade")),
            duration=transition_data.get("duration", 500),
        )

        # Parse interactions
        interactions = []
        for interaction_data in data.get("interactions", []):
            interaction = self._parse_interaction(interaction_data)
            interactions.append(interaction)

        return Page(
            id=page_id,
            chapter_id=data.get("chapter_id", ""),
            image_path=data.get("image", ""),
            width=data.get("width", 1920),
            height=data.get("height", 1080),
            panels=panels,
            audio=audio,
            transition=transition,
            interactions=interactions,
            next_page=data.get("next_page"),
            prev_page=data.get("prev_page"),
        )

    def _parse_panel(self, data: Dict[str, Any]) -> Panel:
        """Parse panel data."""
        bounds_data = data.get("bounds", {})
        bounds = Bounds(
            x=bounds_data.get("x", 0),
            y=bounds_data.get("y", 0),
            width=bounds_data.get("width", 100),
            height=bounds_data.get("height", 100),
        )

        # Parse speech bubbles
        bubbles = []
        for bubble_data in data.get("speech_bubbles", []):
            bubble = self._parse_speech_bubble(bubble_data)
            bubbles.append(bubble)

        # Parse hotspots
        hotspots = []
        for hotspot_data in data.get("hotspots", []):
            hotspot = self._parse_hotspot(hotspot_data)
            hotspots.append(hotspot)

        return Panel(
            id=data.get("id", ""),
            bounds=bounds,
            speech_bubbles=bubbles,
            hotspots=hotspots,
        )

    def _parse_speech_bubble(self, data: Dict[str, Any]) -> SpeechBubble:
        """Parse speech bubble data."""
        pos_data = data.get("position", {})
        position = Position(x=pos_data.get("x", 0), y=pos_data.get("y", 0))

        style_str = data.get("style", "speech")
        try:
            style = BubbleStyle(style_str)
        except ValueError:
            style = BubbleStyle.SPEECH

        return SpeechBubble(
            id=data.get("id", ""),
            text=data.get("text", ""),
            character=data.get("character"),
            position=position,
            style=style,
            font_size=data.get("font_size", 16),
            color=data.get("color", "#000000"),
            background_color=data.get("background_color"),
            max_width=data.get("max_width", 300),
        )

    def _parse_hotspot(self, data: Dict[str, Any]) -> Hotspot:
        """Parse hotspot data."""
        bounds_data = data.get("bounds", {})
        bounds = Bounds(
            x=bounds_data.get("x", 0),
            y=bounds_data.get("y", 0),
            width=bounds_data.get("width", 100),
            height=bounds_data.get("height", 100),
        )

        return Hotspot(
            id=data.get("id", ""),
            bounds=bounds,
            action=data.get("action", ""),
            target=data.get("target"),
            tooltip=data.get("tooltip"),
        )

    def _parse_interaction(self, data: Dict[str, Any]) -> Interaction:
        """Parse interaction data."""
        trigger_data = data.get("trigger", {})
        trigger = Bounds(
            x=trigger_data.get("x", 0),
            y=trigger_data.get("y", 0),
            width=trigger_data.get("width", 100),
            height=trigger_data.get("height", 100),
        )

        type_str = data.get("type", "hotspot")
        try:
            interaction_type = InteractionType(type_str)
        except ValueError:
            interaction_type = InteractionType.HOTSPOT

        # Parse choice options
        options = []
        for option_data in data.get("options", []):
            option = ChoiceOption(
                text=option_data.get("text", ""),
                target=option_data.get("target", ""),
                condition=option_data.get("condition"),
            )
            options.append(option)

        return Interaction(
            id=data.get("id", ""),
            type=interaction_type,
            trigger=trigger,
            options=options,
            action=data.get("action"),
            delay=data.get("delay", 0),
        )

    def _parse_character(self, char_id: str, data: Dict[str, Any]) -> Character:
        """Parse character data."""
        return Character(
            id=char_id,
            name=data.get("name", char_id),
            color=data.get("color", "#000000"),
            avatar_path=data.get("avatar"),
        )

    def _parse_audio_track(self, track_id: str, data: Dict[str, Any]) -> AudioTrack:
        """Parse audio track data."""
        return AudioTrack(
            id=track_id,
            file_path=data.get("file", ""),
            loop=data.get("loop", False),
            volume=data.get("volume", 1.0),
        )

    def get_file_path(self, relative_path: str) -> str:
        """Get absolute path to a file in the extracted package."""
        if not self.extracted_path:
            raise RuntimeError("No WebHat file loaded")
        return os.path.join(self.extracted_path, relative_path)

    def file_exists(self, relative_path: str) -> bool:
        """Check if a file exists in the package."""
        return os.path.exists(self.get_file_path(relative_path))

    def cleanup(self):
        """Clean up temporary files."""
        if self.temp_dir and os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
            self.temp_dir = None
            self.extracted_path = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.cleanup()
