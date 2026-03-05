"""
Event manager for WebHat stories - handles interactions and story progression.
"""

import json
from typing import Dict, List, Callable, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
import re


class EventType(Enum):
    PAGE_CHANGE = "page_change"
    CHAPTER_CHANGE = "chapter_change"
    CHOICE_MADE = "choice_made"
    HOTSPOT_CLICKED = "hotspot_clicked"
    AUDIO_STARTED = "audio_started"
    AUDIO_ENDED = "audio_ended"
    VARIABLE_SET = "variable_set"
    ANIMATION_COMPLETE = "animation_complete"
    TIMER_EXPIRED = "timer_expired"
    STORY_END = "story_end"


@dataclass
class StoryEvent:
    type: EventType
    data: Dict[str, Any] = field(default_factory=dict)
    timestamp: float = field(default_factory=lambda: __import__('time').time())


@dataclass
class StoryState:
    """Tracks the current state of story progression."""
    current_page_id: Optional[str] = None
    current_chapter_id: Optional[str] = None
    visited_pages: List[str] = field(default_factory=list)
    variables: Dict[str, Any] = field(default_factory=dict)
    choices_made: Dict[str, str] = field(default_factory=dict)
    history: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "current_page_id": self.current_page_id,
            "current_chapter_id": self.current_chapter_id,
            "visited_pages": self.visited_pages,
            "variables": self.variables,
            "choices_made": self.choices_made,
            "history": self.history,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'StoryState':
        return cls(
            current_page_id=data.get("current_page_id"),
            current_chapter_id=data.get("current_chapter_id"),
            visited_pages=data.get("visited_pages", []),
            variables=data.get("variables", {}),
            choices_made=data.get("choices_made", {}),
            history=data.get("history", []),
        )


