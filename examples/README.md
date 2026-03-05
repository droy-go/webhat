# WebHat Examples

This folder contains example .webhat stories and templates.

## Sample Story

The `sample-story` folder contains a basic example demonstrating:
- Story structure (manifest.json, story.json)
- Multiple pages and chapters
- Speech bubbles with different styles
- Interactive choices
- Character definitions

### Creating a .webhat file

To create a .webhat file from the sample:

```bash
cd sample-story
zip -r ../sample-story.webhat manifest.json story.json pages/ icons/
```

Or use the Python engine:

```bash
webhat-engine pack sample-story/ sample-story.webhat
```

## Templates

Coming soon:
- Blank template
- Manga template (right-to-left reading)
- Interactive gamebook template
- Audio drama template

## Contributing

Have a great example story? Submit a pull request!
