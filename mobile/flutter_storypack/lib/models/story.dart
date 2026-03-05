import 'dart:convert';

class Manifest {
  final String formatVersion;
  final String id;
  final String title;
  final String? description;
  final String author;
  final String version;
  final String? createdAt;
  final String? updatedAt;
  final List<String> categories;
  final List<String> tags;
  final String language;
  final String rating;
  final int pagesCount;
  final bool hasAudio;
  final bool hasInteractions;
  final String? coverImage;
  final String? thumbnail;

  Manifest({
    required this.formatVersion,
    required this.id,
    required this.title,
    this.description,
    required this.author,
    required this.version,
    this.createdAt,
    this.updatedAt,
    this.categories = const [],
    this.tags = const [],
    this.language = 'en',
    this.rating = 'everyone',
    this.pagesCount = 0,
    this.hasAudio = false,
    this.hasInteractions = false,
    this.coverImage,
    this.thumbnail,
  });

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      formatVersion: json['format_version'] ?? '1.0.0',
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      author: json['author'] ?? 'Unknown',
      version: json['version'] ?? '1.0.0',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      categories: List<String>.from(json['categories'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      language: json['language'] ?? 'en',
      rating: json['rating'] ?? 'everyone',
      pagesCount: json['pages_count'] ?? 0,
      hasAudio: json['has_audio'] ?? false,
      hasInteractions: json['has_interactions'] ?? false,
      coverImage: json['cover_image'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format_version': formatVersion,
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'version': version,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'categories': categories,
      'tags': tags,
      'language': language,
      'rating': rating,
      'pages_count': pagesCount,
      'has_audio': hasAudio,
      'has_interactions': hasInteractions,
      'cover_image': coverImage,
      'thumbnail': thumbnail,
    };
  }
}

class Story {
  final String title;
  final Map<String, Chapter> chapters;
  final Map<String, Page> pages;
  final Map<String, Character> characters;
  final Map<String, AudioTrack> audioTracks;

