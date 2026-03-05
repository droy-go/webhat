#!/usr/bin/env python3
"""
Command-line interface for WebHat Engine.
"""

import argparse
import sys
import os

from .loader import WebHatLoader
from .renderer import WebHatRenderer


def main():
    parser = argparse.ArgumentParser(
        description="WebHat Engine - Load and render .webhat files"
    )
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Info command
    info_parser = subparsers.add_parser("info", help="Show story information")
    info_parser.add_argument("file", help="Path to .webhat file")

    # Render command
    render_parser = subparsers.add_parser("render", help="Render pages")
    render_parser.add_argument("file", help="Path to .webhat file")
    render_parser.add_argument("-o", "--output", default="output", help="Output directory")
    render_parser.add_argument("-p", "--page", help="Specific page to render")
    render_parser.add_argument("-s", "--scale", type=float, default=1.0, help="Scale factor")
    render_parser.add_argument("--no-bubbles", action="store_true", help="Hide speech bubbles")

    # Validate command
    validate_parser = subparsers.add_parser("validate", help="Validate .webhat file")
    validate_parser.add_argument("file", help="Path to .webhat file")

    # Extract command
    extract_parser = subparsers.add_parser("extract", help="Extract .webhat contents")
    extract_parser.add_argument("file", help="Path to .webhat file")
    extract_parser.add_argument("-o", "--output", required=True, help="Output directory")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == "info":
        cmd_info(args)
    elif args.command == "render":
        cmd_render(args)
    elif args.command == "validate":
        cmd_validate(args)
    elif args.command == "extract":
        cmd_extract(args)


def cmd_info(args):
    """Show story information."""
    try:
        with WebHatLoader() as loader:
            story = loader.load(args.file)
            manifest = story.manifest

            print(f"\n{'='*50}")
            print(f"Title: {manifest.title}")
            print(f"Author: {manifest.author}")
            print(f"Version: {manifest.version}")
            print(f"Format Version: {manifest.format_version}")
            print(f"{'='*50}")
            print(f"Description: {manifest.description or 'N/A'}")
            print(f"Language: {manifest.language}")
            print(f"Rating: {manifest.rating}")
            print(f"Pages: {manifest.pages_count}")
            print(f"Has Audio: {manifest.has_audio}")
            print(f"Has Interactions: {manifest.has_interactions}")
            print(f"Categories: {', '.join(manifest.categories) or 'None'}")
            print(f"Tags: {', '.join(manifest.tags) or 'None'}")

            print(f"\nChapters ({len(story.chapters)}):")
            for chapter in story.chapters.values():
                print(f"  - {chapter.title} ({len(chapter.pages)} pages)")

            print(f"\nCharacters ({len(story.characters)}):")
            for char in story.characters.values():
                print(f"  - {char.name}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_render(args):
    """Render pages from the story."""
    try:
        os.makedirs(args.output, exist_ok=True)

        with WebHatLoader() as loader:
            story = loader.load(args.file)
            renderer = WebHatRenderer(loader.extracted_path)

            pages_to_render = []
            if args.page:
                if args.page in story.pages:
                    pages_to_render = [story.pages[args.page]]
                else:
                    print(f"Error: Page '{args.page}' not found", file=sys.stderr)
                    sys.exit(1)
            else:
                pages_to_render = list(story.pages.values())

            print(f"Rendering {len(pages_to_render)} page(s)...")

            for page in pages_to_render:
                output_path = os.path.join(args.output, f"{page.id}.png")
                image = renderer.render_page(
                    page,
                    show_bubbles=not args.no_bubbles,
                    scale=args.scale
                )
                image.save(output_path)
                print(f"  Saved: {output_path}")

            print("Done!")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_validate(args):
    """Validate a .webhat file."""
    errors = []
    warnings = []

    try:
        with WebHatLoader() as loader:
            story = loader.load(args.file)

            # Check required files
            manifest = story.manifest

            if not manifest.id:
                errors.append("Missing story ID in manifest")

            if not manifest.title:
                errors.append("Missing story title in manifest")

            if not manifest.author:
                warnings.append("Missing author in manifest")

            # Check pages
            for page_id, page in story.pages.items():
                image_path = loader.get_file_path(page.image_path)
                if not os.path.exists(image_path):
                    errors.append(f"Page image not found: {page.image_path}")

                # Check audio files
                if page.audio.bgm:
                    bgm_path = loader.get_file_path(page.audio.bgm)
                    if not os.path.exists(bgm_path):
                        warnings.append(f"BGM file not found: {page.audio.bgm}")

                for sfx in page.audio.sfx:
                    sfx_path = loader.get_file_path(sfx)
                    if not os.path.exists(sfx_path):
                        warnings.append(f"SFX file not found: {sfx}")

            # Check characters referenced in bubbles exist
            for page in story.pages.values():
                for panel in page.panels:
                    for bubble in panel.speech_bubbles:
                        if bubble.character and bubble.character not in story.characters:
                            warnings.append(f"Character '{bubble.character}' referenced but not defined")

    except Exception as e:
        errors.append(str(e))

    # Print results
    print(f"\n{'='*50}")
    print(f"Validation Results for: {args.file}")
    print(f"{'='*50}")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for error in errors:
            print(f"  [ERROR] {error}")

    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for warning in warnings:
            print(f"  [WARN] {warning}")

    if not errors and not warnings:
        print("\n✓ Validation passed! No issues found.")
    elif not errors:
        print(f"\n✓ Validation passed with {len(warnings)} warning(s).")
    else:
        print(f"\n✗ Validation failed with {len(errors)} error(s).")
        sys.exit(1)


def cmd_extract(args):
    """Extract .webhat contents."""
    import zipfile

    try:
        os.makedirs(args.output, exist_ok=True)

        with zipfile.ZipFile(args.file, 'r') as zip_ref:
            zip_ref.extractall(args.output)

        print(f"Extracted to: {args.output}")
        print(f"Files: {len(zip_ref.namelist())}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
