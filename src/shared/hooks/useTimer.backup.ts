import { useEffect, useCallback } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

class HighPrecisionTimer {
  private callbacks: Array<() => void> = [];
  private isRunning = false;
  private lastTime = 0;
  private animationFrameId: number | null = null;
  private wakeLock: WakeLockSentinel | null = null;

  start() {
    if (this.isRunning) return;
    
    this.isRunning = true;
    this.lastTime = Date.now();
    this.requestWakeLock();
    this.tick();
  }

  stop() {
    this.isRunning = false;
    
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
    
    this.releaseWakeLock();
  }

  addCallback(callback: () => void) {
    this.callbacks.push(callback);
  }

  removeCallback(callback: () => void) {
    const index = this.callbacks.indexOf(callback);
    if (index !== -1) {
      this.callbacks.splice(index, 1);
    }
  }

  private tick = () => {
    if (!this.isRunning) return;

    const now = Date.now();
    
    // 每秒执行一次回调
    if (now - this.lastTime >= 1000) {
      this.callbacks.forEach(callback => {
        try {
          callback();
        } catch (error) {
          console.error('Timer callback error:', error);
        }
      });
      this.lastTime = now;
    }

    this.animationFrameId = requestAnimationFrame(this.tick);
  };

  private async requestWakeLock() {
    if ('wakeLock' in navigator) {
      try {
        this.wakeLock = await navigator.wakeLock.request('screen');
        console.log('Wake lock activated');
        
        // 监听 wake lock 释放事件
        this.wakeLock.addEventListener('release', () => {
          console.log('Wake lock released');
        });
      } catch (error) {
        console.warn('Failed to request wake lock:', error);
      }
    }
  }

  private releaseWakeLock() {
    if (this.wakeLock) {
      this.wakeLock.release();
      this.wakeLock = null;
    }
  }
}

// 全局定时器实例
const globalTimer = new HighPrecisionTimer();

// 导出类以供测试使用
export { HighPrecisionTimer };

export const useTimer = () => {
  const updateCurrentTime = useAlarmStore(state => state.updateCurrentTime);
  const enableWakeLock = useAlarmStore(state => state.enableWakeLock);
  const isAlarmRinging = useAlarmStore(state => state.isAlarmRinging);
  
  // 创建稳定的回调引用
  const timerCallback = useCallback(() => {
    updateCurrentTime();
  }, [updateCurrentTime]);

  useEffect(() => {
    // 立即更新一次
    updateCurrentTime();
    
    // 添加到全局定时器
    globalTimer.addCallback(timerCallback);
    
    // 启动定时器
    globalTimer.start();

    return () => {
      // 移除回调
      globalTimer.removeCallback(timerCallback);
    };
  }, [updateCurrentTime, timerCallback]);

  // 处理 Wake Lock
  useEffect(() => {
    if (isAlarmRinging && enableWakeLock) {
      // 闹钟响起时会通过 globalTimer 自动处理 wake lock
      console.log('Alarm ringing, wake lock will be activated');
    }
  }, [isAlarmRinging, enableWakeLock]);

  // 页面可见性处理
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // 页面隐藏时，确保定时器继续运行
        console.log('Page hidden, maintaining timer');
      } else {
        // 页面显示时，立即同步时间
        updateCurrentTime();
        console.log('Page visible, syncing time');
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [updateCurrentTime]);

  // 窗口焦点处理
  useEffect(() => {
    const handleFocus = () => {
      // 窗口获得焦点时同步时间
      updateCurrentTime();
    };

    const handleBlur = () => {
      // 窗口失去焦点时的处理
      console.log('Window lost focus');
    };

    window.addEventListener('focus', handleFocus);
    window.addEventListener('blur', handleBlur);
    
    return () => {
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('blur', handleBlur);
    };
  }, [updateCurrentTime]);

  return {
    // 暴露一些有用的方法
    forceSync: updateCurrentTime,
    isWakeLockSupported: 'wakeLock' in navigator,
  };
};

// 导出全局定时器实例，供其他组件使用
export { globalTimer };

// 页面卸载时清理资源
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    globalTimer.stop();
  });
}