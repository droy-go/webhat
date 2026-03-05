import JSZip from 'jszip';
import type { Project, Manifest, Story, Chapter, Page, Panel, SpeechBubble, EditorState, ToolType } from './types';
import { DEFAULT_CONFIG } from './types';

class WebHatEditor {
  private project: Project | null = null;
  private state: EditorState = {
    currentTool: 'select',
    selectedElement: null,
    zoom: 1,
    isDragging: false,
    dragStart: null,
  };

  private currentChapterId: string | null = null;
  private currentPageId: string | null = null;
  private elementCounter: number = 0;

  constructor() {
    this.initElements();
    this.bindEvents();
    this.newProject();
  }

  private initElements(): void {
    // Tool buttons
    document.getElementById('tool-select')?.addEventListener('click', () => this.setTool('select'));
    document.getElementById('tool-panel')?.addEventListener('click', () => this.setTool('panel'));
    document.getElementById('tool-bubble')?.addEventListener('click', () => this.setTool('bubble'));
    document.getElementById('tool-hotspot')?.addEventListener('click', () => this.setTool('hotspot'));

    // Zoom controls
    document.getElementById('zoom-in')?.addEventListener('click', () => this.zoomIn());
    document.getElementById('zoom-out')?.addEventListener('click', () => this.zoomOut());

    // Header buttons
    document.getElementById('new-btn')?.addEventListener('click', () => this.showModal('new-project-modal'));
    document.getElementById('open-btn')?.addEventListener('click', () => document.getElementById('open-input')?.click());
    document.getElementById('save-btn')?.addEventListener('click', () => this.saveProject());
    document.getElementById('export-btn')?.addEventListener('click', () => this.exportWebHat());

    // Add buttons
    document.getElementById('add-chapter-btn')?.addEventListener('click', () => this.showModal('add-chapter-modal'));
    document.getElementById('add-page-btn')?.addEventListener('click', () => this.showModal('add-page-modal'));

    // Canvas interactions
    const canvas = document.getElementById('canvas');
    canvas?.addEventListener('mousedown', (e) => this.onCanvasMouseDown(e));
    canvas?.addEventListener('mousemove', (e) => this.onCanvasMouseMove(e));
    canvas?.addEventListener('mouseup', (e) => this.onCanvasMouseUp(e));
    canvas?.addEventListener('click', (e) => this.onCanvasClick(e));

    // Story info inputs
    document.getElementById('story-title')?.addEventListener('change', (e) => {
      if (this.project) {
        this.project.manifest.title = (e.target as HTMLInputElement).value;
        this.updateProjectName();
      }
    });

    document.getElementById('story-author')?.addEventListener('change', (e) => {
      if (this.project) {
        this.project.manifest.author = (e.target as HTMLInputElement).value;
      }
    });

    document.getElementById('story-description')?.addEventListener('change', (e) => {
      if (this.project) {
        this.project.manifest.description = (e.target as HTMLTextAreaElement).value;
      }
    });
  }

