import JSZip from 'jszip';
import type { Manifest, Story, WebHatPackage } from '../types';

export class WebHatLoader {
  private files: Map<string, Blob> = new Map();

  async load(file: File): Promise<WebHatPackage> {
    const zip = await JSZip.loadAsync(file);

    // Extract all files
    this.files.clear();
    const filePromises: Promise<void>[] = [];

    zip.forEach((path, zipEntry) => {
      if (!zipEntry.dir) {
        const promise = zipEntry.async('blob').then(blob => {
          this.files.set(path, blob);
        });
        filePromises.push(promise);
      }
    });

    await Promise.all(filePromises);

    // Load manifest
    const manifestBlob = this.files.get('manifest.json');
    if (!manifestBlob) {
      throw new Error('manifest.json not found in WebHat package');
    }
    const manifest: Manifest = JSON.parse(await manifestBlob.text());

    // Load story
    const storyBlob = this.files.get('story.json');
    if (!storyBlob) {
      throw new Error('story.json not found in WebHat package');
    }
    const story: Story = JSON.parse(await storyBlob.text());

    return {
      manifest,
      story,
      files: this.files,
    };
  }

  getFile(path: string): Blob | undefined {
    return this.files.get(path);
  }

  async getFileUrl(path: string): Promise<string | undefined> {
    const blob = this.files.get(path);
    if (!blob) return undefined;
    return URL.createObjectURL(blob);
  }

  hasFile(path: string): boolean {
    return this.files.has(path);
  }

  clear(): void {
    // Revoke all object URLs
    this.files.forEach(blob => {
      URL.revokeObjectURL(URL.createObjectURL(blob));
    });
    this.files.clear();
  }
}
