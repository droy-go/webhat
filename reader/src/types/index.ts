// WebHat Reader Type Definitions

export interface Manifest {
  format_version: string;
  id: string;
  title: string;
  description?: string;
  author: string;
  version: string;
  created_at?: string;
  updated_at?: string;
  categories: string[];
  tags: string[];
  language: string;
  rating: string;
  pages_count: number;
  has_audio: boolean;
  has_interactions: boolean;
  cover_image?: string;
  thumbnail?: string;
}

export interface Position {
  x: number;
  y: number;
}

export interface Bounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface SpeechBubble {
  id: string;
  text: string;
  character?: string;
  position: Position;
  style: 'speech' | 'thought' | 'narration' | 'shout' | 'whisper';
  font_size: number;
  color: string;
  background_color?: string;
  max_width: number;
}

export interface Panel {
  id: string;
  bounds: Bounds;
  speech_bubbles: SpeechBubble[];
  hotspots: Hotspot[];
}

export interface Hotspot {
  id: string;
  bounds: Bounds;
  action: string;
  target?: string;
  tooltip?: string;
}

export interface ChoiceOption {
  text: string;
  target: string;
  condition?: string;
}

export interface Interaction {
  id: string;
  type: 'choice' | 'hotspot' | 'timer' | 'swipe';
  trigger: Bounds;
  options: ChoiceOption[];
  action?: string;
  delay: number;
}

export interface AudioConfig {
  bgm?: string;
  bgm_loop: boolean;
  bgm_volume: number;
  sfx: string[];
  voice?: string;
}

export interface Transition {
  in: string;
  out: string;
  duration: number;
}

export interface Page {
  id: string;
  chapter_id: string;
  image: string;
  width: number;
  height: number;
  panels: Panel[];
  audio: AudioConfig;
  transitions: Transition;
  interactions: Interaction[];
  next_page?: string;
  prev_page?: string;
}

export interface Chapter {
  id: string;
  title: string;
  pages: string[];
  description?: string;
}

export interface Character {
  id: string;
  name: string;
  color: string;
  avatar?: string;
}

export interface AudioTrack {
  id: string;
  file: string;
  loop: boolean;
  volume: number;
}

export interface Story {
  title: string;
  chapters: Record<string, Chapter>;
  pages: Record<string, Page>;
  characters: Record<string, Character>;
  audio_tracks: Record<string, AudioTrack>;
  variables?: Record<string, any>;
}

export interface WebHatPackage {
  manifest: Manifest;
  story: Story;
  files: Map<string, Blob>;
}

export interface ReaderState {
  currentPageId: string | null;
  currentChapterId: string | null;
  visitedPages: string[];
  zoom: number;
  audioEnabled: boolean;
  volume: number;
}

export type EventCallback = (event: string, data?: any) => void;
