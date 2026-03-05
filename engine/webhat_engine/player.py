"""
Audio player for WebHat stories.
"""

import os
import threading
from typing import Optional, Dict, Callable
from pathlib import Path

try:
    import pygame
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False

try:
    from pydub import AudioSegment
    from pydub.playback import play
    PYDUB_AVAILABLE = True
except ImportError:
    PYDUB_AVAILABLE = False


class AudioPlayer:
    """Plays audio for WebHat stories."""

    def __init__(self, base_path: str = ""):
        self.base_path = base_path
        self.current_bgm: Optional[str] = None
        self.bgm_volume: float = 0.7
        self.sfx_volume: float = 1.0
        self.is_playing: bool = False
        self._bgm_thread: Optional[threading.Thread] = None
        self._stop_bgm: bool = False
        self._callbacks: Dict[str, Callable] = {}

        # Initialize pygame if available
        if PYGAME_AVAILABLE:
            pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)

    def play_bgm(self, track_path: str, loop: bool = True, volume: float = 0.7):
        """
        Play background music.

        Args:
            track_path: Path to audio file
            loop: Whether to loop the track
            volume: Volume level (0.0 to 1.0)
        """
        if not PYGAME_AVAILABLE:
            print("Warning: pygame not available, cannot play audio")
            return

        # Stop current BGM
        self.stop_bgm()

        full_path = os.path.join(self.base_path, track_path)
        if not os.path.exists(full_path):
            print(f"Warning: Audio file not found: {full_path}")
            return

        self.current_bgm = track_path
        self.bgm_volume = volume

        try:
            pygame.mixer.music.load(full_path)
            pygame.mixer.music.set_volume(volume)
            pygame.mixer.music.play(-1 if loop else 0)
            self.is_playing = True
        except Exception as e:
            print(f"Error playing BGM: {e}")

    def stop_bgm(self):
        """Stop background music."""
        if PYGAME_AVAILABLE:
            pygame.mixer.music.stop()
        self.current_bgm = None
        self.is_playing = False

    def pause_bgm(self):
        """Pause background music."""
        if PYGAME_AVAILABLE:
            pygame.mixer.music.pause()
        self.is_playing = False

    def resume_bgm(self):
        """Resume background music."""
        if PYGAME_AVAILABLE:
            pygame.mixer.music.unpause()
        self.is_playing = True

    def set_bgm_volume(self, volume: float):
        """Set BGM volume (0.0 to 1.0)."""
        self.bgm_volume = max(0.0, min(1.0, volume))
        if PYGAME_AVAILABLE:
            pygame.mixer.music.set_volume(self.bgm_volume)

    def play_sfx(self, sfx_path: str, volume: float = 1.0) -> bool:
        """
        Play a sound effect.

        Args:
            sfx_path: Path to sound effect file
            volume: Volume level (0.0 to 1.0)

        Returns:
            True if played successfully
        """
        if not PYGAME_AVAILABLE:
            print("Warning: pygame not available, cannot play SFX")
            return False

        full_path = os.path.join(self.base_path, sfx_path)
        if not os.path.exists(full_path):
            print(f"Warning: SFX file not found: {full_path}")
            return False

        try:
            sound = pygame.mixer.Sound(full_path)
            sound.set_volume(max(0.0, min(1.0, volume)))
            sound.play()
            return True
        except Exception as e:
            print(f"Error playing SFX: {e}")
            return False

    def play_voice(self, voice_path: str, volume: float = 1.0) -> bool:
        """
        Play voice narration.

        Args:
            voice_path: Path to voice file
            volume: Volume level (0.0 to 1.0)

        Returns:
            True if played successfully
        """
        # Voice uses same mechanism as SFX
        return self.play_sfx(voice_path, volume)

    def fade_out_bgm(self, duration_ms: int = 1000):
        """Fade out background music."""
        if PYGAME_AVAILABLE:
            pygame.mixer.music.fadeout(duration_ms)
        self.is_playing = False

    def fade_in_bgm(self, track_path: str, duration_ms: int = 1000, loop: bool = True):
        """Fade in background music."""
        if not PYGAME_AVAILABLE:
            return

        full_path = os.path.join(self.base_path, track_path)
        if not os.path.exists(full_path):
            return

        try:
            pygame.mixer.music.load(full_path)
            pygame.mixer.music.set_volume(0)
            pygame.mixer.music.play(-1 if loop else 0)
            pygame.mixer.music.set_volume(self.bgm_volume)
            self.is_playing = True
        except Exception as e:
            print(f"Error fading in BGM: {e}")

    def is_bgm_playing(self) -> bool:
        """Check if BGM is currently playing."""
        if PYGAME_AVAILABLE:
            return pygame.mixer.music.get_busy()
        return False

    def get_position(self) -> float:
        """Get current playback position in milliseconds."""
        if PYGAME_AVAILABLE:
            return pygame.mixer.music.get_pos()
        return 0.0

    def register_callback(self, event: str, callback: Callable):
        """Register a callback for audio events."""
        self._callbacks[event] = callback

    def unregister_callback(self, event: str):
        """Unregister a callback."""
        if event in self._callbacks:
            del self._callbacks[event]

    def stop_all(self):
        """Stop all audio playback."""
        self.stop_bgm()
        if PYGAME_AVAILABLE:
            pygame.mixer.stop()

    def cleanup(self):
        """Clean up audio resources."""
        self.stop_all()
        if PYGAME_AVAILABLE:
            pygame.mixer.quit()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.cleanup()


class AudioPreloader:
    """Preloads audio files for smooth playback."""

    def __init__(self, base_path: str = ""):
        self.base_path = base_path
        self._cache: Dict[str, any] = {}
        self.max_cache_size = 50  # Maximum number of cached sounds

    def preload(self, audio_path: str) -> bool:
        """
        Preload an audio file into memory.

        Args:
            audio_path: Path to audio file

        Returns:
            True if preloaded successfully
        """
        if not PYGAME_AVAILABLE:
            return False

        if audio_path in self._cache:
            return True

        full_path = os.path.join(self.base_path, audio_path)
        if not os.path.exists(full_path):
            return False

        try:
            sound = pygame.mixer.Sound(full_path)
            self._cache[audio_path] = sound

            # Manage cache size
            if len(self._cache) > self.max_cache_size:
                oldest_key = next(iter(self._cache))
                del self._cache[oldest_key]

            return True
        except Exception as e:
            print(f"Error preloading audio: {e}")
            return False

    def get_cached(self, audio_path: str) -> Optional[any]:
        """Get a cached audio object."""
        return self._cache.get(audio_path)

    def clear_cache(self):
        """Clear the audio cache."""
        self._cache.clear()

    def preload_page_audio(self, page):
        """Preload all audio for a page."""
        if page.audio.bgm:
            self.preload(page.audio.bgm)
        for sfx in page.audio.sfx:
            self.preload(sfx)
        if page.audio.voice:
            self.preload(page.audio.voice)
