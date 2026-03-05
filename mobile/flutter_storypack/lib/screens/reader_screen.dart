import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/story_service.dart';
import '../services/settings_service.dart';
import '../models/story.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _zoom = 1.0;
  bool _showControls = true;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StoryService, SettingsService>(
      builder: (context, storyService, settings, child) {
        final package = storyService.currentPackage;

        if (package == null) {
          return const Scaffold(
            body: Center(child: Text('No story loaded')),
          );
        }

        final page = package.story.pages[storyService.currentPageId];
        if (page == null) {
          return const Scaffold(
            body: Center(child: Text('Page not found')),
          );
        }

        final imageData = storyService.getPageImage(page.id);

        // Play audio if enabled
        if (settings.autoPlay && page.audio.bgm != null) {
          _playBGM(storyService.getAudioData(page.audio.bgm!));
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              children: [
                // Page image
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.all(20),
                    child: imageData != null
                        ? Image.memory(
                            imageData,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Text('Image not found'),
                          ),
                  ),
                ),

                // Speech bubbles overlay
                if (settings.showBubbles)
                  Positioned.fill(
                    child: _SpeechBubblesOverlay(page: page),
                  ),

                // Top controls
                if (_showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  package.manifest.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  settings.showBubbles
                                      ? Icons.chat_bubble
                                      : Icons.chat_bubble_outline,
                                ),
                                onPressed: () {
                                  settings.setShowBubbles(!settings.showBubbles);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  // TODO: Show reader settings
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom navigation
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                onPressed: storyService.goToPreviousPage,
                              ),
                              Text(
                                'Page ${storyService.pageHistory.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: storyService.goToNextPage,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Chapter sidebar (desktop only)
                if (_showControls && MediaQuery.of(context).size.width > 600)
                  Positioned(
                    left: 0,
                    top: 100,
                    bottom: 100,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                      child: _ChapterSidebar(
                        story: package.story,
                        currentPageId: storyService.currentPageId,
                        onPageSelected: storyService.goToPage,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _playBGM(Uint8List? audioData) async {
    if (audioData == null) return;

    try {
      await _audioPlayer.stop();
      // Note: audioplayers doesn't directly support bytes, would need to save to temp file
      // This is a simplified implementation
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
}

class _SpeechBubblesOverlay extends StatelessWidget {
  final Page page;

  const _SpeechBubblesOverlay({required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: page.panels.expand((panel) {
        return panel.speechBubbles.map((bubble) {
          return Positioned(
            left: bubble.position.x,
            top: bubble.position.y,
            child: Container(
              constraints: BoxConstraints(maxWidth: bubble.maxWidth.toDouble()),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBubbleColor(bubble.style),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black54),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                bubble.text,
                style: TextStyle(
                  fontSize: bubble.fontSize.toDouble(),
                  color: _parseColor(bubble.color),
                ),
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Color _getBubbleColor(String style) {
    switch (style) {
      case 'thought':
        return const Color(0xFFF0F0F0);
      case 'narration':
        return const Color(0xFFFFF8DC);
      case 'shout':
        return const Color(0xFFFFE4E1);
      case 'whisper':
        return const Color(0xFFE6E6FA);
      default:
        return Colors.white;
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _ChapterSidebar extends StatelessWidget {
  final Story story;
  final String? currentPageId;
  final Function(String) onPageSelected;

  const _ChapterSidebar({
    required this.story,
    required this.currentPageId,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: story.chapters.length,
      itemBuilder: (context, chapterIndex) {
        final chapter = story.chapters.values.elementAt(chapterIndex);
        return ExpansionTile(
          title: Text(
            chapter.title,
            style: const TextStyle(fontSize: 14),
          ),
          initiallyExpanded: true,
          children: chapter.pages.asMap().entries.map((entry) {
            final pageIndex = entry.key;
            final pageId = entry.value;
            final isCurrent = pageId == currentPageId;

            return ListTile(
              dense: true,
              title: Text(
                'Page ${pageIndex + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? const Color(0xFF6366F1) : null,
                  fontWeight: isCurrent ? FontWeight.bold : null,
                ),
              ),
              selected: isCurrent,
              onTap: () => onPageSelected(pageId),
            );
          }).toList(),
        );
      },
    );
  }
}
