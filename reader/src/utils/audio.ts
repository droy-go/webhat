export class AudioPlayer {
  private bgm: HTMLAudioElement | null = null;
  private sfx: HTMLAudioElement[] = [];
  private volume: number = 0.7;
  private enabled: boolean = true;
  private basePath: string = '';
  private fileResolver: (path: string) => string | undefined;

  constructor(fileResolver: (path: string) => string | undefined) {
    this.fileResolver = fileResolver;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    if (!enabled) {
      this.stopAll();
    }
  }

  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
    if (this.bgm) {
      this.bgm.volume = this.volume;
    }
  }

  getVolume(): number {
    return this.volume;
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  async playBGM(trackPath: string, loop: boolean = true): Promise<void> {
    if (!this.enabled) return;

    this.stopBGM();

    const url = this.fileResolver(trackPath);
    if (!url) {
      console.warn(`BGM file not found: ${trackPath}`);
      return;
    }

    this.bgm = new Audio(url);
    this.bgm.loop = loop;
    this.bgm.volume = this.volume;

    try {
      await this.bgm.play();
    } catch (e) {
      console.error('Error playing BGM:', e);
    }
  }

  stopBGM(): void {
    if (this.bgm) {
      this.bgm.pause();
      this.bgm.currentTime = 0;
      this.bgm = null;
    }
  }

  pauseBGM(): void {
    if (this.bgm) {
      this.bgm.pause();
    }
  }

  resumeBGM(): void {
    if (this.bgm && this.enabled) {
      this.bgm.play().catch(e => console.error('Error resuming BGM:', e));
    }
  }

  async playSFX(sfxPath: string): Promise<void> {
    if (!this.enabled) return;

    const url = this.fileResolver(sfxPath);
    if (!url) {
      console.warn(`SFX file not found: ${sfxPath}`);
      return;
    }

    const sfx = new Audio(url);
    sfx.volume = this.volume;

    try {
      await sfx.play();
      this.sfx.push(sfx);

      // Clean up after playback
      sfx.addEventListener('ended', () => {
        const index = this.sfx.indexOf(sfx);
        if (index > -1) {
          this.sfx.splice(index, 1);
        }
      });
    } catch (e) {
      console.error('Error playing SFX:', e);
    }
  }

  async playVoice(voicePath: string): Promise<void> {
    // Voice uses same mechanism as SFX
    await this.playSFX(voicePath);
  }

  stopAll(): void {
    this.stopBGM();
    this.sfx.forEach(sfx => {
      sfx.pause();
      sfx.currentTime = 0;
    });
    this.sfx = [];
  }

  fadeOutBGM(duration: number = 1000): void {
    if (!this.bgm) return;

    const startVolume = this.bgm.volume;
    const steps = 20;
    const stepDuration = duration / steps;
    let currentStep = 0;

    const fade = () => {
      currentStep++;
      const newVolume = startVolume * (1 - currentStep / steps);

      if (this.bgm) {
        this.bgm.volume = Math.max(0, newVolume);
      }

      if (currentStep < steps) {
        setTimeout(fade, stepDuration);
      } else {
        this.stopBGM();
        if (this.bgm) {
          this.bgm.volume = this.volume;
        }
      }
    };

    fade();
  }
}