  Story({
    required this.title,
    this.chapters = const {},
    this.pages = const {},
    this.characters = const {},
    this.audioTracks = const {},
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      title: json['title'] ?? 'Untitled',
      chapters: (json['chapters'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Chapter.fromJson(v)),
          ) ??
          {},
      pages: (json['pages'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Page.fromJson(k, v)),
          ) ??
          {},
      characters: (json['characters'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Character.fromJson(k, v)),
          ) ??
          {},
      audioTracks: (json['audio_tracks'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, AudioTrack.fromJson(k, v)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'chapters': chapters.map((k, v) => MapEntry(k, v.toJson())),
      'pages': pages.map((k, v) => MapEntry(k, v.toJson())),
      'characters': characters.map((k, v) => MapEntry(k, v.toJson())),
      'audio_tracks': audioTracks.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}

class Chapter {
  final String id;
  final String title;
  final List<String> pages;
  final String? description;

  Chapter({
    required this.id,
    required this.title,
    this.pages = const [],
    this.description,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Chapter',
      pages: List<String>.from(json['pages'] ?? []),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pages': pages,
      'description': description,
    };
  }
}

class Page {
  final String id;
  final String chapterId;
  final String image;
  final int width;
  final int height;
  final List<Panel> panels;
  final AudioConfig audio;
  final Transition transitions;
  final List<Interaction> interactions;
  final String? nextPage;
  final String? prevPage;

  Page({
    required this.id,
    required this.chapterId,
    required this.image,
    this.width = 1920,
    this.height = 1080,
    this.panels = const [],
    required this.audio,
    required this.transitions,
    this.interactions = const [],
    this.nextPage,
    this.prevPage,
  });

  factory Page.fromJson(String id, Map<String, dynamic> json) {
    return Page(
      id: id,
      chapterId: json['chapter_id'] ?? '',
      image: json['image'] ?? '',
      width: json['width'] ?? 1920,
      height: json['height'] ?? 1080,
      panels: (json['panels'] as List<dynamic>?)
              ?.map((p) => Panel.fromJson(p))
              .toList() ??
          [],
      audio: AudioConfig.fromJson(json['audio'] ?? {}),
      transitions: Transition.fromJson(json['transitions'] ?? {}),
      interactions: (json['interactions'] as List<dynamic>?)
              ?.map((i) => Interaction.fromJson(i))
              .toList() ??
          [],
      nextPage: json['next_page'],
      prevPage: json['prev_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter_id': chapterId,
      'image': image,
      'width': width,
      'height': height,
      'panels': panels.map((p) => p.toJson()).toList(),
      'audio': audio.toJson(),
      'transitions': transitions.toJson(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'next_page': nextPage,
      'prev_page': prevPage,
    };
  }
}

class Panel {
  final String id;
  final Bounds bounds;
  final List<SpeechBubble> speechBubbles;
  final List<Hotspot> hotspots;

  Panel({
    required this.id,
    required this.bounds,
    this.speechBubbles = const [],
    this.hotspots = const [],
  });

  factory Panel.fromJson(Map<String, dynamic> json) {
    return Panel(
      id: json['id'] ?? '',
      bounds: Bounds.fromJson(json['bounds'] ?? {}),
      speechBubbles: (json['speech_bubbles'] as List<dynamic>?)
              ?.map((b) => SpeechBubble.fromJson(b))
              .toList() ??
          [],
      hotspots: (json['hotspots'] as List<dynamic>?)
              ?.map((h) => Hotspot.fromJson(h))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bounds': bounds.toJson(),
      'speech_bubbles': speechBubbles.map((b) => b.toJson()).toList(),
      'hotspots': hotspots.map((h) => h.toJson()).toList(),
    };
  }
}

class SpeechBubble {
  final String id;
  final String text;
  final String? character;
  final Position position;
  final String style;
  final int fontSize;
  final String color;
  final String? backgroundColor;
  final int maxWidth;

  SpeechBubble({
    required this.id,
    required this.text,
    this.character,
    required this.position,
    this.style = 'speech',
    this.fontSize = 16,
    this.color = '#000000',
    this.backgroundColor,
    this.maxWidth = 300,
  });

  factory SpeechBubble.fromJson(Map<String, dynamic> json) {
    return SpeechBubble(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      character: json['character'],
      position: Position.fromJson(json['position'] ?? {}),
      style: json['style'] ?? 'speech',
      fontSize: json['font_size'] ?? 16,
      color: json['color'] ?? '#000000',
      backgroundColor: json['background_color'],
      maxWidth: json['max_width'] ?? 300,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'character': character,
      'position': position.toJson(),
      'style': style,
      'font_size': fontSize,
      'color': color,
      'background_color': backgroundColor,
      'max_width': maxWidth,
    };
  }
}

class Hotspot {
  final String id;
  final Bounds bounds;
  final String action;
  final String? target;
  final String? tooltip;

  Hotspot({
    required this.id,
    required this.bounds,
    required this.action,
    this.target,
    this.tooltip,
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      id: json['id'] ?? '',
      bounds: Bounds.fromJson(json['bounds'] ?? {}),
      action: json['action'] ?? '',
      target: json['target'],
      tooltip: json['tooltip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bounds': bounds.toJson(),
      'action': action,
      'target': target,
      'tooltip': tooltip,
    };
  }
}

class Bounds {
  final double x;
  final double y;
  final double width;
  final double height;

  Bounds({
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
  });

  factory Bounds.fromJson(Map<String, dynamic> json) {
    return Bounds(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 100).toDouble(),
      height: (json['height'] ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  bool contains(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }
}

class Position {
  final double x;
  final double y;

  Position({
    this.x = 0,
    this.y = 0,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class AudioConfig {
  final String? bgm;
  final bool bgmLoop;
  final double bgmVolume;
  final List<String> sfx;
  final String? voice;

  AudioConfig({
    this.bgm,
    this.bgmLoop = true,
    this.bgmVolume = 0.7,
    this.sfx = const [],
    this.voice,
  });

  factory AudioConfig.fromJson(Map<String, dynamic> json) {
    return AudioConfig(
      bgm: json['bgm'],
      bgmLoop: json['bgm_loop'] ?? true,
      bgmVolume: (json['bgm_volume'] ?? 0.7).toDouble(),
      sfx: List<String>.from(json['sfx'] ?? []),
      voice: json['voice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bgm': bgm,
      'bgm_loop': bgmLoop,
      'bgm_volume': bgmVolume,
      'sfx': sfx,
      'voice': voice,
    };
  }
}

class Transition {
  final String inType;
  final String outType;
  final int duration;

  Transition({
    this.inType = 'fade',
    this.outType = 'fade',
    this.duration = 500,
  });

  factory Transition.fromJson(Map<String, dynamic> json) {
    return Transition(
      inType: json['in'] ?? 'fade',
      outType: json['out'] ?? 'fade',
      duration: json['duration'] ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in': inType,
      'out': outType,
      'duration': duration,
    };
  }
}

class Interaction {
  final String id;
  final String type;
  final Bounds trigger;
  final List<ChoiceOption> options;
  final String? action;
  final int delay;

  Interaction({
    required this.id,
    required this.type,
    required this.trigger,
    this.options = const [],
    this.action,
    this.delay = 0,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'hotspot',
      trigger: Bounds.fromJson(json['trigger'] ?? {}),
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ChoiceOption.fromJson(o))
              .toList() ??
          [],
      action: json['action'],
      delay: json['delay'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'trigger': trigger.toJson(),
      'options': options.map((o) => o.toJson()).toList(),
      'action': action,
      'delay': delay,
    };
  }
}

class ChoiceOption {
  final String text;
  final String target;
  final String? condition;

  ChoiceOption({
    required this.text,
    required this.target,
    this.condition,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    return ChoiceOption(
      text: json['text'] ?? '',
      target: json['target'] ?? '',
      condition: json['condition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'target': target,
      'condition': condition,
    };
  }
}

class Character {
  final String id;
  final String name;
  final String color;
  final String? avatar;

  Character({
    required this.id,
    required this.name,
    this.color = '#000000',
    this.avatar,
  });

  factory Character.fromJson(String id, Map<String, dynamic> json) {
    return Character(
      id: id,
      name: json['name'] ?? id,
      color: json['color'] ?? '#000000',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'avatar': avatar,
    };
  }
}

class AudioTrack {
  final String id;
  final String file;
  final bool loop;
  final double volume;

  AudioTrack({
    required this.id,
    required this.file,
    this.loop = false,
    this.volume = 1.0,
  });

  factory AudioTrack.fromJson(String id, Map<String, dynamic> json) {
    return AudioTrack(
      id: id,
      file: json['file'] ?? '',
      loop: json['loop'] ?? false,
      volume: (json['volume'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'loop': loop,
      'volume': volume,
    };
  }
}

class WebHatPackage {
  final Manifest manifest;
  final Story story;
  final Map<String, List<int>> files;

  WebHatPackage({
    required this.manifest,
    required this.story,
    this.files = const {},
  });
}
