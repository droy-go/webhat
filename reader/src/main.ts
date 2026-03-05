import { WebHatLoader } from './utils/loader';
import { AudioPlayer } from './utils/audio';
import type { WebHatPackage, Page, Chapter, ChoiceOption } from './types';

class WebHatReader {
  private loader: WebHatLoader;
  private audioPlayer: AudioPlayer;
  private package: WebHatPackage | null = null;
  private currentPageId: string | null = null;
  private pageHistory: string[] = [];
  private zoom: number = 1;
  private fileUrls: Map<string, string> = new Map();

  // DOM Elements
  private welcomeScreen: HTMLElement;
  private readerView: HTMLElement;
  private pageImage: HTMLImageElement;
  private pageWrapper: HTMLElement;
  private speechBubblesContainer: HTMLElement;
  private interactionsContainer: HTMLElement;
  private chapterList: HTMLElement;
  private prevBtn: HTMLButtonElement;
  private nextBtn: HTMLButtonElement;
  private pageIndicator: HTMLElement;
  private storyTitle: HTMLElement;
  private loadingOverlay: HTMLElement;
  private audioControls: HTMLElement;
  private zoomControls: HTMLElement;
  private audioToggle: HTMLButtonElement;
  private audioIcon: HTMLElement;
  private volumeSlider: HTMLInputElement;

  constructor() {
    this.loader = new WebHatLoader();
    this.audioPlayer = new AudioPlayer(this.getFileUrl.bind(this));
    this.initElements();
    this.bindEvents();
  }

  private initElements(): void {
    this.welcomeScreen = document.getElementById('welcome-screen')!;
    this.readerView = document.getElementById('reader-view')!;
    this.pageImage = document.getElementById('page-image') as HTMLImageElement;
    this.pageWrapper = document.getElementById('page-wrapper')!;
    this.speechBubblesContainer = document.getElementById('speech-bubbles')!;
    this.interactionsContainer = document.getElementById('interactions')!;
    this.chapterList = document.getElementById('chapter-list')!;
    this.prevBtn = document.getElementById('prev-btn') as HTMLButtonElement;
    this.nextBtn = document.getElementById('next-btn') as HTMLButtonElement;
    this.pageIndicator = document.getElementById('page-indicator')!;
    this.storyTitle = document.getElementById('story-title')!;
    this.loadingOverlay = document.getElementById('loading-overlay')!;
    this.audioControls = document.getElementById('audio-controls')!;
    this.zoomControls = document.getElementById('zoom-controls')!;
    this.audioToggle = document.getElementById('audio-toggle') as HTMLButtonElement;
    this.audioIcon = document.getElementById('audio-icon')!;
    this.volumeSlider = document.getElementById('volume-slider') as HTMLInputElement;
  }

  private bindEvents(): void {
    // File input
    const fileInput = document.getElementById('file-input') as HTMLInputElement;
    const openFileBtn = document.getElementById('open-file-btn')!;
    const welcomeOpenBtn = document.getElementById('welcome-open-btn')!;

    openFileBtn.addEventListener('click', () => fileInput.click());
    welcomeOpenBtn.addEventListener('click', () => fileInput.click());

    fileInput.addEventListener('change', (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) {
        this.loadStory(file);
      }
    });

