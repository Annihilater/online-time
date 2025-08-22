/**
 * Web Worker for high-precision time calculations
 * 使用 Web Worker 处理时间计算，避免主线程阻塞
 */

export interface TimeWorkerMessage {
  type: 'START' | 'STOP' | 'SYNC' | 'CHECK_ALARMS';
  data?: any;
}

export interface TimeWorkerResponse {
  type: 'TICK' | 'ALARM_TRIGGERED' | 'TIME_SYNC';
  data: {
    currentTime: number;
    triggeredAlarms?: string[];
  };
}

// Web Worker 脚本内容
const workerScript = `
let intervalId = null;
let alarms = [];
let isRunning = false;

function checkAlarms(currentTime) {
  const triggeredAlarms = [];
  
  alarms.forEach(alarm => {
    if (!alarm.isActive || alarm.isRinging) return;
    
    const alarmTime = new Date(alarm.time);
    const current = new Date(currentTime);
    
    // 精确比较到分钟
    alarmTime.setSeconds(0, 0);
    current.setSeconds(0, 0);
    
    if (alarmTime.getTime() === current.getTime()) {
      triggeredAlarms.push(alarm.id);
    }
  });
  
  return triggeredAlarms;
}

function tick() {
  const currentTime = Date.now();
  const triggeredAlarms = checkAlarms(currentTime);
  
  self.postMessage({
    type: 'TICK',
    data: {
      currentTime,
      triggeredAlarms: triggeredAlarms.length > 0 ? triggeredAlarms : undefined
    }
  });
  
  if (triggeredAlarms.length > 0) {
    self.postMessage({
      type: 'ALARM_TRIGGERED',
      data: {
        currentTime,
        triggeredAlarms
      }
    });
  }
}

self.onmessage = function(e) {
  const { type, data } = e.data;
  
  switch (type) {
    case 'START':
      if (!isRunning) {
        isRunning = true;
        intervalId = setInterval(tick, 1000);
        tick(); // 立即执行一次
      }
      break;
      
    case 'STOP':
      if (intervalId) {
        clearInterval(intervalId);
        intervalId = null;
        isRunning = false;
      }
      break;
      
    case 'SYNC':
      alarms = data.alarms || [];
      if (isRunning) {
        tick(); // 同步后立即检查
      }
      break;
      
    case 'CHECK_ALARMS':
      const currentTime = Date.now();
      const triggeredAlarms = checkAlarms(currentTime);
      self.postMessage({
        type: 'TIME_SYNC',
        data: {
          currentTime,
          triggeredAlarms
        }
      });
      break;
  }
};
`;

export class TimeWorkerManager {
  private worker: Worker | null = null;
  private callbacks: {
    onTick?: (time: number) => void;
    onAlarmTriggered?: (alarmIds: string[]) => void;
    onTimeSync?: (time: number) => void;
  } = {};

  constructor() {
    this.initWorker();
  }

  private initWorker() {
    try {
      // 创建 Web Worker
      const blob = new Blob([workerScript], { type: 'application/javascript' });
      const workerUrl = URL.createObjectURL(blob);
      this.worker = new Worker(workerUrl);

      this.worker.onmessage = (e: MessageEvent<TimeWorkerResponse>) => {
        const { type, data } = e.data;

        switch (type) {
          case 'TICK':
            this.callbacks.onTick?.(data.currentTime);
            if (data.triggeredAlarms) {
              this.callbacks.onAlarmTriggered?.(data.triggeredAlarms);
            }
            break;

          case 'ALARM_TRIGGERED':
            if (data.triggeredAlarms) {
              this.callbacks.onAlarmTriggered?.(data.triggeredAlarms);
            }
            break;

          case 'TIME_SYNC':
            this.callbacks.onTimeSync?.(data.currentTime);
            break;
        }
      };

      this.worker.onerror = (error) => {
        console.error('TimeWorker error:', error);
        this.fallbackToMainThread();
      };

      // 清理 Blob URL
      URL.revokeObjectURL(workerUrl);
    } catch (error) {
      console.warn('Failed to create TimeWorker, falling back to main thread:', error);
      this.fallbackToMainThread();
    }
  }

  private fallbackToMainThread() {
    // 如果 Web Worker 不可用，回退到主线程
    console.warn('Using main thread for time calculations');
    this.worker = null;
  }

  start() {
    if (this.worker) {
      this.worker.postMessage({ type: 'START' });
    } else {
      // 主线程回退逻辑将由 useTimer hook 处理
    }
  }

  stop() {
    if (this.worker) {
      this.worker.postMessage({ type: 'STOP' });
    }
  }

  syncAlarms(alarms: any[]) {
    if (this.worker) {
      this.worker.postMessage({
        type: 'SYNC',
        data: { alarms }
      });
    }
  }

  checkAlarms() {
    if (this.worker) {
      this.worker.postMessage({ type: 'CHECK_ALARMS' });
    }
  }

  setCallbacks(callbacks: {
    onTick?: (time: number) => void;
    onAlarmTriggered?: (alarmIds: string[]) => void;
    onTimeSync?: (time: number) => void;
  }) {
    this.callbacks = callbacks;
  }

  isWorkerAvailable(): boolean {
    return this.worker !== null;
  }

  dispose() {
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
  }
}

// 导出单例实例
export const timeWorkerManager = new TimeWorkerManager();

// 页面卸载时清理
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    timeWorkerManager.dispose();
  });
}