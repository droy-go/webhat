import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../services/story_service.dart';
import '../models/story.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedChapterId;
  String? _selectedPageId;

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryService>(
      builder: (context, storyService, child) {
        final package = storyService.currentPackage;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Editor'),
            actions: [
              if (package != null) ...[
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => storyService.saveProject(),
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _exportWebHat(context, storyService),
                  tooltip: 'Export .webhat',
                ),
              ],
            ],
          ),
          body: package == null
              ? _NewProjectView(
                  onCreateProject: (title, author) {
                    storyService.createNewProject(title, author);
                  },
                )
              : Row(
                  children: [
                    // Left sidebar - Chapters & Pages
                    SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          // Chapters
                          Expanded(
                            flex: 1,
                            child: _ChaptersList(
                              chapters: package.story.chapters,
                              selectedChapterId: _selectedChapterId,
                              onChapterSelected: (id) {
                                setState(() => _selectedChapterId = id);
                              },
                              onAddChapter: () => _showAddChapterDialog(context, storyService),
                            ),
                          ),
                          const Divider(height: 1),
                          // Pages
                          Expanded(
                            flex: 1,
                            child: _PagesList(
                              chapter: _selectedChapterId != null
                                  ? package.story.chapters[_selectedChapterId]
                                  : null,
                              selectedPageId: _selectedPageId,
                              onPageSelected: (id) {
                                setState(() => _selectedPageId = id);
                              },
                              onAddPage: () => _addPage(context, storyService),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Center - Canvas
                    Expanded(
                      child: _selectedPageId != null
                          ? _PageEditor(
                              page: package.story.pages[_selectedPageId]!,
                              imageData: storyService.getPageImage(_selectedPageId!),
                            )
                          : const Center(
                              child: Text('Select a page to edit'),
                            ),
                    ),
                    const VerticalDivider(width: 1),
                    // Right sidebar - Properties
                    SizedBox(
                      width: 280,
                      child: _PropertiesPanel(
                        manifest: package.manifest,
                        onUpdate: (updatedManifest) {
                          // TODO: Update manifest
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showAddChapterDialog(BuildContext context, StoryService service) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Chapter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chapter Title',
            hintText: 'Enter chapter title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      service.addChapter(result);
    }
  }

  Future<void> _addPage(BuildContext context, StoryService service) async {
    if (_selectedChapterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter first')),
      );
      return;
    }

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    service.addPage(
      _selectedChapterId!,
      image.path,
      bytes,
    );
  }

  Future<void> _exportWebHat(BuildContext context, StoryService service) async {
    try {
      final path = await service.exportWebHat();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _NewProjectView extends StatefulWidget {
  final Function(String title, String author) onCreateProject;

  const _NewProjectView({required this.onCreateProject});

  @override
  State<_NewProjectView> createState() => _NewProjectViewState();
}

class _NewProjectViewState extends State<_NewProjectView> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Project',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Story Title',
                  hintText: 'Enter your story title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Enter author name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    widget.onCreateProject(
                      _titleController.text,
                      _authorController.text,
                    );
                  }
                },
                child: const Text('Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChaptersList extends StatelessWidget {
  final Map<String, Chapter> chapters;
  final String? selectedChapterId;
  final Function(String) onChapterSelected;
  final VoidCallback onAddChapter;

  const _ChaptersList({
    required this.chapters,
    required this.selectedChapterId,
    required this.onChapterSelected,
    required this.onAddChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: onAddChapter,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters.values.elementAt(index);
              final isSelected = chapter.id == selectedChapterId;

              return ListTile(
                dense: true,
                selected: isSelected,
                title: Text(
                  chapter.title,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${chapter.pages.length} pages',
                  style: const TextStyle(fontSize: 11),
                ),
                leading: const Icon(Icons.folder, size: 20),
                onTap: () => onChapterSelected(chapter.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PagesList extends StatelessWidget {
  final Chapter? chapter;
  final String? selectedPageId;
  final Function(String) onPageSelected;
  final VoidCallback onAddPage;

  const _PagesList({
    required this.chapter,
    required this.selectedPageId,
    required this.onPageSelected,
    required this.onAddPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pages',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              if (chapter != null)
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: onAddPage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        if (chapter == null)
          const Expanded(
            child: Center(
              child: Text(
                'Select a chapter',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: chapter!.pages.length,
              itemBuilder: (context, index) {
                final pageId = chapter!.pages[index];
                final isSelected = pageId == selectedPageId;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  color: isSelected ? const Color(0xFF6366F1) : null,
                  child: InkWell(
                    onTap: () => onPageSelected(pageId),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PageEditor extends StatelessWidget {
  final Page page;
  final List<int>? imageData;

  const _PageEditor({
    required this.page,
    this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pan_tool),
                onPressed: () {},
                tooltip: 'Select',
              ),
              IconButton(
                icon: const Icon(Icons.crop_square),
                onPressed: () {},
                tooltip: 'Add Panel',
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble),
                onPressed: () {},
                tooltip: 'Add Speech Bubble',
              ),
              const VerticalDivider(width: 16),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {},
              ),
              const Text('100%'),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Canvas
        Expanded(
          child: Container(
            color: const Color(0xFF2D2D44),
            child: Center(
              child: imageData != null
                  ? Image.memory(
                      imageData as List<int>,
                      fit: BoxFit.contain,
                    )
                  : const Text('No image'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertiesPanel extends StatelessWidget {
  final Manifest manifest;
  final Function(Manifest) onUpdate;

  const _PropertiesPanel({
    required this.manifest,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Story Info',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: manifest.title,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: manifest.author,
            decoration: const InputDecoration(
              labelText: 'Author',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: manifest.description,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
