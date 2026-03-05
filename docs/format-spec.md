# WebHat Format Specification

## Overview

WebHat (.webhat) is a ZIP-based package format for interactive digital comics and stories.

## File Structure

```
story.webhat (ZIP archive)
├── manifest.json          # Required - Package metadata
├── story.json             # Required - Story definition
├── pages/                 # Required - Page images
│   ├── page_001.png
│   ├── page_002.png
│   └── ...
├── audio/                 # Optional - Audio files
│   ├── bgm_track1.mp3
│   ├── sfx_click.mp3
│   └── ...
├── icons/                 # Optional - Story icons
│   ├── cover.png
│   └── thumbnail.png
└── scripts/               # Optional - Interactive scripts
    └── interactions.json
```

## manifest.json

Contains package metadata and version information.

```json
{
  "format_version": "1.0.0",
  "id": "com.author.storyname",
  "title": "Story Title",
  "description": "A brief description of the story",
  "author": "Author Name",
  "version": "1.0.0",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "categories": ["fantasy", "action"],
  "tags": ["magic", "adventure"],
  "language": "en",
  "rating": "everyone",
  "pages_count": 24,
  "has_audio": true,
  "has_interactions": true,
  "cover_image": "icons/cover.png",
  "thumbnail": "icons/thumbnail.png"
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| format_version | string | Yes | WebHat format version |
| id | string | Yes | Unique identifier (reverse domain) |
| title | string | Yes | Story title |
| description | string | No | Brief description |
| author | string | Yes | Author name |
| version | string | Yes | Story version |
| created_at | string | No | ISO 8601 creation date |
| updated_at | string | No | ISO 8601 update date |
| categories | array | No | Story categories |
| tags | array | No | Search tags |
| language | string | No | ISO 639-1 language code |
| rating | string | No | Content rating |
| pages_count | integer | Yes | Number of pages |
| has_audio | boolean | No | Contains audio files |
| has_interactions | boolean | No | Has interactive elements |
| cover_image | string | No | Path to cover image |
| thumbnail | string | No | Path to thumbnail |

## story.json

Defines the story structure, pages, and events.

```json
{
  "title": "Story Title",
  "chapters": [
    {
      "id": "chapter_1",
      "title": "Chapter 1: The Beginning",
      "pages": ["page_001", "page_002", "page_003"]
    }
  ],
  "pages": {
    "page_001": {
      "id": "page_001",
      "chapter_id": "chapter_1",
      "image": "pages/page_001.png",
      "width": 1920,
      "height": 1080,
      "panels": [
        {
          "id": "panel_1",
          "bounds": {"x": 0, "y": 0, "width": 960, "height": 540},
          "speech_bubbles": [
            {
              "id": "bubble_1",
              "text": "Hello, world!",
              "character": "Hero",
              "position": {"x": 100, "y": 100},
              "style": "speech"
            }
          ]
        }
      ],
      "audio": {
        "bgm": "audio/bgm_calm.mp3",
        "sfx": ["audio/sfx_wind.mp3"]
      },
      "transitions": {
        "in": "fade",
        "out": "slide_left"
      },
      "interactions": [
        {
          "type": "choice",
          "trigger": {"x": 500, "y": 500, "width": 200, "height": 50},
          "options": [
            {"text": "Go left", "target": "page_002"},
            {"text": "Go right", "target": "page_003"}
          ]
        }
      ]
    }
  },
  "characters": {
    "hero": {
      "id": "hero",
      "name": "Hero",
      "color": "#FF5733",
      "avatar": "icons/hero_avatar.png"
    }
  },
  "audio_tracks": {
    "bgm_calm": {
      "id": "bgm_calm",
      "file": "audio/bgm_calm.mp3",
      "loop": true,
      "volume": 0.7
    }
  }
}
```

### Page Object

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique page identifier |
| chapter_id | string | Parent chapter ID |
| image | string | Path to page image |
| width | integer | Image width in pixels |
| height | integer | Image height in pixels |
| panels | array | Panel definitions |
| audio | object | Audio configuration |
| transitions | object | Page transitions |
| interactions | array | Interactive elements |

### Panel Object

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique panel identifier |
| bounds | object | Panel position and size |
| speech_bubbles | array | Speech/text bubbles |
| hotspots | array | Clickable areas |

### Speech Bubble Object

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique bubble identifier |
| text | string | Display text |
| character | string | Character ID |
| position | object | X, Y coordinates |
| style | string | "speech", "thought", "narration" |

### Interaction Object

| Field | Type | Description |
|-------|------|-------------|
| type | string | "choice", "hotspot", "timer" |
| trigger | object | Activation area or condition |
| action | object | Action to perform |

## Supported Image Formats

- PNG (recommended for quality)
- JPEG (for photos)
- WebP (for smaller sizes)

## Supported Audio Formats

- MP3 (recommended for compatibility)
- OGG (for open source)
- WAV (for short effects)

## Content Ratings

- `everyone` - Suitable for all ages
- `teen` - Ages 13+
- `mature` - Ages 17+
- `adult` - Ages 18+

## Version History

### 1.0.0 (Current)
- Initial specification
- Basic page/speech/interaction support
- Audio support
