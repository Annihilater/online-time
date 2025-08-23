import { ALARM_SOUNDS } from '@/shared/stores/alarmStore';

interface SoundData {
  name: string;
  frequency: number;
  type: OscillatorType;
  duration: number;
  envelope?: {
    attack: number;
    decay: number;
    sustain: number;
    release: number;
  };
}

// 音频节点跟踪，用于防止内存泄漏
interface AudioNodeTracker {
  nodes: Set<AudioNode>;
  timeouts: Set<NodeJS.Timeout>;
  created: number;
}

// 定义音频参数
const SOUND_DEFINITIONS: Record<string, SoundData> = {
  clock: {
    name: '时钟',
    frequency: 800,
    type: 'square',
    duration: 1.0,
    envelope: { attack: 0.01, decay: 0.1, sustain: 0.3, release: 0.5 }
  },
  beep: {
    name: '蜂鸣声',
    frequency: 1000,
    type: 'sine',
    duration: 0.5,
    envelope: { attack: 0.01, decay: 0.05, sustain: 0.8, release: 0.1 }
  },
  rooster: {
    name: '公鸡声',
    frequency: 600,
    type: 'sawtooth',
    duration: 2.0,
    envelope: { attack: 0.1, decay: 0.3, sustain: 0.4, release: 0.8 }
  },
  siren: {
    name: '警笛声',
    frequency: 440,
    type: 'triangle',
    duration: 1.5,
    envelope: { attack: 0.05, decay: 0.1, sustain: 0.7, release: 0.3 }
  },
  rain: {
    name: '雨声',
    frequency: 300,
    type: 'sine',
    duration: 4.0,
    envelope: { attack: 0.5, decay: 0.3, sustain: 0.8, release: 2.0 }
  },
  bell: {
    name: '钟声',
    frequency: 523,
    type: 'sine',
    duration: 3.0,
    envelope: { attack: 0.01, decay: 0.5, sustain: 0.3, release: 2.0 }
  },
  whitenoise: {
    name: '白噪音',
    frequency: 440,
    type: 'square',
    duration: 5.0,
    envelope: { attack: 0.1, decay: 0.0, sustain: 1.0, release: 0.5 }
  }
};

export class EnhancedAudioEngine {
  private audioContext: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private volume: number = 0.7;
  private isPlaying: boolean = false;
  private loopTimeout: NodeJS.Timeout | null = null;
  private wakeLock: WakeLockSentinel | null = null;
  
  // 改进的资源跟踪
  private activeNodes: Map<string, AudioNodeTracker> = new Map();
  private nodeCleanupTimeout: NodeJS.Timeout | null = null;
  private lastCleanup: number = 0;
  
  constructor() {
    this.initializeAudioContext();
    this.startPeriodicCleanup();
  }

