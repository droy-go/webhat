// WebHat Editor Type Definitions

export * from '../../../reader/src/types';

export interface EditorState {
  currentTool: ToolType;
  selectedElement: string | null;
  zoom: number;
  isDragging: boolean;
  dragStart: { x: number; y: number } | null;
}

export type ToolType = 'select' | 'panel' | 'bubble' | 'hotspot';

export interface Project {
  manifest: Manifest;
  story: Story;
  files: Map<string, File>;
}

export interface EditorConfig {
  autoSave: boolean;
  autoSaveInterval: number;
  defaultZoom: number;
  snapToGrid: boolean;
  gridSize: number;
}

export const DEFAULT_CONFIG: EditorConfig = {
  autoSave: true,
  autoSaveInterval: 30000,
  defaultZoom: 1,
  snapToGrid: false,
  gridSize: 10,
};