  private bindEvents(): void {
    // Modal confirmations
    document.getElementById('confirm-new')?.addEventListener('click', () => this.confirmNewProject());
    document.getElementById('cancel-new')?.addEventListener('click', () => this.hideModal('new-project-modal'));

    document.getElementById('confirm-chapter')?.addEventListener('click', () => this.confirmAddChapter());
    document.getElementById('cancel-chapter')?.addEventListener('click', () => this.hideModal('add-chapter-modal'));

    document.getElementById('confirm-page')?.addEventListener('click', () => this.confirmAddPage());
    document.getElementById('cancel-page')?.addEventListener('click', () => this.hideModal('add-page-modal'));

    document.getElementById('confirm-bubble')?.addEventListener('click', () => this.confirmEditBubble());
    document.getElementById('cancel-bubble')?.addEventListener('click', () => this.hideModal('bubble-modal'));
    document.getElementById('delete-bubble')?.addEventListener('click', () => this.deleteBubble());

    // File input
    document.getElementById('open-input')?.addEventListener('change', (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) this.openProject(file);
    });
  }

  private newProject(): void {
    const manifest: Manifest = {
      format_version: '1.0.0',
      id: `com.author.project_${Date.now()}`,
      title: 'Untitled Project',
      author: '',
      version: '1.0.0',
      categories: [],
      tags: [],
      language: 'en',
      rating: 'everyone',
      pages_count: 0,
      has_audio: false,
      has_interactions: false,
    };

    const story: Story = {
      title: 'Untitled Project',
      chapters: {},
      pages: {},
      characters: {},
      audio_tracks: {},
    };

    this.project = {
      manifest,
      story,
      files: new Map(),
    };

    this.updateUI();
  }

  private async openProject(file: File): Promise<void> {
    try {
      const zip = await JSZip.loadAsync(file);
      const files = new Map<string, File>();

      // Extract files
      const promises: Promise<void>[] = [];
      zip.forEach((path, zipEntry) => {
        if (!zipEntry.dir) {
          promises.push(
            zipEntry.async('blob').then((blob) => {
              const fileObj = new File([blob], path.split('/').pop() || path);
              files.set(path, fileObj);
            })
          );
        }
      });
      await Promise.all(promises);

      // Load manifest and story
      const manifestBlob = files.get('manifest.json');
      const storyBlob = files.get('story.json');

      if (!manifestBlob || !storyBlob) {
        throw new Error('Invalid WebHat file: missing manifest.json or story.json');
      }

      const manifest: Manifest = JSON.parse(await manifestBlob.text());
      const story: Story = JSON.parse(await storyBlob.text());

      this.project = { manifest, story, files };
      this.updateUI();

      // Load first page if available
      const firstChapter = Object.values(story.chapters)[0];
      if (firstChapter?.pages.length > 0) {
        this.loadPage(firstChapter.pages[0]);
      }

    } catch (error) {
      console.error('Error opening project:', error);
      alert(`Error opening project: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  private saveProject(): void {
    if (!this.project) return;

    const data = {
      manifest: this.project.manifest,
      story: this.project.story,
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${this.project.manifest.title.replace(/\s+/g, '_')}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  private async exportWebHat(): Promise<void> {
    if (!this.project) return;

    const zip = new JSZip();

    // Add manifest and story
    zip.file('manifest.json', JSON.stringify(this.project.manifest, null, 2));
    zip.file('story.json', JSON.stringify(this.project.story, null, 2));

    // Add all files
    this.project.files.forEach((file, path) => {
      zip.file(path, file);
    });

    // Generate ZIP
    const blob = await zip.generateAsync({ type: 'blob' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${this.project.manifest.title.replace(/\s+/g, '_')}.webhat`;
    a.click();
    URL.revokeObjectURL(url);
  }

  private setTool(tool: ToolType): void {
    this.state.currentTool = tool;

    // Update UI
    document.querySelectorAll('.tool-btn').forEach((btn) => {
      btn.classList.remove('active');
    });
    document.getElementById(`tool-${tool}`)?.classList.add('active');
  }

  private zoomIn(): void {
    this.state.zoom = Math.min(3, this.state.zoom + 0.1);
    this.applyZoom();
  }

  private zoomOut(): void {
    this.state.zoom = Math.max(0.5, this.state.zoom - 0.1);
    this.applyZoom();
  }

  private applyZoom(): void {
    const canvas = document.getElementById('canvas') as HTMLElement;
    canvas.style.transform = `scale(${this.state.zoom})`;
    document.getElementById('zoom-level')!.textContent = `${Math.round(this.state.zoom * 100)}%`;
  }

  private showModal(modalId: string): void {
    document.getElementById(modalId)?.classList.remove('hidden');
  }

  private hideModal(modalId: string): void {
    document.getElementById(modalId)?.classList.add('hidden');
  }

  private confirmNewProject(): void {
    const title = (document.getElementById('new-title') as HTMLInputElement).value;
    const author = (document.getElementById('new-author') as HTMLInputElement).value;

    if (title) {
      this.newProject();
      if (this.project) {
        this.project.manifest.title = title;
        this.project.manifest.author = author;
        this.project.story.title = title;
        this.updateUI();
      }
    }

    this.hideModal('new-project-modal');
  }

  private confirmAddChapter(): void {
    const title = (document.getElementById('chapter-title') as HTMLInputElement).value;

    if (title && this.project) {
      const id = `chapter_${Date.now()}`;
      this.project.story.chapters[id] = {
        id,
        title,
        pages: [],
      };
      this.renderChapterList();
    }

    this.hideModal('add-chapter-modal');
  }

  private async confirmAddPage(): Promise<void> {
    const input = document.getElementById('page-image-input') as HTMLInputElement;
    const file = input.files?.[0];

    if (!file || !this.project || !this.currentChapterId) {
      alert('Please select an image and a chapter');
      return;
    }

    const pageId = `page_${Date.now()}`;
    const imagePath = `pages/${pageId}_${file.name}`;

    // Store file
    this.project.files.set(imagePath, file);

    // Create page
    const img = new Image();
    img.src = URL.createObjectURL(file);
    await new Promise((resolve) => {
      img.onload = resolve;
    });

    this.project.story.pages[pageId] = {
      id: pageId,
      chapter_id: this.currentChapterId,
      image: imagePath,
      width: img.width,
      height: img.height,
      panels: [],
      audio: { bgm_loop: true, bgm_volume: 0.7, sfx: [] },
      transitions: { in: 'fade', out: 'fade', duration: 500 },
      interactions: [],
    };

    // Add to chapter
    this.project.story.chapters[this.currentChapterId].pages.push(pageId);
    this.project.manifest.pages_count++;

    this.renderPageList();
    this.loadPage(pageId);

    this.hideModal('add-page-modal');
    input.value = '';
  }

  private loadPage(pageId: string): void {
    if (!this.project) return;

    const page = this.project.story.pages[pageId];
    if (!page) return;

    this.currentPageId = pageId;

    // Load image
    const file = this.project.files.get(page.image);
    if (file) {
      const canvasImage = document.getElementById('canvas-image') as HTMLImageElement;
      canvasImage.src = URL.createObjectURL(file);
    }

    // Render overlays
    this.renderOverlays(page);

    // Update UI
    this.updatePageSelection();
  }

  private renderOverlays(page: Page): void {
    const container = document.getElementById('overlay-layer')!;
    container.innerHTML = '';

    // Render panels
    page.panels.forEach((panel) => {
      const el = document.createElement('div');
      el.className = 'overlay-element overlay-panel';
      el.dataset.id = panel.id;
      el.dataset.type = 'panel';
      el.style.left = `${panel.bounds.x}px`;
      el.style.top = `${panel.bounds.y}px`;
      el.style.width = `${panel.bounds.width}px`;
      el.style.height = `${panel.bounds.height}px`;
      container.appendChild(el);
    });

    // Render speech bubbles
    page.panels.forEach((panel) => {
      panel.speech_bubbles.forEach((bubble) => {
        const el = document.createElement('div');
        el.className = `overlay-element overlay-bubble ${bubble.style}`;
        el.dataset.id = bubble.id;
        el.dataset.type = 'bubble';
        el.dataset.panelId = panel.id;
        el.style.left = `${bubble.position.x}px`;
        el.style.top = `${bubble.position.y}px`;
        el.textContent = bubble.text;
        el.addEventListener('dblclick', () => this.editBubble(bubble, panel.id));
        container.appendChild(el);
      });
    });
  }

  private onCanvasClick(e: MouseEvent): void {
    if (!this.project || !this.currentPageId) return;

    const canvas = document.getElementById('canvas')!;
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) / this.state.zoom;
    const y = (e.clientY - rect.top) / this.state.zoom;

    switch (this.state.currentTool) {
      case 'panel':
        this.addPanel(x, y);
        break;
      case 'bubble':
        this.addBubble(x, y);
        break;
      case 'hotspot':
        this.addHotspot(x, y);
        break;
    }
  }

  private addPanel(x: number, y: number): void {
    if (!this.project || !this.currentPageId) return;

    const page = this.project.story.pages[this.currentPageId];
    const panel: Panel = {
      id: `panel_${++this.elementCounter}`,
      bounds: { x: x - 100, y: y - 75, width: 200, height: 150 },
      speech_bubbles: [],
      hotspots: [],
    };

    page.panels.push(panel);
    this.renderOverlays(page);
    this.setTool('select');
  }

  private addBubble(x: number, y: number): void {
    if (!this.project || !this.currentPageId) return;

    const page = this.project.story.pages[this.currentPageId];

    // Find containing panel
    const panel = page.panels.find((p) =>
      x >= p.bounds.x &&
      x <= p.bounds.x + p.bounds.width &&
      y >= p.bounds.y &&
      y <= p.bounds.y + p.bounds.height
    );

    if (!panel) {
      alert('Please place speech bubble inside a panel');
      return;
    }

    const bubble: SpeechBubble = {
      id: `bubble_${++this.elementCounter}`,
      text: 'New speech bubble',
      position: { x, y },
      style: 'speech',
      font_size: 14,
      color: '#000000',
      max_width: 200,
    };

    panel.speech_bubbles.push(bubble);
    this.renderOverlays(page);
    this.editBubble(bubble, panel.id);
  }

  private addHotspot(x: number, y: number): void {
    // Implementation for adding hotspots
    console.log('Add hotspot at', x, y);
  }

  private editBubble(bubble: SpeechBubble, panelId: string): void {
    (document.getElementById('bubble-text') as HTMLTextAreaElement).value = bubble.text;
    (document.getElementById('bubble-character') as HTMLInputElement).value = bubble.character || '';
    (document.getElementById('bubble-style') as HTMLSelectElement).value = bubble.style;

    this.state.selectedElement = JSON.stringify({ bubbleId: bubble.id, panelId });
    this.showModal('bubble-modal');
  }

  private confirmEditBubble(): void {
    if (!this.state.selectedElement || !this.project || !this.currentPageId) return;

    const { bubbleId, panelId } = JSON.parse(this.state.selectedElement);
    const page = this.project.story.pages[this.currentPageId];
    const panel = page.panels.find((p) => p.id === panelId);
    const bubble = panel?.speech_bubbles.find((b) => b.id === bubbleId);

    if (bubble) {
      bubble.text = (document.getElementById('bubble-text') as HTMLTextAreaElement).value;
      bubble.character = (document.getElementById('bubble-character') as HTMLInputElement).value;
      bubble.style = (document.getElementById('bubble-style') as HTMLSelectElement).value as any;

      this.renderOverlays(page);
    }

    this.hideModal('bubble-modal');
  }

  private deleteBubble(): void {
    if (!this.state.selectedElement || !this.project || !this.currentPageId) return;

    const { bubbleId, panelId } = JSON.parse(this.state.selectedElement);
    const page = this.project.story.pages[this.currentPageId];
    const panel = page.panels.find((p) => p.id === panelId);

    if (panel) {
      panel.speech_bubbles = panel.speech_bubbles.filter((b) => b.id !== bubbleId);
      this.renderOverlays(page);
    }

    this.hideModal('bubble-modal');
  }

  private onCanvasMouseDown(e: MouseEvent): void {
    if (this.state.currentTool !== 'select') return;

    const target = e.target as HTMLElement;
    if (target.classList.contains('overlay-element')) {
      this.state.isDragging = true;
      this.state.dragStart = { x: e.clientX, y: e.clientY };
      target.classList.add('selected');
    }
  }

  private onCanvasMouseMove(e: MouseEvent): void {
    if (!this.state.isDragging || !this.state.dragStart) return;

    const dx = (e.clientX - this.state.dragStart.x) / this.state.zoom;
    const dy = (e.clientY - this.state.dragStart.y) / this.state.zoom;

    // Update element position
    const selected = document.querySelector('.overlay-element.selected') as HTMLElement;
    if (selected) {
      const currentLeft = parseFloat(selected.style.left || '0');
      const currentTop = parseFloat(selected.style.top || '0');
      selected.style.left = `${currentLeft + dx}px`;
      selected.style.top = `${currentTop + dy}px`;
    }

    this.state.dragStart = { x: e.clientX, y: e.clientY };
  }

  private onCanvasMouseUp(e: MouseEvent): void {
    if (this.state.isDragging) {
      this.saveElementPositions();
    }
    this.state.isDragging = false;
    this.state.dragStart = null;
  }

  private saveElementPositions(): void {
    if (!this.project || !this.currentPageId) return;

    const page = this.project.story.pages[this.currentPageId];

    document.querySelectorAll('.overlay-element').forEach((el) => {
      const element = el as HTMLElement;
      const id = element.dataset.id;
      const type = element.dataset.type;
      const x = parseFloat(element.style.left);
      const y = parseFloat(element.style.top);

      if (type === 'panel') {
        const panel = page.panels.find((p) => p.id === id);
        if (panel) {
          panel.bounds.x = x;
          panel.bounds.y = y;
        }
      } else if (type === 'bubble') {
        const panelId = element.dataset.panelId;
        const panel = page.panels.find((p) => p.id === panelId);
        const bubble = panel?.speech_bubbles.find((b) => b.id === id);
        if (bubble) {
          bubble.position.x = x;
          bubble.position.y = y;
        }
      }
    });
  }

  private updateUI(): void {
    if (!this.project) return;

    this.updateProjectName();
    this.renderChapterList();
    this.renderPageList();

    // Update story info
    (document.getElementById('story-title') as HTMLInputElement).value = this.project.manifest.title;
    (document.getElementById('story-author') as HTMLInputElement).value = this.project.manifest.author;
    (document.getElementById('story-description') as HTMLTextAreaElement).value =
      this.project.manifest.description || '';
  }

  private updateProjectName(): void {
    if (this.project) {
      document.getElementById('project-name')!.textContent = this.project.manifest.title;
    }
  }

  private renderChapterList(): void {
    if (!this.project) return;

    const container = document.getElementById('chapter-list')!;
    container.innerHTML = '';

    Object.values(this.project.story.chapters).forEach((chapter) => {
      const item = document.createElement('div');
      item.className = 'item';
      item.dataset.id = chapter.id;
      item.innerHTML = `<span class="item-icon">📁</span> ${chapter.title}`;

      if (chapter.id === this.currentChapterId) {
        item.classList.add('active');
      }

      item.addEventListener('click', () => {
        this.currentChapterId = chapter.id;
        this.renderChapterList();
        this.renderPageList();
      });

      container.appendChild(item);
    });
  }

  private renderPageList(): void {
    if (!this.project) return;

    const container = document.getElementById('page-list')!;
    container.innerHTML = '';

    const chapter = this.currentChapterId
      ? this.project.story.chapters[this.currentChapterId]
      : null;

    if (!chapter) return;

    chapter.pages.forEach((pageId, index) => {
      const page = this.project!.story.pages[pageId];
      const item = document.createElement('div');
      item.className = 'page-item';
      item.dataset.id = pageId;
      item.title = `Page ${index + 1}`;

      // Try to show thumbnail
      const file = this.project!.files.get(page.image);
      if (file) {
        const img = document.createElement('img');
        img.src = URL.createObjectURL(file);
        item.appendChild(img);
      } else {
        item.textContent = `${index + 1}`;
      }

      if (pageId === this.currentPageId) {
        item.classList.add('active');
      }

      item.addEventListener('click', () => this.loadPage(pageId));
      container.appendChild(item);
    });
  }

  private updatePageSelection(): void {
    document.querySelectorAll('.page-item').forEach((item) => {
      item.classList.toggle('active', item.dataset.id === this.currentPageId);
    });
  }
}

// Initialize editor
document.addEventListener('DOMContentLoaded', () => {
  new WebHatEditor();
});