  private async initializeAudioContext(): Promise<void> {
    try {
      this.audioContext = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
      
      // 创建主增益节点用于总音量控制
      this.masterGain = this.audioContext.createGain();
      this.masterGain.connect(this.audioContext.destination);
      this.masterGain.gain.setValueAtTime(this.volume, this.audioContext.currentTime);
      
      // Resume audio context if suspended
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }
    } catch (error) {
      console.error('Failed to initialize AudioContext:', error);
    }
  }

  private async ensureAudioContext(): Promise<AudioContext> {
    if (!this.audioContext) {
      await this.initializeAudioContext();
    }
    
    if (!this.audioContext) {
      throw new Error('AudioContext not available');
    }
    
    if (this.audioContext.state === 'suspended') {
      await this.audioContext.resume();
    }
    
    return this.audioContext;
  }

  // 改进的节点创建和跟踪
  private createTrackedNode<T extends AudioNode>(
    sessionId: string,
    nodeFactory: (context: AudioContext) => T
  ): T | null {
    if (!this.audioContext) return null;
    
    try {
      const node = nodeFactory(this.audioContext);
      
      // 跟踪节点
      if (!this.activeNodes.has(sessionId)) {
        this.activeNodes.set(sessionId, {
          nodes: new Set(),
          timeouts: new Set(),
          created: Date.now()
        });
      }
      
      const tracker = this.activeNodes.get(sessionId)!;
      tracker.nodes.add(node);
      
      return node;
    } catch (error) {
      console.error('Failed to create audio node:', error);
      return null;
    }
  }

  private trackTimeout(sessionId: string, timeout: NodeJS.Timeout): void {
    const tracker = this.activeNodes.get(sessionId);
    if (tracker) {
      tracker.timeouts.add(timeout);
    }
  }

  // 改进的复杂音调生成，带有完整的资源管理
  private createComplexTone(soundName: string, context: AudioContext, startTime: number): string {
    const sessionId = `${soundName}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const soundDef = SOUND_DEFINITIONS[soundName];
    if (!soundDef) return sessionId;

    // 创建基础振荡器和增益节点
    const oscillator = this.createTrackedNode(sessionId, (ctx) => ctx.createOscillator());
    const gainNode = this.createTrackedNode(sessionId, (ctx) => ctx.createGain());
    
    if (!oscillator || !gainNode || !this.masterGain) return sessionId;

    // 连接节点链
    oscillator.connect(gainNode);
    gainNode.connect(this.masterGain);
    
    // 配置振荡器
    oscillator.type = soundDef.type;
    oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
    
    // 应用ADSR包络
    if (soundDef.envelope) {
      const { attack, decay, sustain, release } = soundDef.envelope;
      
      gainNode.gain.setValueAtTime(0, startTime);
      gainNode.gain.linearRampToValueAtTime(1, startTime + attack);
      gainNode.gain.linearRampToValueAtTime(sustain, startTime + attack + decay);
      gainNode.gain.setValueAtTime(sustain, startTime + soundDef.duration - release);
      gainNode.gain.linearRampToValueAtTime(0, startTime + soundDef.duration);
    }
    
    // 添加特效
    this.addSoundEffects(sessionId, soundName, oscillator, gainNode, context, startTime, soundDef);
    
    // 启动振荡器
    oscillator.start(startTime);
    oscillator.stop(startTime + soundDef.duration);
    
    // 自动清理节点
    const cleanupTimeout = setTimeout(() => {
      this.cleanupSession(sessionId);
    }, (soundDef.duration + 1) * 1000);
    
    this.trackTimeout(sessionId, cleanupTimeout);
    
    return sessionId;
  }

  private addSoundEffects(
    sessionId: string,
    soundName: string,
    oscillator: OscillatorNode,
    _gainNode: GainNode,
    context: AudioContext,
    startTime: number,
    soundDef: SoundData
  ): void {
    switch (soundName) {
      case 'siren':
        // 频率扫描
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
        oscillator.frequency.exponentialRampToValueAtTime(soundDef.frequency * 2, startTime + soundDef.duration / 2);
        oscillator.frequency.exponentialRampToValueAtTime(soundDef.frequency, startTime + soundDef.duration);
        break;
        
      case 'bell':
        // 添加谐波
        this.addHarmonics(sessionId, soundDef.frequency, context, startTime, soundDef.duration);
        break;
        
      case 'rain':
        // 添加白噪声效果
        this.addWhiteNoise(sessionId, context, startTime, soundDef.duration, 0.1);
        break;
    }
  }

  private addHarmonics(sessionId: string, baseFreq: number, _context: AudioContext, startTime: number, duration: number): void {
    for (let i = 2; i <= 4; i++) {
      const harmonic = this.createTrackedNode(sessionId, (ctx) => ctx.createOscillator());
      const harmonicGain = this.createTrackedNode(sessionId, (ctx) => ctx.createGain());
      
      if (!harmonic || !harmonicGain || !this.masterGain) continue;
      
      harmonic.frequency.value = baseFreq * i;
      harmonic.type = 'sine';
      harmonicGain.gain.value = 1 / (i * 2); // 逐渐减弱谐波
      
      harmonic.connect(harmonicGain);
      harmonicGain.connect(this.masterGain);
      
      harmonic.start(startTime);
      harmonic.stop(startTime + duration);
    }
  }

  private addWhiteNoise(sessionId: string, context: AudioContext, startTime: number, duration: number, volume: number): void {
    // 创建白噪声缓冲区
    const bufferSize = context.sampleRate * duration;
    const buffer = context.createBuffer(1, bufferSize, context.sampleRate);
    const output = buffer.getChannelData(0);
    
    // 生成白噪声
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }
    
    const noise = this.createTrackedNode(sessionId, (ctx) => ctx.createBufferSource());
    const noiseGain = this.createTrackedNode(sessionId, (ctx) => ctx.createGain());
    
    if (!noise || !noiseGain || !this.masterGain) return;
    
    noise.buffer = buffer;
    noiseGain.gain.value = volume;
    
    noise.connect(noiseGain);
    noiseGain.connect(this.masterGain);
    
    noise.start(startTime);
  }

  // 改进的播放方法
  async play(soundName: string): Promise<void> {
    if (this.isPlaying) {
      this.stop();
    }
    
    try {
      const context = await this.ensureAudioContext();
      if (!context) return;

      this.isPlaying = true;
      await this.requestWakeLock();
      
      const playSound = () => {
        if (!this.isPlaying || !context) return;
        
        const startTime = context.currentTime;
        this.createComplexTone(soundName, context, startTime);
        
        // 循环播放
        const soundDef = SOUND_DEFINITIONS[soundName];
        if (soundDef && this.isPlaying) {
          this.loopTimeout = setTimeout(playSound, soundDef.duration * 1000);
        }
      };
      
      playSound();
      
    } catch (error) {
      console.error('Error playing sound:', error);
      this.isPlaying = false;
      this.releaseWakeLock();
    }
  }

  stop(): void {
    this.isPlaying = false;
    
    if (this.loopTimeout) {
      clearTimeout(this.loopTimeout);
      this.loopTimeout = null;
    }
    
    // 清理所有活动会话
    this.cleanupAllSessions();
    this.releaseWakeLock();
  }

  // 改进的清理方法
  private cleanupSession(sessionId: string): void {
    const tracker = this.activeNodes.get(sessionId);
    if (!tracker) return;
    
    // 断开并清理所有节点
    tracker.nodes.forEach(node => {
      try {
        if ('stop' in node && typeof node.stop === 'function') {
          (node as OscillatorNode | AudioBufferSourceNode).stop();
        }
        node.disconnect();
      } catch {
        // 节点可能已经停止或断开
      }
    });
    
    // 清理所有timeout
    tracker.timeouts.forEach(timeout => {
      clearTimeout(timeout);
    });
    
    this.activeNodes.delete(sessionId);
  }

  private cleanupAllSessions(): void {
    Array.from(this.activeNodes.keys()).forEach(sessionId => {
      this.cleanupSession(sessionId);
    });
  }

  // 定期清理过期的会话
  private startPeriodicCleanup(): void {
    this.nodeCleanupTimeout = setInterval(() => {
      const now = Date.now();
      const expiredSessions: string[] = [];
      
      this.activeNodes.forEach((tracker, sessionId) => {
        // 清理超过30秒的会话
        if (now - tracker.created > 30000) {
          expiredSessions.push(sessionId);
        }
      });
      
      expiredSessions.forEach(sessionId => {
        this.cleanupSession(sessionId);
      });
      
      this.lastCleanup = now;
    }, 5000); // 每5秒检查一次
  }

  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
    
    if (this.masterGain && this.audioContext) {
      this.masterGain.gain.setValueAtTime(this.volume, this.audioContext.currentTime);
    }
  }

  getVolume(): number {
    return this.volume;
  }

  isCurrentlyPlaying(): boolean {
    return this.isPlaying;
  }

  async testSound(soundName: string, duration: number = 3000): Promise<void> {
    await this.play(soundName);
    
    setTimeout(() => {
      if (this.isPlaying) {
        this.stop();
      }
    }, duration);
  }

  getSoundName(soundKey: string): string {
    return SOUND_DEFINITIONS[soundKey]?.name || soundKey;
  }

  getAllSounds(): Array<{ key: string; name: string }> {
    return ALARM_SOUNDS.map(key => ({
      key,
      name: this.getSoundName(key)
    }));
  }

  private async requestWakeLock(): Promise<void> {
    if ('wakeLock' in navigator) {
      try {
        this.wakeLock = await navigator.wakeLock.request('screen');
      } catch (error) {
        console.warn('Wake Lock request failed:', error);
      }
    }
  }

  private releaseWakeLock(): void {
    if (this.wakeLock) {
      this.wakeLock.release();
      this.wakeLock = null;
    }
  }

  // 获取性能统计
  getStats() {
    return {
      isPlaying: this.isPlaying,
      activeSessions: this.activeNodes.size,
      totalNodes: Array.from(this.activeNodes.values()).reduce((total, tracker) => total + tracker.nodes.size, 0),
      lastCleanup: this.lastCleanup,
      audioContextState: this.audioContext?.state || 'not-initialized',
      wakeLockActive: !!this.wakeLock
    };
  }

  // 增强的资源清理
  dispose(): void {
    this.stop();
    
    // 停止定期清理
    if (this.nodeCleanupTimeout) {
      clearInterval(this.nodeCleanupTimeout);
      this.nodeCleanupTimeout = null;
    }
    
    // 清理所有会话
    this.cleanupAllSessions();
    
    // 释放wake lock
    this.releaseWakeLock();
    
    // 断开主增益节点
    if (this.masterGain) {
      this.masterGain.disconnect();
      this.masterGain = null;
    }
    
    // 关闭音频上下文
    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close();
      this.audioContext = null;
    }
  }
}

// 导出增强版单例实例
export const audioEngine = new EnhancedAudioEngine();

// 页面卸载时的清理
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    audioEngine.dispose();
  });
  
  // 页面可见性变化时的处理
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && audioEngine.isCurrentlyPlaying()) {
      // 页面隐藏时继续播放，但可以考虑降低音量
      console.log('Page hidden while audio is playing');
    }
  });
}

export default EnhancedAudioEngine;