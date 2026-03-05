# WebHat StoryPack Platform

An open-source interactive comic format and platform for creating, reading, and sharing digital stories.

## What is WebHat?

WebHat (.webhat) is a new interactive comic format designed for modern digital storytelling. It combines:
- Rich visual content (images, panels)
- Audio narration and sound effects
- Interactive elements and branching paths
- Cross-platform compatibility

## Project Structure

```
webhat-platform/
├── engine/          # Python engine for rendering .webhat files
├── reader/          # Web-based reader (TypeScript + Vite)
├── editor/          # Web-based visual editor
├── mobile/          # Flutter applications
│   └── flutter_storypack/  # Mobile/desktop app
├── packages/        # Shared packages and schemas
├── icons/           # Category icons
├── tools/           # Utility tools
└── docs/            # Documentation
```

## Quick Start

### Web Reader
```bash
cd reader
npm install
npm run dev
```

### Web Editor
```bash
cd editor
npm install
npm run dev
```

### Python Engine
```bash
cd engine
pip install -e .
```

### Flutter App
```bash
cd mobile/flutter_storypack
flutter pub get
flutter run
```

## File Format

The `.webhat` format is a ZIP-based package containing:

```
example.webhat
├── manifest.json    # Package metadata
├── story.json       # Story structure and events
├── pages/           # Comic page images
├── audio/           # Audio files
├── icons/           # Story icons
└── scripts/         # Interactive scripts
```

## Features

- **Cross-Platform**: Works on Web, Android, iOS, Windows, macOS, and Linux
- **Interactive**: Support for branching narratives and user choices
- **Rich Media**: Images, audio, animations
- **Offline First**: Works without internet connection
- **Open Source**: Fully open and extensible

## Documentation

See the [docs](./docs) folder for complete documentation:
- [Format Specification](./docs/format-spec.md)
- [Engine API](./docs/engine-api.md)
- [Editor Guide](./docs/editor-guide.md)
- [Scripting Reference](./docs/scripting.md)

## License

MIT License - See [LICENSE](./LICENSE) for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
