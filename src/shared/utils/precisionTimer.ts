/**
 * 高精度定时器 - 优化版本
 * 目标：确保定时器精度在±5ms以内，减少时间漂移
 */

interface TimerCallback {
  id: string;
  callback: () => void;
  interval: number;
  lastExecution: number;
  enabled: boolean;
}

export class PrecisionTimer {
  private callbacks: Map<string, TimerCallback> = new Map();
  private isRunning = false;
  private animationFrameId: number | null = null;
  private workerTimer: Worker | null = null;
  private lastTime = 0;
  private drift = 0;
  private performanceStartTime = performance.now();
  
  // 配置选项
  private config = {
    targetInterval: 1000, // 目标间隔 1000ms
    maxDrift: 5,         // 最大允许漂移 5ms
    correctionThreshold: 10, // 漂移纠正阈值
    useBrowserTimer: false,  // 是否使用浏览器定时器回退
  };

  constructor(options?: Partial<typeof PrecisionTimer.prototype.config>) {
    if (options) {
      this.config = { ...this.config, ...options };
    }
    this.initWorkerTimer();
  }

  private initWorkerTimer() {
    try {
      // 创建高精度计时器Web Worker
      const workerCode = `
        let intervalId = null;
        let targetInterval = 1000;
        let lastTime = Date.now();
        
        function highPrecisionTick() {
          const currentTime = Date.now();
          const elapsed = currentTime - lastTime;
          
          // 计算下一次执行的精确时间
          const drift = elapsed - targetInterval;
          const nextInterval = Math.max(0, targetInterval - drift);
          
          self.postMessage({
            type: 'TICK',
            time: currentTime,
            elapsed: elapsed,
            drift: drift
          });
          
          lastTime = currentTime;
          setTimeout(highPrecisionTick, nextInterval);
        }
        
        self.onmessage = function(e) {
          const { type, data } = e.data;
          
          if (type === 'START') {
            targetInterval = data?.interval || 1000;
            lastTime = Date.now();
            highPrecisionTick();
          } else if (type === 'STOP') {
            // Worker 会在主线程销毁时自动停止
          }
        };
      `;

      const blob = new Blob([workerCode], { type: 'application/javascript' });
      const workerUrl = URL.createObjectURL(blob);
      this.workerTimer = new Worker(workerUrl);

      this.workerTimer.onmessage = (e) => {
        const { time, drift } = e.data;
        this.handleTick(time, drift);
      };

      this.workerTimer.onerror = () => {
        console.warn('PrecisionTimer: Worker failed, falling back to main thread');
        this.workerTimer = null;
        this.config.useBrowserTimer = true;
      };

      URL.revokeObjectURL(workerUrl);
    } catch {
      console.warn('PrecisionTimer: Worker not available, using main thread');
      this.config.useBrowserTimer = true;
    }
  }

  private handleTick(currentTime: number, workerDrift: number = 0) {
    // 更新漂移统计
    this.drift = workerDrift;
    
    // 执行所有启用的回调
    this.callbacks.forEach((timerCallback) => {
      if (!timerCallback.enabled) return;
      
      const timeSinceLastExecution = currentTime - timerCallback.lastExecution;
      
      if (timeSinceLastExecution >= timerCallback.interval - this.config.maxDrift) {
        try {
          timerCallback.callback();
          timerCallback.lastExecution = currentTime;
        } catch (error) {
          console.error(`PrecisionTimer callback error for ${timerCallback.id}:`, error);
        }
      }
    });
  }

  private mainThreadTick = () => {
    if (!this.isRunning) return;

    const currentTime = performance.now();
    const elapsed = currentTime - this.performanceStartTime;
    const expectedTime = Math.floor(elapsed / this.config.targetInterval) * this.config.targetInterval;
    const drift = elapsed - expectedTime;

    // 如果漂移太大，进行时间校正
    if (Math.abs(drift) > this.config.correctionThreshold) {
      this.performanceStartTime = currentTime - (elapsed - drift);
    }

    this.handleTick(Date.now(), drift);

    // 计算下一次执行的精确时间
    const nextTickDelay = Math.max(0, this.config.targetInterval - (currentTime - this.lastTime));
    this.lastTime = currentTime;

    if (this.config.useBrowserTimer) {
      // 使用 setTimeout 而不是 requestAnimationFrame 来获得更好的精度
      setTimeout(this.mainThreadTick, nextTickDelay);
    } else {
      this.animationFrameId = requestAnimationFrame(this.mainThreadTick);
    }
  };

  addTimer(id: string, callback: () => void, interval: number = 1000): void {
    const now = Date.now();
    this.callbacks.set(id, {
      id,
      callback,
      interval,
      lastExecution: now,
      enabled: true
    });
  }

  removeTimer(id: string): void {
    this.callbacks.delete(id);
  }

  enableTimer(id: string): void {
    const timer = this.callbacks.get(id);
    if (timer) {
      timer.enabled = true;
      timer.lastExecution = Date.now(); // 重置执行时间
    }
  }

  disableTimer(id: string): void {
    const timer = this.callbacks.get(id);
    if (timer) {
      timer.enabled = false;
    }
  }

  start(): void {
    if (this.isRunning) return;

    this.isRunning = true;
    this.lastTime = performance.now();
    this.performanceStartTime = this.lastTime;

    if (this.workerTimer) {
      // 使用 Worker 计时器
      this.workerTimer.postMessage({ 
        type: 'START', 
        data: { interval: this.config.targetInterval } 
      });
    } else {
      // 使用主线程计时器
      this.mainThreadTick();
    }
  }

  stop(): void {
    this.isRunning = false;

    if (this.workerTimer) {
      this.workerTimer.postMessage({ type: 'STOP' });
    }

    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  // 获取性能统计信息
  getStats() {
    return {
      isRunning: this.isRunning,
      activeTimers: Array.from(this.callbacks.values()).filter(t => t.enabled).length,
      totalTimers: this.callbacks.size,
      drift: this.drift,
      usingWorker: this.workerTimer !== null,
      config: this.config
    };
  }

  // 强制同步所有计时器
  forceSync(): void {
    const now = Date.now();
    this.callbacks.forEach((timer) => {
      if (timer.enabled) {
        timer.lastExecution = now - timer.interval; // 强制下次立即执行
      }
    });
  }

  dispose(): void {
    this.stop();
    this.callbacks.clear();
    
    if (this.workerTimer) {
      this.workerTimer.terminate();
      this.workerTimer = null;
    }
  }
}

// 创建全局精度定时器实例
export const globalPrecisionTimer = new PrecisionTimer({
  targetInterval: 1000,
  maxDrift: 5,
  correctionThreshold: 10
});

// 页面卸载时清理资源
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    globalPrecisionTimer.dispose();
  });
  
  // 页面可见性变化时进行时间同步
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      globalPrecisionTimer.forceSync();
    }
  });
  
  // 窗口获得焦点时同步
  window.addEventListener('focus', () => {
    globalPrecisionTimer.forceSync();
  });
}

export default PrecisionTimer;