class EventManager:
    """Manages story events and interactions."""

    def __init__(self, story=None):
        self.story = story
        self.state = StoryState()
        self._listeners: Dict[EventType, List[Callable]] = {
            event_type: [] for event_type in EventType
        }
        self._global_listeners: List[Callable] = []
        self._condition_handlers: Dict[str, Callable] = {}
        self._action_handlers: Dict[str, Callable] = {}

        # Register default handlers
        self._register_default_handlers()

    def _register_default_handlers(self):
        """Register default action handlers."""
        self.register_action_handler("goto_page", self._action_goto_page)
        self.register_action_handler("goto_chapter", self._action_goto_chapter)
        self.register_action_handler("set_variable", self._action_set_variable)
        self.register_action_handler("play_audio", self._action_play_audio)
        self.register_action_handler("stop_audio", self._action_stop_audio)

    def add_listener(self, event_type: EventType, callback: Callable):
        """Add an event listener for a specific event type."""
        if event_type not in self._listeners:
            self._listeners[event_type] = []
        self._listeners[event_type].append(callback)

    def remove_listener(self, event_type: EventType, callback: Callable):
        """Remove an event listener."""
        if event_type in self._listeners:
            if callback in self._listeners[event_type]:
                self._listeners[event_type].remove(callback)

    def add_global_listener(self, callback: Callable):
        """Add a listener for all events."""
        self._global_listeners.append(callback)

    def remove_global_listener(self, callback: Callable):
        """Remove a global listener."""
        if callback in self._global_listeners:
            self._global_listeners.remove(callback)

    def emit(self, event: StoryEvent):
        """Emit an event to all listeners."""
        # Call type-specific listeners
        for listener in self._listeners.get(event.type, []):
            try:
                listener(event)
            except Exception as e:
                print(f"Error in event listener: {e}")

        # Call global listeners
        for listener in self._global_listeners:
            try:
                listener(event)
            except Exception as e:
                print(f"Error in global event listener: {e}")

    def emit_simple(self, event_type: EventType, **data):
        """Emit a simple event with data."""
        self.emit(StoryEvent(type=event_type, data=data))

    def register_condition_handler(self, name: str, handler: Callable):
        """Register a custom condition handler."""
        self._condition_handlers[name] = handler

    def register_action_handler(self, name: str, handler: Callable):
        """Register a custom action handler."""
        self._action_handlers[name] = handler

    def evaluate_condition(self, condition: str) -> bool:
        """
        Evaluate a condition string.

        Supports:
        - Variable checks: "$variable == value"
        - Comparisons: ">", "<", ">=", "<=", "==", "!="
        - Logical operators: "AND", "OR", "NOT"
        """
        if not condition:
            return True

        # Check for custom handler
        for name, handler in self._condition_handlers.items():
            if condition.startswith(name + "("):
                return handler(condition)

        # Parse variable conditions
        return self._parse_condition(condition)

    def _parse_condition(self, condition: str) -> bool:
        """Parse and evaluate a condition string."""
        condition = condition.strip()

        # Handle parentheses
        while '(' in condition and ')' in condition:
            start = condition.rfind('(')
            end = condition.find(')', start)
            if start == -1 or end == -1:
                break
            inner = condition[start + 1:end]
            result = self._parse_condition(inner)
            condition = condition[:start] + str(result) + condition[end + 1:]

        # Handle logical operators
        if ' AND ' in condition:
            parts = condition.split(' AND ')
            return all(self._parse_condition(p) for p in parts)

        if ' OR ' in condition:
            parts = condition.split(' OR ')
            return any(self._parse_condition(p) for p in parts)

        if condition.startswith('NOT '):
            return not self._parse_condition(condition[4:])

        # Handle comparisons
        for op in ['>=', '<=', '!=', '==', '>', '<']:
            if op in condition:
                left, right = condition.split(op, 1)
                left_val = self._get_value(left.strip())
                right_val = self._get_value(right.strip())
                return self._compare(left_val, op, right_val)

        # Simple truthiness check
        return bool(self._get_value(condition))

    def _get_value(self, expr: str) -> Any:
        """Get the value of an expression."""
        expr = expr.strip()

        # Variable reference
        if expr.startswith('$'):
            var_name = expr[1:]
            return self.state.variables.get(var_name)

        # String literal
        if (expr.startswith('"') and expr.endswith('"')) or \
           (expr.startswith("'") and expr.endswith("'")):
            return expr[1:-1]

        # Boolean
        if expr.lower() == 'true':
            return True
        if expr.lower() == 'false':
            return False

        # Null
        if expr.lower() in ('null', 'none'):
            return None

        # Number
        try:
            if '.' in expr:
                return float(expr)
            return int(expr)
        except ValueError:
            pass

        return expr

    def _compare(self, left: Any, op: str, right: Any) -> bool:
        """Compare two values."""
        try:
            if op == '==':
                return left == right
            elif op == '!=':
                return left != right
            elif op == '>':
                return left > right
            elif op == '<':
                return left < right
            elif op == '>=':
                return left >= right
            elif op == '<=':
                return left <= right
        except TypeError:
            return False
        return False

    def execute_action(self, action: str, **params):
        """Execute an action."""
        if action in self._action_handlers:
            self._action_handlersaction

    def _action_goto_page(self, page_id: str, **kwargs):
        """Navigate to a page."""
        if self.story and page_id in self.story.pages:
            old_page = self.state.current_page_id
            self.state.current_page_id = page_id
            self.state.visited_pages.append(page_id)
            self.state.history.append(page_id)

            page = self.story.pages[page_id]
            self.state.current_chapter_id = page.chapter_id

            self.emit(StoryEvent(
                type=EventType.PAGE_CHANGE,
                data={
                    "from": old_page,
                    "to": page_id,
                    "page": page,
                }
            ))

    def _action_goto_chapter(self, chapter_id: str, **kwargs):
        """Navigate to a chapter."""
        if self.story and chapter_id in self.story.chapters:
            old_chapter = self.state.current_chapter_id
            self.state.current_chapter_id = chapter_id

            chapter = self.story.chapters[chapter_id]
            if chapter.pages and not self.state.current_page_id:
                self._action_goto_page(chapter.pages[0])

            self.emit(StoryEvent(
                type=EventType.CHAPTER_CHANGE,
                data={
                    "from": old_chapter,
                    "to": chapter_id,
                    "chapter": chapter,
                }
            ))

    def _action_set_variable(self, name: str, value: Any, **kwargs):
        """Set a story variable."""
        old_value = self.state.variables.get(name)
        self.state.variables[name] = value

        self.emit(StoryEvent(
            type=EventType.VARIABLE_SET,
            data={
                "name": name,
                "old_value": old_value,
                "new_value": value,
            }
        ))

    def _action_play_audio(self, track: str, **kwargs):
        """Play audio track."""
        self.emit(StoryEvent(
            type=EventType.AUDIO_STARTED,
            data={"track": track, **kwargs}
        ))

    def _action_stop_audio(self, **kwargs):
        """Stop audio."""
        self.emit(StoryEvent(
            type=EventType.AUDIO_ENDED,
            data=kwargs
        ))

    def handle_interaction(self, interaction, **context):
        """Handle a user interaction."""
        from .models import InteractionType

        if interaction.type == InteractionType.CHOICE:
            # Filter options by condition
            valid_options = []
            for option in interaction.options:
                if not option.condition or self.evaluate_condition(option.condition):
                    valid_options.append(option)
            return valid_options

        elif interaction.type == InteractionType.HOTSPOT:
            if interaction.action:
                self.execute_action(interaction.action, **context)
            return True

        elif interaction.type == InteractionType.TIMER:
            # Timer interactions are handled externally
            return interaction

        return None

    def make_choice(self, choice, **context):
        """Record a choice and execute its action."""
        self.state.choices_made[context.get('interaction_id', 'unknown')] = choice.target

        self.emit(StoryEvent(
            type=EventType.CHOICE_MADE,
            data={
                "choice": choice,
                "context": context,
            }
        ))

        # Navigate to target
        if choice.target:
            self._action_goto_page(choice.target)

    def save_state(self, filepath: str):
        """Save current state to file."""
        with open(filepath, 'w') as f:
            json.dump(self.state.to_dict(), f, indent=2)

    def load_state(self, filepath: str):
        """Load state from file."""
        with open(filepath, 'r') as f:
            data = json.load(f)
            self.state = StoryState.from_dict(data)

    def reset(self):
        """Reset story state."""
        self.state = StoryState()
