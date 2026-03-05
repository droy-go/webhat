# WebHat Engine API Documentation

## Overview

The WebHat Engine is a Python library for loading, rendering, and interacting with .webhat comic files.

## Installation

```bash
cd engine
pip install -e .
```

## Quick Start

```python
from webhat_engine import WebHatLoader, WebHatRenderer

# Load a .webhat file
with WebHatLoader() as loader:
    story = loader.load("path/to/story.webhat")

    # Access story information
    print(f"Title: {story.manifest.title}")
    print(f"Author: {story.manifest.author}")
    print(f"Pages: {story.manifest.pages_count}")

    # Render a page
    renderer = WebHatRenderer(loader.extracted_path)
    page = story.get_page("page_001")
    image = renderer.render_page(page)
    image.save("output.png")
```

## Core Classes

### WebHatLoader

Handles loading and parsing .webhat files.

```python
loader = WebHatLoader()
story = loader.load("story.webhat")

# Get file path within package
image_path = loader.get_file_path("pages/page_001.png")

# Check if file exists
exists = loader.file_exists("audio/bgm.mp3")

# Cleanup when done
loader.cleanup()
```

**Context Manager Support:**
```python
with WebHatLoader() as loader:
    story = loader.load("story.webhat")
    # Automatic cleanup on exit
```

### WebHatRenderer

Renders comic pages with speech bubbles and effects.

```python
renderer = WebHatRenderer(base_path)

# Render full page
image = renderer.render_page(
    page,
    show_bubbles=True,
    highlight_panel=None,
    scale=1.0
)

# Render single panel
panel_image = renderer.render_panel(
    page,
    panel_id="panel_1",
    show_bubbles=True,
    scale=1.0
)

# Render to bytes
image_bytes = renderer.render_to_bytes(
    page,
    format="PNG",
    show_bubbles=True
)
```

### AudioPlayer

Plays audio for stories.

```python
player = AudioPlayer(base_path)

# Play background music
player.play_bgm("audio/background.mp3", loop=True, volume=0.7)

# Play sound effect
player.play_sfx("audio/click.mp3", volume=1.0)

# Control playback
player.pause_bgm()
player.resume_bgm()
player.stop_bgm()
player.set_bgm_volume(0.5)

# Fade effects
player.fade_out_bgm(duration_ms=1000)
player.fade_in_bgm("audio/new_bgm.mp3", duration_ms=1000)

# Cleanup
player.cleanup()
```

**Context Manager Support:**
```python
with AudioPlayer(base_path) as player:
    player.play_bgm("audio/bgm.mp3")
    # Automatic cleanup on exit
```

### EventManager

Handles story events and interactions.

```python
manager = EventManager(story)

# Listen for events
def on_page_change(event):
    print(f"Page changed from {event.data['from']} to {event.data['to']}")

manager.add_listener(EventType.PAGE_CHANGE, on_page_change)

# Navigate
manager.execute_action("goto_page", page_id="page_002")

# Evaluate conditions
result = manager.evaluate_condition("$variable == 'value'")

# Make choices
manager.make_choice(choice_option, interaction_id="choice_1")

# Save/Load state
manager.save_state("save.json")
manager.load_state("save.json")
```

## Data Models

### Manifest

```python
@dataclass
class Manifest:
    format_version: str      # "1.0.0"
    id: str                  # Unique identifier
    title: str               # Story title
    description: Optional[str]
    author: str
    version: str
    created_at: Optional[str]
    updated_at: Optional[str]
    categories: List[str]
    tags: List[str]
    language: str            # ISO 639-1 code
    rating: str              # "everyone", "teen", "mature", "adult"
    pages_count: int
    has_audio: bool
    has_interactions: bool
    cover_image: Optional[str]
    thumbnail: Optional[str]
```

### Page

```python
@dataclass
class Page:
    id: str
    chapter_id: str
    image_path: str
    width: int
    height: int
    panels: List[Panel]
    audio: AudioConfig
    transition: Transition
    interactions: List[Interaction]
    next_page: Optional[str]
    prev_page: Optional[str]
```

### SpeechBubble

```python
@dataclass
class SpeechBubble:
    id: str
    text: str
    character: Optional[str]
    position: Position      # x, y coordinates
    style: BubbleStyle      # SPEECH, THOUGHT, NARRATION, SHOUT, WHISPER
    font_size: int
    color: str              # Hex color
    background_color: Optional[str]
    max_width: int
```

## CLI Usage

```bash
# Show story information
webhat-engine info story.webhat

# Render pages
webhat-engine render story.webhat -o output/ --scale 1.5

# Validate file
webhat-engine validate story.webhat

# Extract contents
webhat-engine extract story.webhat -o extracted/
```

## Advanced Usage

### Custom Event Handlers

```python
from webhat_engine import EventManager, EventType

manager = EventManager(story)

# Custom condition handler
def check_achievement(condition):
    return game_state.has_achievement(condition)

manager.register_condition_handler("has_achievement", check_achievement)

# Custom action handler
def unlock_achievement(**params):
    game_state.unlock(params["achievement_id"])

manager.register_action_handler("unlock_achievement", unlock_achievement)
```

### Audio Preloading

```python
from webhat_engine.player import AudioPreloader

preloader = AudioPreloader(base_path)

# Preload specific files
preloader.preload("audio/bgm.mp3")
preloader.preload("audio/sfx_click.mp3")

# Preload all audio for a page
preloader.preload_page_audio(page)

# Get cached audio
cached = preloader.get_cached("audio/bgm.mp3")

# Clear cache
preloader.clear_cache()
```

### Story Navigation

```python
# Get first page
first_page = story.get_first_page()

# Navigate through pages
next_page = story.get_next_page(current_page_id)
prev_page = story.get_prev_page(current_page_id)

# Get by ID
page = story.get_page("page_001")
chapter = story.get_chapter("chapter_1")
character = story.get_character("hero")
```

## Error Handling

```python
from webhat_engine import WebHatLoader

try:
    with WebHatLoader() as loader:
        story = loader.load("story.webhat")
except FileNotFoundError:
    print("File not found")
except ValueError as e:
    print(f"Invalid WebHat file: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

## Type Hints

All public APIs include type hints for better IDE support:

```python
from webhat_engine import WebHatLoader, WebHatStory

loader: WebHatLoader = WebHatLoader()
story: WebHatStory = loader.load("story.webhat")
```
