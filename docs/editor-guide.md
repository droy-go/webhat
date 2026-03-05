# WebHat Editor Guide

## Overview

The WebHat Editor is a visual tool for creating and editing .webhat comic files. It supports both web and desktop versions.

## Getting Started

### Web Editor

1. Open the WebHat Editor in your browser
2. Click "New Project" to start a new comic
3. Or click "Open" to load an existing .webhat file

### Desktop Editor (Flutter)

1. Launch the WebHat StoryPack app
2. Select "Create New" from the home screen
3. Enter your story title and author name

## Interface

### Main Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Header: [New] [Open] [Save] [Export]         Project Name  │
├──────────┬──────────────────────────────┬───────────────────┤
│          │                              │                   │
│ Chapters │                              │   Properties      │
│          │        Canvas Area           │   Panel           │
│  List    │        (Page Viewer)         │                   │
│          │                              │   Story Info      │
├──────────┤                              │   Audio Settings  │
│          │                              │                   │
│ Pages    │                              │                   │
│ Grid     │                              │                   │
│          │                              │                   │
└──────────┴──────────────────────────────┴───────────────────┘
```

## Creating a Story

### 1. Project Setup

1. Enter story title
2. Enter author name
3. Add description
4. Select categories and tags
5. Choose content rating

### 2. Creating Chapters

1. Click "+ Add Chapter" in the left sidebar
2. Enter chapter title
3. Optionally add a description

### 3. Adding Pages

1. Select a chapter
2. Click "+ Add Page"
3. Select an image file (PNG, JPG, WebP)
4. The page will be added to the chapter

## Editing Pages

### Canvas Tools

| Tool | Icon | Description |
|------|------|-------------|
| Select | ↖ | Select and move elements |
| Panel | □ | Add panel boundaries |
| Bubble | 💬 | Add speech bubbles |
| Hotspot | ⌖ | Add interactive hotspots |

### Adding Panels

1. Select the Panel tool
2. Click and drag on the canvas to draw a panel
3. Panels define areas for speech bubbles

### Adding Speech Bubbles

1. Select the Bubble tool
2. Click inside a panel to place a bubble
3. Double-click the bubble to edit text
4. Set style: Speech, Thought, Narration, Shout, Whisper

#### Bubble Properties

- **Text**: The spoken text
- **Character**: Who is speaking (optional)
- **Style**: Visual style of the bubble
- **Position**: X, Y coordinates
- **Font Size**: Text size
- **Color**: Text color
- **Background**: Bubble background color

### Adding Interactions

1. Select the Hotspot tool
2. Draw a hotspot area on the canvas
3. Configure the interaction:
   - Type: Choice, Hotspot, Timer
   - Action: What happens when triggered
   - Target: Destination page

## Audio

### Background Music

1. Select a page
2. In the Properties panel, click "Choose File" for BGM
3. Select an audio file (MP3, OGG)
4. Set volume and loop options

### Sound Effects

1. Add SFX files to the page
2. They will play when the page loads

### Voice Acting

1. Add voice files for narration
2. Link to specific speech bubbles (optional)

## Exporting

### Export as .webhat

1. Click "Export .webhat" button
2. The file will be downloaded
3. This is the final format for distribution

### Save Project

1. Click "Save" to save locally
2. Creates a JSON file with project data
3. Does not include image/audio files

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+N | New project |
| Ctrl+O | Open file |
| Ctrl+S | Save |
| Ctrl+E | Export |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Delete | Delete selected element |
| Space | Pan canvas |
| Ctrl++ | Zoom in |
| Ctrl+- | Zoom out |
| Ctrl+0 | Reset zoom |

## Tips and Tricks

### Organization

- Use descriptive chapter names
- Number your pages consistently
- Group related pages in the same chapter

### Design

- Keep speech bubbles readable
- Use contrasting colors for text
- Test on different screen sizes

### Performance

- Optimize images before importing
- Use WebP for smaller file sizes
- Compress audio files

### Collaboration

- Export .webhat for sharing
- Use version control for story.json
- Document your variable usage

## Troubleshooting

### Images not showing

- Check file format (PNG, JPG, WebP)
- Verify file is not corrupted
- Try re-importing the image

### Audio not playing

- Ensure file format is supported
- Check volume settings
- Verify file path in story.json

### Export fails

- Check all files are valid
- Ensure sufficient disk space
- Try exporting to a different location

## Advanced Features

### Custom Scripts

Add custom behavior through the scripting panel:

```json
{
  "on_page_load": "play_sfx('audio/wind.mp3')",
  "on_page_exit": "fade_out_bgm()"
}
```

### Variables

Track story state:

1. Open Variables panel
2. Add new variable
3. Use in conditions for branching

### Transitions

Set page transition effects:

- Fade
- Slide (left, right, up, down)
- Zoom (in, out)
- None (instant)

## Mobile Editing

The Flutter app supports editing on:
- Android tablets
- iPad
- Touch-enabled laptops

### Touch Gestures

- Pinch to zoom
- Two-finger pan
- Tap to select
- Long press for context menu
