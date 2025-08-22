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

// 定义11种声音的参数
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
  nuclear: {
    name: '核弹',
    frequency: 200,
    type: 'sawtooth',
    duration: 3.0,
    envelope: { attack: 0.2, decay: 0.5, sustain: 0.6, release: 1.0 }
  },
  alien: {
    name: '外星人',
    frequency: 1200,
    type: 'square',
    duration: 1.8,
    envelope: { attack: 0.01, decay: 0.2, sustain: 0.5, release: 0.4 }
  },
  rain: {
    name: '雨声',
    frequency: 300,
    type: 'sine',
    duration: 4.0,
    envelope: { attack: 0.5, decay: 0.3, sustain: 0.8, release: 2.0 }
  },
  bomb: {
    name: '炸弹',
    frequency: 80,
    type: 'sawtooth',
    duration: 2.5,
    envelope: { attack: 0.01, decay: 0.8, sustain: 0.2, release: 1.5 }
  },
  mystery: {
    name: '神秘之声',
    frequency: 666,
    type: 'triangle',
    duration: 2.2,
    envelope: { attack: 0.3, decay: 0.4, sustain: 0.6, release: 0.8 }
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

export class AdvancedAudioEngine {
  private audioContext: AudioContext | null = null;
  private currentOscillator: OscillatorNode | null = null;
  private currentGain: GainNode | null = null;
  private volume: number = 0.7;
  private isPlaying: boolean = false;
  private loopTimeout: NodeJS.Timeout | null = null;
  private wakeLock: WakeLockSentinel | null = null;
  
  constructor() {
    this.initializeAudioContext();
  }

  private async initializeAudioContext(): Promise<void> {
    try {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      
      // Resume audio context if suspended (required by some browsers)
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

  private createComplexTone(soundName: string, context: AudioContext, startTime: number): void {
    const soundDef = SOUND_DEFINITIONS[soundName];
    if (!soundDef) return;

    // Create oscillator and gain
    const oscillator = context.createOscillator();
    const gainNode = context.createGain();
    
    // Connect nodes
    oscillator.connect(gainNode);
    gainNode.connect(context.destination);
    
    // Configure oscillator
    oscillator.type = soundDef.type;
    
    // Add frequency modulation for more interesting sounds
    switch (soundName) {
      case 'siren':
        // Frequency sweep for siren
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
        oscillator.frequency.exponentialRampToValueAtTime(soundDef.frequency * 2, startTime + soundDef.duration / 2);
        oscillator.frequency.exponentialRampToValueAtTime(soundDef.frequency, startTime + soundDef.duration);
        break;
        
      case 'alien':
        // Vibrato effect
        const lfo = context.createOscillator();
        const lfoGain = context.createGain();
        lfo.frequency.value = 6; // 6Hz vibrato
        lfoGain.gain.value = 50; // 50Hz depth
        lfo.connect(lfoGain);
        lfoGain.connect(oscillator.frequency);
        lfo.start(startTime);
        lfo.stop(startTime + soundDef.duration);
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
        break;
        
      case 'mystery':
        // Tremolo effect
        const tremolo = context.createOscillator();
        const tremoloGain = context.createGain();
        tremolo.frequency.value = 4;
        tremoloGain.gain.value = 0.3;
        tremolo.connect(tremoloGain);
        tremoloGain.connect(gainNode.gain);
        tremolo.start(startTime);
        tremolo.stop(startTime + soundDef.duration);
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
        break;
        
      case 'bell':
        // Add harmonics for bell sound
        const harmonic1 = context.createOscillator();
        const harmonic2 = context.createOscillator();
        const harmonic1Gain = context.createGain();
        const harmonic2Gain = context.createGain();
        
        harmonic1.frequency.value = soundDef.frequency * 2;
        harmonic2.frequency.value = soundDef.frequency * 3;
        harmonic1Gain.gain.value = 0.3;
        harmonic2Gain.gain.value = 0.1;
        
        harmonic1.connect(harmonic1Gain);
        harmonic2.connect(harmonic2Gain);
        harmonic1Gain.connect(context.destination);
        harmonic2Gain.connect(context.destination);
        
        harmonic1.start(startTime);
        harmonic2.start(startTime);
        harmonic1.stop(startTime + soundDef.duration);
        harmonic2.stop(startTime + soundDef.duration);
        
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
        break;
        
      case 'whitenoise':
        // Create white noise using buffer
        const bufferSize = context.sampleRate * soundDef.duration;
        const buffer = context.createBuffer(1, bufferSize, context.sampleRate);
        const output = buffer.getChannelData(0);
        
        for (let i = 0; i < bufferSize; i++) {
          output[i] = Math.random() * 2 - 1;
        }
        
        const noise = context.createBufferSource();
        noise.buffer = buffer;
        noise.connect(gainNode);
        noise.start(startTime);
        
        // Don't start the oscillator for white noise
        oscillator.disconnect();
        break;
        
      default:
        oscillator.frequency.setValueAtTime(soundDef.frequency, startTime);
    }
    
    // Apply envelope
    if (soundDef.envelope && soundName !== 'whitenoise') {
      const { attack, decay, sustain, release } = soundDef.envelope;
      const sustainTime = soundDef.duration - attack - decay - release;
      
      gainNode.gain.setValueAtTime(0, startTime);
      gainNode.gain.linearRampToValueAtTime(this.volume, startTime + attack);
      gainNode.gain.linearRampToValueAtTime(this.volume * sustain, startTime + attack + decay);
      gainNode.gain.setValueAtTime(this.volume * sustain, startTime + attack + decay + sustainTime);
      gainNode.gain.linearRampToValueAtTime(0, startTime + soundDef.duration);
    } else {
      gainNode.gain.setValueAtTime(this.volume, startTime);
    }
    
    // Start and stop oscillator
    if (soundName !== 'whitenoise') {
      oscillator.start(startTime);
      oscillator.stop(startTime + soundDef.duration);
    }
    
    this.currentOscillator = oscillator;
    this.currentGain = gainNode;
  }

  async play(soundName: string): Promise<void> {
    if (this.isPlaying) {
      this.stop();
    }
    
    try {
      const context = await this.ensureAudioContext();
      this.isPlaying = true;
      
      // Request wake lock to prevent screen from sleeping
      await this.requestWakeLock();
      
      const playSound = () => {
        if (!this.isPlaying) return;
        
        const startTime = context.currentTime;
        this.createComplexTone(soundName, context, startTime);
        
        const soundDef = SOUND_DEFINITIONS[soundName];
        const duration = soundDef ? soundDef.duration : 1.0;
        
        // Schedule next iteration
        this.loopTimeout = setTimeout(() => {
          if (this.isPlaying) {
            playSound();
          }
        }, duration * 1000);
      };
      
      playSound();
      
    } catch (error) {
      console.error('Error playing sound:', error);
      this.isPlaying = false;
    }
  }

  stop(): void {
    this.isPlaying = false;
    
    if (this.loopTimeout) {
      clearTimeout(this.loopTimeout);
      this.loopTimeout = null;
    }
    
    if (this.currentOscillator) {
      try {
        this.currentOscillator.stop();
      } catch (error) {
        // Oscillator might already be stopped
      }
      this.currentOscillator = null;
    }
    
    if (this.currentGain) {
      this.currentGain.disconnect();
      this.currentGain = null;
    }
    
    this.releaseWakeLock();
  }

  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
    
    if (this.currentGain) {
      this.currentGain.gain.setValueAtTime(this.volume, this.audioContext?.currentTime || 0);
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

  // Clean up resources
  dispose(): void {
    this.stop();
    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close();
    }
  }
}

// Export singleton instance
export const audioEngine = new AdvancedAudioEngine();

// Cleanup on page unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    audioEngine.dispose();
  });
}