    // Navigation
    this.prevBtn.addEventListener('click', () => this.goToPreviousPage());
    this.nextBtn.addEventListener('click', () => this.goToNextPage());

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (this.welcomeScreen.classList.contains('hidden')) {
        if (e.key === 'ArrowLeft') this.goToPreviousPage();
        if (e.key === 'ArrowRight') this.goToNextPage();
      }
    });

    // Audio controls
    this.audioToggle.addEventListener('click', () => this.toggleAudio());
    this.volumeSlider.addEventListener('input', (e) => {
      const volume = parseInt((e.target as HTMLInputElement).value) / 100;
      this.audioPlayer.setVolume(volume);
    });

    // Zoom controls
    document.getElementById('zoom-in')!.addEventListener('click', () => this.zoomIn());
    document.getElementById('zoom-out')!.addEventListener('click', () => this.zoomOut());
    document.getElementById('zoom-reset')!.addEventListener('click', () => this.resetZoom());

    // Mouse wheel zoom
    this.pageWrapper.addEventListener('wheel', (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        if (e.deltaY < 0) {
          this.zoomIn();
        } else {
          this.zoomOut();
        }
      }
    });
  }

  private async loadStory(file: File): Promise<void> {
    this.showLoading(true);

    try {
      // Clear previous story
      this.cleanup();

      // Load new story
      this.package = await this.loader.load(file);

      // Create file URLs
      await this.createFileUrls();

      // Update UI
      this.storyTitle.textContent = this.package.manifest.title;
      this.renderChapterList();

      // Show reader
      this.welcomeScreen.classList.add('hidden');
      this.readerView.classList.remove('hidden');
      this.audioControls.classList.remove('hidden');
      this.zoomControls.classList.remove('hidden');

      // Navigate to first page
      const firstChapter = Object.values(this.package.story.chapters)[0];
      if (firstChapter && firstChapter.pages.length > 0) {
        this.goToPage(firstChapter.pages[0]);
      }

    } catch (error) {
      console.error('Error loading story:', error);
      alert(`Error loading story: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      this.showLoading(false);
    }
  }

  private async createFileUrls(): Promise<void> {
    if (!this.package) return;

    // Create URLs for all files
    const promises: Promise<void>[] = [];

    this.package.files.forEach((blob, path) => {
      const promise = new Promise<void>((resolve) => {
        const url = URL.createObjectURL(blob);
        this.fileUrls.set(path, url);
        resolve();
      });
      promises.push(promise);
    });

    await Promise.all(promises);
  }

  private getFileUrl(path: string): string | undefined {
    return this.fileUrls.get(path);
  }

  private renderChapterList(): void {
    if (!this.package) return;

    this.chapterList.innerHTML = '';

    Object.values(this.package.story.chapters).forEach((chapter) => {
      const item = document.createElement('div');
      item.className = 'chapter-item';
      item.dataset.chapterId = chapter.id;

      const title = document.createElement('div');
      title.className = 'chapter-title';
      title.textContent = chapter.title;

      const pages = document.createElement('div');
      pages.className = 'chapter-pages';
      pages.textContent = `${chapter.pages.length} pages`;

      item.appendChild(title);
      item.appendChild(pages);

      item.addEventListener('click', () => {
        if (chapter.pages.length > 0) {
          this.goToPage(chapter.pages[0]);
        }
      });

      this.chapterList.appendChild(item);
    });
  }

  private updateChapterHighlight(): void {
    if (!this.package || !this.currentPageId) return;

    const page = this.package.story.pages[this.currentPageId];
    if (!page) return;

    document.querySelectorAll('.chapter-item').forEach((item) => {
      item.classList.remove('active');
      if (item.dataset.chapterId === page.chapter_id) {
        item.classList.add('active');
      }
    });
  }

  private async goToPage(pageId: string): Promise<void> {
    if (!this.package) return;

    const page = this.package.story.pages[pageId];
    if (!page) {
      console.warn(`Page not found: ${pageId}`);
      return;
    }

    this.currentPageId = pageId;
    this.pageHistory.push(pageId);

    // Update page image
    const imageUrl = this.getFileUrl(page.image);
    if (imageUrl) {
      this.pageImage.src = imageUrl;
      this.pageImage.style.transform = `scale(${this.zoom})`;
    }

    // Render speech bubbles
    this.renderSpeechBubbles(page);

    // Render interactions
    this.renderInteractions(page);

    // Play audio
    await this.playPageAudio(page);

    // Update UI
    this.updateNavigation();
    this.updateChapterHighlight();
    this.updatePageIndicator();
  }

  private renderSpeechBubbles(page: Page): void {
    this.speechBubblesContainer.innerHTML = '';

    page.panels.forEach((panel) => {
      panel.speech_bubbles.forEach((bubble) => {
        const bubbleEl = document.createElement('div');
        bubbleEl.className = `speech-bubble ${bubble.style}`;
        bubbleEl.textContent = bubble.text;
        bubbleEl.style.left = `${bubble.position.x}px`;
        bubbleEl.style.top = `${bubble.position.y}px`;
        bubbleEl.style.maxWidth = `${bubble.max_width}px`;
        bubbleEl.style.fontSize = `${bubble.font_size}px`;
        bubbleEl.style.color = bubble.color;

        if (bubble.background_color) {
          bubbleEl.style.backgroundColor = bubble.background_color;
        }

        this.speechBubblesContainer.appendChild(bubbleEl);
      });
    });
  }

  private renderInteractions(page: Page): void {
    this.interactionsContainer.innerHTML = '';

    page.interactions.forEach((interaction) => {
      const zone = document.createElement('div');
      zone.className = 'interaction-zone';
      zone.style.left = `${interaction.trigger.x}px`;
      zone.style.top = `${interaction.trigger.y}px`;
      zone.style.width = `${interaction.trigger.width}px`;
      zone.style.height = `${interaction.trigger.height}px`;

      zone.addEventListener('click', () => {
        this.handleInteraction(interaction);
      });

      this.interactionsContainer.appendChild(zone);
    });
  }

  private handleInteraction(interaction: any): void {
    if (interaction.type === 'choice') {
      this.showChoiceModal(interaction.options);
    } else if (interaction.type === 'hotspot' && interaction.action) {
      // Handle hotspot action
      if (interaction.action === 'goto_page' && interaction.target) {
        this.goToPage(interaction.target);
      }
    }
  }

  private showChoiceModal(options: ChoiceOption[]): void {
    const modal = document.createElement('div');
    modal.className = 'choice-modal';

    const content = document.createElement('div');
    content.className = 'choice-content';

    const title = document.createElement('h3');
    title.textContent = 'Make a choice';
    content.appendChild(title);

    const optionsContainer = document.createElement('div');
    optionsContainer.className = 'choice-options';

    options.forEach((option) => {
      const btn = document.createElement('button');
      btn.className = 'choice-btn';
      btn.textContent = option.text;
      btn.addEventListener('click', () => {
        document.body.removeChild(modal);
        this.goToPage(option.target);
      });
      optionsContainer.appendChild(btn);
    });

    content.appendChild(optionsContainer);
    modal.appendChild(content);
    document.body.appendChild(modal);
  }

  private async playPageAudio(page: Page): Promise<void> {
    // Play BGM
    if (page.audio.bgm) {
      await this.audioPlayer.playBGM(page.audio.bgm, page.audio.bgm_loop);
      this.audioPlayer.setVolume(page.audio.bgm_volume);
    }

    // Play SFX
    for (const sfx of page.audio.sfx) {
      await this.audioPlayer.playSFX(sfx);
    }

    // Play voice
    if (page.audio.voice) {
      await this.audioPlayer.playVoice(page.audio.voice);
    }
  }

  private goToPreviousPage(): void {
    if (!this.package || !this.currentPageId) return;

    const page = this.package.story.pages[this.currentPageId];
    if (page?.prev_page) {
      this.goToPage(page.prev_page);
    } else {
      // Find previous page in chapter
      const chapter = this.package.story.chapters[page.chapter_id];
      const currentIndex = chapter.pages.indexOf(this.currentPageId);
      if (currentIndex > 0) {
        this.goToPage(chapter.pages[currentIndex - 1]);
      }
    }
  }

  private goToNextPage(): void {
    if (!this.package || !this.currentPageId) return;

    const page = this.package.story.pages[this.currentPageId];
    if (page?.next_page) {
      this.goToPage(page.next_page);
    } else {
      // Find next page in chapter
      const chapter = this.package.story.chapters[page.chapter_id];
      const currentIndex = chapter.pages.indexOf(this.currentPageId);
      if (currentIndex < chapter.pages.length - 1) {
        this.goToPage(chapter.pages[currentIndex + 1]);
      }
    }
  }

  private updateNavigation(): void {
    if (!this.package || !this.currentPageId) return;

    const page = this.package.story.pages[this.currentPageId];
    const chapter = this.package.story.chapters[page.chapter_id];
    const currentIndex = chapter.pages.indexOf(this.currentPageId);

    this.prevBtn.disabled = currentIndex === 0 && !page.prev_page;
    this.nextBtn.disabled = currentIndex === chapter.pages.length - 1 && !page.next_page;
  }

  private updatePageIndicator(): void {
    if (!this.package || !this.currentPageId) return;

    const page = this.package.story.pages[this.currentPageId];
    const chapter = this.package.story.chapters[page.chapter_id];
    const currentIndex = chapter.pages.indexOf(this.currentPageId);

    this.pageIndicator.textContent = `Page ${currentIndex + 1} / ${chapter.pages.length}`;
  }

  private toggleAudio(): void {
    const enabled = !this.audioPlayer.isEnabled();
    this.audioPlayer.setEnabled(enabled);
    this.audioIcon.textContent = enabled ? '🔊' : '🔇';
  }

  private zoomIn(): void {
    this.zoom = Math.min(3, this.zoom + 0.1);
    this.applyZoom();
  }

  private zoomOut(): void {
    this.zoom = Math.max(0.5, this.zoom - 0.1);
    this.applyZoom();
  }

  private resetZoom(): void {
    this.zoom = 1;
    this.applyZoom();
  }

  private applyZoom(): void {
    this.pageImage.style.transform = `scale(${this.zoom})`;
    document.getElementById('zoom-level')!.textContent = `${Math.round(this.zoom * 100)}%`;
  }

  private showLoading(show: boolean): void {
    this.loadingOverlay.classList.toggle('hidden', !show);
  }

  private cleanup(): void {
    this.audioPlayer.stopAll();

    // Revoke file URLs
    this.fileUrls.forEach((url) => {
      URL.revokeObjectURL(url);
    });
    this.fileUrls.clear();

    this.loader.clear();
    this.package = null;
    this.currentPageId = null;
    this.pageHistory = [];
    this.zoom = 1;
  }
}

// Initialize reader when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new WebHatReader();
});
