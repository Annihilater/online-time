import { audioEngine } from './audioEngine';

/**
 * 旧版音频管理器，保持向后兼容
 * @deprecated 使用新的 audioEngine 替代
 */
export class AlarmAudioManager {
  private audio: HTMLAudioElement | null = null;
  private volume: number = 0.7;

  constructor() {
    console.warn('AlarmAudioManager is deprecated. Use audioEngine instead.');
    this.audio = new Audio();
    this.audio.loop = true;
  }

  async play(soundName: string): Promise<void> {
    // 委托给新的音频引擎
    return audioEngine.play(soundName);
  }

  stop(): void {
    audioEngine.stop();
  }

  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
    audioEngine.setVolume(this.volume);
  }

  isPlaying(): boolean {
    return audioEngine.isCurrentlyPlaying();
  }

  async testSound(soundName: string, duration: number = 2000): Promise<void> {
    return audioEngine.testSound(soundName, duration);
  }
}

// 保持向后兼容的单例实例
export const audioManager = new AlarmAudioManager();

// 导出新的音频引擎作为主要接口
export { audioEngine } from './audioEngine';

// 音频工具函数
export const AudioUtils = {
  /**
   * 检查浏览器是否支持 Web Audio API
   */
  isWebAudioSupported(): boolean {
    return !!(window.AudioContext || (window as any).webkitAudioContext);
  },

  /**
   * 检查浏览器是否支持 Wake Lock API
   */
  isWakeLockSupported(): boolean {
    return 'wakeLock' in navigator;
  },

  /**
   * 检查浏览器是否支持通知
   */
  isNotificationSupported(): boolean {
    return 'Notification' in window;
  },

  /**
   * 请求通知权限
   */
  async requestNotificationPermission(): Promise<NotificationPermission> {
    if (!this.isNotificationSupported()) {
      return 'denied';
    }
    
    if (Notification.permission === 'default') {
      return await Notification.requestPermission();
    }
    
    return Notification.permission;
  },

  /**
   * 显示浏览器通知
   */
  showNotification(title: string, options?: NotificationOptions): Notification | null {
    if (!this.isNotificationSupported() || Notification.permission !== 'granted') {
      return null;
    }
    
    return new Notification(title, {
      icon: '/vite.svg',
      badge: '/vite.svg',
      tag: 'alarm',
      requireInteraction: true,
      ...options
    });
  },

  /**
   * 格式化音量百分比
   */
  formatVolumePercentage(volume: number): string {
    return `${Math.round(volume * 100)}%`;
  },

  /**
   * 从百分比转换为音量值
   */
  percentageToVolume(percentage: number): number {
    return Math.max(0, Math.min(1, percentage / 100));
  },

  /**
   * 获取用户友好的声音名称
   */
  getSoundDisplayName(soundKey: string): string {
    return audioEngine.getSoundName(soundKey);
  },

  /**
   * 获取所有可用声音列表
   */
  getAllSounds(): Array<{ key: string; name: string }> {
    return audioEngine.getAllSounds();
  }
};