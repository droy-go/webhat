# Changelog

All notable changes to the WebHat StoryPack project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added
- Initial release of WebHat StoryPack platform
- **Engine**: Python library for loading and rendering .webhat files
  - WebHatLoader for parsing ZIP-based .webhat format
  - WebHatRenderer for rendering pages with speech bubbles
  - AudioPlayer for BGM and SFX playback
  - EventManager for handling story interactions
- **Reader**: Web-based reader (TypeScript + Vite)
  - Open and display .webhat files
  - Zoom and pan support
  - Chapter navigation
  - Audio playback
  - Keyboard navigation
- **Editor**: Web-based visual editor (TypeScript + Vite)
  - Create new comics
  - Add images, speech bubbles, hotspots
  - Chapter and page management
  - Export to .webhat format
- **Mobile App**: Flutter application (webhat-private)
  - Cross-platform support (Android, iOS, Windows, macOS, Linux)
  - Offline reading
  - Story creation and editing
  - Library management
- **Tools**: Category icon generator
  - Generate icons for all categories (action, horror, fantasy, scifi, comedy, education, kids)
  - Customizable sizes and colors
- **CI/CD**: GitHub Actions workflows
  - Automated builds for all platforms
  - GitHub Pages deployment
  - Automatic releases on tag push
- **Documentation**
  - Format specification
  - Engine API documentation
  - Scripting reference
  - Editor user guide

### Features
- ZIP-based .webhat file format
- Support for images (PNG, JPG, WebP)
- Audio support (MP3, OGG, WAV)
- Interactive elements (choices, hotspots, timers)
- Speech bubbles with multiple styles
- Page transitions
- Story variables and conditions
- Multi-platform support

[1.0.0]: https://github.com/yourusername/webhat-platform/releases/tag/v1.0.0
