# Contributing to WebHat StoryPack

Thank you for your interest in contributing to WebHat StoryPack! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Open a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, version, etc.)
   - Screenshots if applicable

### Suggesting Features

1. Open an issue with the "feature request" label
2. Describe the feature and its use case
3. Explain why it would be valuable

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

## Development Setup

### Prerequisites

- Python 3.8+
- Node.js 20+
- Flutter 3.16+
- Git

### Clone and Setup

```bash
git clone https://github.com/yourusername/webhat-platform.git
cd webhat-platform

# Setup Python engine
cd engine
pip install -e ".[dev]"

# Setup Web Reader
cd ../reader
npm install

# Setup Web Editor
cd ../editor
npm install

# Setup Flutter app
cd ../mobile/flutter_storypack
flutter pub get
```

## Project Structure

```
webhat-platform/
├── engine/           # Python engine
│   ├── webhat_engine/    # Main package
│   └── tests/            # Unit tests
├── reader/           # Web reader (TypeScript + Vite)
├── editor/           # Web editor (TypeScript + Vite)
├── mobile/           # Flutter applications
│   └── flutter_storypack/
├── packages/         # Shared packages
├── icons/            # Category icons
├── tools/            # Utility tools
└── docs/             # Documentation
```

## Coding Standards

### Python

- Follow PEP 8
- Use type hints
- Write docstrings for public APIs
- Maintain test coverage > 80%

### TypeScript

- Use strict mode
- Prefer interfaces over types
- Document public functions
- Use meaningful variable names

### Dart/Flutter

- Follow Effective Dart guidelines
- Use `const` constructors where possible
- Keep widgets small and focused
- Write widget tests

## Testing

### Python Engine

```bash
cd engine
pytest
```

### Web Components

```bash
cd reader
npm run test

cd ../editor
npm run test
```

### Flutter

```bash
cd mobile/flutter_storypack
flutter test
```

## Documentation

- Update README.md if needed
- Add docstrings to new functions
- Update relevant docs/ files
- Include code examples

## Commit Messages

Use conventional commits:

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
style: Formatting changes
refactor: Code restructuring
test: Add tests
chore: Maintenance tasks
```

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create a git tag (`git tag v1.0.0`)
4. Push tag (`git push origin v1.0.0`)
5. CI will create release automatically

## Questions?

- Open an issue for questions
- Join our community discussions
- Check existing documentation

Thank you for contributing!
