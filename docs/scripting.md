# WebHat Scripting Reference

## Overview

WebHat supports interactive storytelling through scripting. Scripts allow you to:
- Create branching narratives
- Track player choices
- Control audio playback
- Manage story state

## Story Variables

Variables are stored in the story state and persist throughout the reading session.

### Setting Variables

```json
{
  "interactions": [
    {
      "type": "hotspot",
      "trigger": {"x": 100, "y": 100, "width": 50, "height": 50},
      "action": "set_variable",
      "params": {
        "name": "found_key",
        "value": true
      }
    }
  ]
}
```

### Using Variables in Conditions

```json
{
  "interactions": [
    {
      "type": "choice",
      "trigger": {"x": 200, "y": 200, "width": 100, "height": 50},
      "options": [
        {
          "text": "Open the door",
          "target": "page_unlocked",
          "condition": "$found_key == true"
        },
        {
          "text": "The door is locked",
          "target": "page_locked",
          "condition": "$found_key != true"
        }
      ]
    }
  ]
}
```

## Condition Syntax

### Comparison Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `==` | Equal | `$health == 100` |
| `!=` | Not equal | `$class != 'warrior'` |
| `>` | Greater than | `$score > 500` |
| `<` | Less than | `$level < 10` |
| `>=` | Greater or equal | `$gold >= 100` |
| `<=` | Less or equal | `$lives <= 3` |

### Logical Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `AND` | Both conditions | `$has_sword AND $has_shield` |
| `OR` | Either condition | `$is_wizard OR $is_mage` |
| `NOT` | Negation | `NOT $is_defeated` |

### Complex Conditions

```
($strength >= 15 AND $has_weapon) OR $is_berserk
```

## Built-in Actions

### Navigation Actions

#### `goto_page`
Navigate to a specific page.

```json
{
  "action": "goto_page",
  "params": {
    "page_id": "page_005"
  }
}
```

#### `goto_chapter`
Navigate to the first page of a chapter.

```json
{
  "action": "goto_chapter",
  "params": {
    "chapter_id": "chapter_2"
  }
}
```

### Variable Actions

#### `set_variable`
Set a variable value.

```json
{
  "action": "set_variable",
  "params": {
    "name": "player_name",
    "value": "Hero"
  }
}
```

#### `increment`
Increment a numeric variable.

```json
{
  "action": "increment",
  "params": {
    "name": "score",
    "amount": 100
  }
}
```

#### `decrement`
Decrement a numeric variable.

```json
{
  "action": "decrement",
  "params": {
    "name": "lives",
    "amount": 1
  }
}
```

### Audio Actions

#### `play_audio`
Play an audio track.

```json
{
  "action": "play_audio",
  "params": {
    "track": "audio/bgm_battle.mp3",
    "loop": true,
    "volume": 0.8
  }
}
```

#### `stop_audio`
Stop audio playback.

```json
{
  "action": "stop_audio"
}
```

#### `play_sfx`
Play a sound effect.

```json
{
  "action": "play_sfx",
  "params": {
    "track": "audio/sfx_explosion.mp3",
    "volume": 1.0
  }
}
```

## Interaction Types

### Hotspot

Clickable area that triggers an action.

```json
{
  "id": "hotspot_1",
  "type": "hotspot",
  "trigger": {
    "x": 100,
    "y": 100,
    "width": 200,
    "height": 150
  },
  "action": "goto_page",
  "params": {
    "page_id": "page_002"
  }
}
```

### Choice

Multiple choice dialog.

```json
{
  "id": "choice_1",
  "type": "choice",
  "trigger": {
    "x": 300,
    "y": 400,
    "width": 250,
    "height": 100
  },
  "options": [
    {
      "text": "Fight the dragon",
      "target": "page_battle",
      "condition": "$has_sword == true"
    },
    {
      "text": "Run away",
      "target": "page_escape"
    },
    {
      "text": "Try to negotiate",
      "target": "page_talk",
      "condition": "$charisma >= 12"
    }
  ]
}
```

### Timer

Automatic action after delay.

```json
{
  "id": "timer_1",
  "type": "timer",
  "delay": 5000,
  "action": "goto_page",
  "params": {
    "page_id": "page_timeout"
  }
}
```

### Swipe

Swipe gesture detection (mobile).

```json
{
  "id": "swipe_1",
  "type": "swipe",
  "direction": "left",
  "action": "goto_page",
  "params": {
    "page_id": "page_next"
  }
}
```

## Complete Example

```json
{
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
          "bounds": {"x": 0, "y": 0, "width": 960, "height": 1080},
          "speech_bubbles": [
            {
              "id": "bubble_1",
              "text": "You stand before a mysterious door...",
              "position": {"x": 100, "y": 100},
              "style": "narration"
            }
          ]
        }
      ],
      "interactions": [
        {
          "id": "examine_door",
          "type": "hotspot",
          "trigger": {"x": 400, "y": 300, "width": 200, "height": 400},
          "action": "set_variable",
          "params": {
            "name": "examined_door",
            "value": true
          }
        },
        {
          "id": "door_choice",
          "type": "choice",
          "trigger": {"x": 350, "y": 750, "width": 300, "height": 100},
          "options": [
            {
              "text": "Open the door",
              "target": "page_room",
              "condition": "$has_key == true"
            },
            {
              "text": "The door is locked. You need a key.",
              "target": "page_001",
              "condition": "$has_key != true AND $examined_door == true"
            },
            {
              "text": "Look around first",
              "target": "page_001"
            }
          ]
        }
      ],
      "audio": {
        "bgm": "audio/mystery.mp3",
        "bgm_loop": true,
        "bgm_volume": 0.6
      }
    }
  },
  "variables": {
    "has_key": false,
    "examined_door": false,
    "player_health": 100
  }
}
```

## Best Practices

1. **Use descriptive IDs** for interactions and variables
2. **Set default values** for all variables in story.json
3. **Test all branches** of conditional choices
4. **Keep conditions simple** - break complex logic into multiple steps
5. **Use comments** in your JSON (via `_comment` fields)

## Debugging

Enable debug mode in the reader to see:
- Variable values
- Interaction triggers
- Condition evaluations
