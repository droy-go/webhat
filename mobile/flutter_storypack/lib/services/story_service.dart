import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../models/story.dart';

class StoryService extends ChangeNotifier {
  WebHatPackage? _currentPackage;
  String? _currentPageId;
  String? _currentChapterId;
  final List<String> _pageHistory = [];

  WebHatPackage? get currentPackage => _currentPackage;
  String? get currentPageId => _currentPageId;
  String? get currentChapterId => _currentChapterId;
  List<String> get pageHistory => List.unmodifiable(_pageHistory);

  // Load a .webhat file
  Future<void> loadWebHatFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    await loadWebHatBytes(bytes);
  }

  // Load from bytes
  Future<void> loadWebHatBytes(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, List<int>>{};

    // Extract all files
    for (final file in archive) {
      if (file.isFile) {
        files[file.name] = file.content as List<int>;
      }
    }

    // Parse manifest
    final manifestBytes = files['manifest.json'];
    if (manifestBytes == null) {
      throw Exception('manifest.json not found in WebHat package');
    }
    final manifest = Manifest.fromJson(
      jsonDecode(utf8.decode(manifestBytes)),
    );

    // Parse story
    final storyBytes = files['story.json'];
    if (storyBytes == null) {
      throw Exception('story.json not found in WebHat package');
    }
    final story = Story.fromJson(
      jsonDecode(utf8.decode(storyBytes)),
    );

    _currentPackage = WebHatPackage(
      manifest: manifest,
      story: story,
      files: files,
    );

    // Navigate to first page
    final firstChapter = story.chapters.values.firstOrNull;
    if (firstChapter != null && firstChapter.pages.isNotEmpty) {
      _currentChapterId = firstChapter.id;
      _currentPageId = firstChapter.pages.first;
    }

    notifyListeners();
  }

  // Pick and load file
  Future<void> pickAndLoadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['webhat'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        await loadWebHatFile(file.path!);
      } else if (file.bytes != null) {
        await loadWebHatBytes(file.bytes!);
      }
    }
  }

  // Navigate to page
  void goToPage(String pageId) {
    if (_currentPackage?.story.pages.containsKey(pageId) ?? false) {
      _pageHistory.add(pageId);
      _currentPageId = pageId;

      final page = _currentPackage!.story.pages[pageId]!;
      _currentChapterId = page.chapterId;

      notifyListeners();
    }
  }

  // Go to next page
  void goToNextPage() {
    if (_currentPackage == null || _currentPageId == null) return;

    final page = _currentPackage!.story.pages[_currentPageId!];
    if (page == null) return;

    if (page.nextPage != null) {
      goToPage(page.nextPage!);
      return;
    }

    final chapter = _currentPackage!.story.chapters[page.chapterId];
    if (chapter == null) return;

    final currentIndex = chapter.pages.indexOf(_currentPageId!);
    if (currentIndex < chapter.pages.length - 1) {
      goToPage(chapter.pages[currentIndex + 1]);
    }
  }

  // Go to previous page
  void goToPreviousPage() {
    if (_currentPackage == null || _currentPageId == null) return;

    final page = _currentPackage!.story.pages[_currentPageId!];
    if (page == null) return;

    if (page.prevPage != null) {
      goToPage(page.prevPage!);
      return;
    }

    final chapter = _currentPackage!.story.chapters[page.chapterId];
    if (chapter == null) return;

    final currentIndex = chapter.pages.indexOf(_currentPageId!);
    if (currentIndex > 0) {
      goToPage(chapter.pages[currentIndex - 1]);
    }
  }

  // Get image data for a page
  Uint8List? getPageImage(String pageId) {
    final page = _currentPackage?.story.pages[pageId];
    if (page == null) return null;

    final imageData = _currentPackage?.files[page.image];
    if (imageData == null) return null;

    return Uint8List.fromList(imageData);
  }

  // Get audio data
  Uint8List? getAudioData(String path) {
    final data = _currentPackage?.files[path];
    if (data == null) return null;

    return Uint8List.fromList(data);
  }

  // Close current story
  void closeStory() {
    _currentPackage = null;
    _currentPageId = null;
    _currentChapterId = null;
    _pageHistory.clear();
    notifyListeners();
  }

  // Create new project
  void createNewProject(String title, String author) {
    final manifest = Manifest(
      formatVersion: '1.0.0',
      id: 'com.${author.toLowerCase().replaceAll(" ", "_")}.${title.toLowerCase().replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      version: '1.0.0',
      createdAt: DateTime.now().toIso8601String(),
    );

    final story = Story(
      title: title,
      chapters: {},
      pages: {},
      characters: {},
      audioTracks: {},
    );

    _currentPackage = WebHatPackage(
      manifest: manifest,
      story: story,
      files: {},
    );

    notifyListeners();
  }

  // Add chapter
  void addChapter(String title) {
    if (_currentPackage == null) return;

    final id = 'chapter_${DateTime.now().millisecondsSinceEpoch}';
    final chapter = Chapter(
      id: id,
      title: title,
      pages: [],
    );

    final newChapters = Map<String, Chapter>.from(_currentPackage!.story.chapters);
    newChapters[id] = chapter;

    _currentPackage = WebHatPackage(
      manifest: _currentPackage!.manifest,
      story: Story(
        title: _currentPackage!.story.title,
        chapters: newChapters,
        pages: _currentPackage!.story.pages,
        characters: _currentPackage!.story.characters,
        audioTracks: _currentPackage!.story.audioTracks,
      ),
      files: _currentPackage!.files,
    );

    notifyListeners();
  }

  // Add page to chapter
  void addPage(String chapterId, String imagePath, Uint8List imageData, {int width = 1920, int height = 1080}) {
    if (_currentPackage == null) return;

    final pageId = 'page_${DateTime.now().millisecondsSinceEpoch}';
    final fileName = 'pages/$pageId\_${imagePath.split('/').last}';

    // Add image to files
    final newFiles = Map<String, List<int>>.from(_currentPackage!.files);
    newFiles[fileName] = imageData.toList();

    // Create page
    final page = Page(
      id: pageId,
      chapterId: chapterId,
      image: fileName,
      width: width,
      height: height,
      audio: AudioConfig(),
      transitions: Transition(),
    );

    // Update story
    final newPages = Map<String, Page>.from(_currentPackage!.story.pages);
    newPages[pageId] = page;

    // Update chapter
    final newChapters = Map<String, Chapter>.from(_currentPackage!.story.chapters);
    final chapter = newChapters[chapterId];
    if (chapter != null) {
      newChapters[chapterId] = Chapter(
        id: chapter.id,
        title: chapter.title,
        pages: [...chapter.pages, pageId],
        description: chapter.description,
      );
    }

    // Update manifest
    final newManifest = Manifest(
      formatVersion: _currentPackage!.manifest.formatVersion,
      id: _currentPackage!.manifest.id,
      title: _currentPackage!.manifest.title,
      description: _currentPackage!.manifest.description,
      author: _currentPackage!.manifest.author,
      version: _currentPackage!.manifest.version,
      createdAt: _currentPackage!.manifest.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      categories: _currentPackage!.manifest.categories,
      tags: _currentPackage!.manifest.tags,
      language: _currentPackage!.manifest.language,
      rating: _currentPackage!.manifest.rating,
      pagesCount: _currentPackage!.manifest.pagesCount + 1,
      hasAudio: _currentPackage!.manifest.hasAudio,
      hasInteractions: _currentPackage!.manifest.hasInteractions,
      coverImage: _currentPackage!.manifest.coverImage,
      thumbnail: _currentPackage!.manifest.thumbnail,
    );

    _currentPackage = WebHatPackage(
      manifest: newManifest,
      story: Story(
        title: _currentPackage!.story.title,
        chapters: newChapters,
        pages: newPages,
        characters: _currentPackage!.story.characters,
        audioTracks: _currentPackage!.story.audioTracks,
      ),
      files: newFiles,
    );

    notifyListeners();
  }

  // Export to .webhat file
  Future<String> exportWebHat() async {
    if (_currentPackage == null) {
      throw Exception('No project to export');
    }

    final archive = Archive();

    // Add manifest
    final manifestJson = jsonEncode(_currentPackage!.manifest.toJson());
    archive.addFile(
      ArchiveFile('manifest.json', manifestJson.length, utf8.encode(manifestJson)),
    );

    // Add story
    final storyJson = jsonEncode(_currentPackage!.story.toJson());
    archive.addFile(
      ArchiveFile('story.json', storyJson.length, utf8.encode(storyJson)),
    );

    // Add all files
    for (final entry in _currentPackage!.files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }

    // Encode to bytes
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw Exception('Failed to encode ZIP archive');
    }

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final fileName = '${_currentPackage!.manifest.title.replaceAll(" ", "_")}.webhat';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // Save project to local storage
  Future<void> saveProject() async {
    if (_currentPackage == null) return;

    final prefs = await SharedPreferences.getInstance();
    final projectData = {
      'manifest': _currentPackage!.manifest.toJson(),
      'story': _currentPackage!.story.toJson(),
    };

    await prefs.setString('current_project', jsonEncode(projectData));
  }

  // Load project from local storage
  Future<void> loadSavedProject() async {
    final prefs = await SharedPreferences.getInstance();
    final projectJson = prefs.getString('current_project');

    if (projectJson != null) {
      final projectData = jsonDecode(projectJson);
      final manifest = Manifest.fromJson(projectData['manifest']);
      final story = Story.fromJson(projectData['story']);

      _currentPackage = WebHatPackage(
        manifest: manifest,
        story: story,
        files: {}, // Files are not persisted
      );

      notifyListeners();
    }
  }
}
