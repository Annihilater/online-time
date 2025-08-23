import { useEffect, useCallback, useRef } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { globalPrecisionTimer } from '@/shared/utils/precisionTimer';

export const useTimer = () => {
  const updateCurrentTime = useAlarmStore(state => state.updateCurrentTime);
  const enableWakeLock = useAlarmStore(state => state.enableWakeLock);
  const isAlarmRinging = useAlarmStore(state => state.isAlarmRinging);
  
  const timerIdRef = useRef<string>(`timer-${Math.random().toString(36).substr(2, 9)}`);
  const wakeLockRef = useRef<WakeLockSentinel | null>(null);

  // 创建稳定的回调引用
  const timerCallback = useCallback(() => {
    updateCurrentTime();
  }, [updateCurrentTime]);

  // 主定时器逻辑
  useEffect(() => {
    const timerId = timerIdRef.current;
    
    // 立即更新一次
    updateCurrentTime();
    
    // 添加高精度定时器
    globalPrecisionTimer.addTimer(timerId, timerCallback, 1000);
    
    // 启动全局定时器（如果尚未启动）
    globalPrecisionTimer.start();

    return () => {
      // 组件卸载时移除定时器
      globalPrecisionTimer.removeTimer(timerId);
    };
  }, [updateCurrentTime, timerCallback]);

  // Wake Lock 管理
  const requestWakeLock = useCallback(async () => {
    if (!enableWakeLock || !('wakeLock' in navigator)) return;
    
    try {
      // 释放旧的 wake lock
      if (wakeLockRef.current) {
        wakeLockRef.current.release();
      }
      
      wakeLockRef.current = await navigator.wakeLock.request('screen');
      console.log('Wake lock activated for alarm');
      
      // 监听 wake lock 释放事件
      wakeLockRef.current.addEventListener('release', () => {
        console.log('Wake lock released');
        wakeLockRef.current = null;
      });
    } catch (error) {
      console.warn('Failed to request wake lock:', error);
    }
  }, [enableWakeLock]);

  const releaseWakeLock = useCallback(() => {
    if (wakeLockRef.current) {
      wakeLockRef.current.release();
      wakeLockRef.current = null;
    }
  }, []);

  // 闹钟状态变化时管理 Wake Lock
  useEffect(() => {
    if (isAlarmRinging && enableWakeLock) {
      requestWakeLock();
    } else if (!isAlarmRinging) {
      releaseWakeLock();
    }
  }, [isAlarmRinging, enableWakeLock, requestWakeLock, releaseWakeLock]);

  // 页面可见性处理
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // 页面隐藏时确保定时器继续运行
        console.log('Page hidden, maintaining precision timer');
      } else {
        // 页面显示时，立即同步时间并强制更新所有定时器
        updateCurrentTime();
        globalPrecisionTimer.forceSync();
        console.log('Page visible, forcing timer sync');
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
      // 窗口获得焦点时同步时间和定时器
      updateCurrentTime();
      globalPrecisionTimer.forceSync();
    };

    const handleBlur = () => {
      // 窗口失去焦点时的处理
      console.log('Window lost focus, timer continues in background');
    };

    window.addEventListener('focus', handleFocus);
    window.addEventListener('blur', handleBlur);
    
    return () => {
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('blur', handleBlur);
    };
  }, [updateCurrentTime]);

  // 组件卸载时清理 Wake Lock
  useEffect(() => {
    return () => {
      releaseWakeLock();
    };
  }, [releaseWakeLock]);

  return {
    // 暴露有用的方法和状态
    forceSync: useCallback(() => {
      updateCurrentTime();
      globalPrecisionTimer.forceSync();
    }, [updateCurrentTime]),
    
    isWakeLockSupported: 'wakeLock' in navigator,
    
    isWakeLockActive: !!wakeLockRef.current,
    
    getTimerStats: () => globalPrecisionTimer.getStats(),
    
    // 手动控制定时器
    pauseTimer: useCallback(() => {
      globalPrecisionTimer.disableTimer(timerIdRef.current);
    }, []),
    
    resumeTimer: useCallback(() => {
      globalPrecisionTimer.enableTimer(timerIdRef.current);
    }, []),
  };
};

// 导出精度定时器实例供其他模块使用
export { globalPrecisionTimer };

// 导出一个简单的定时器 hook，适用于简单的定时器需求
export const useSimpleTimer = (callback: () => void, interval: number = 1000, enabled: boolean = true) => {
  const timerIdRef = useRef<string>(`simple-timer-${Math.random().toString(36).substr(2, 9)}`);
  const callbackRef = useRef(callback);
  
  // 保持回调引用最新
  useEffect(() => {
    callbackRef.current = callback;
  }, [callback]);
  
  useEffect(() => {
    const timerId = timerIdRef.current;
    
    if (enabled) {
      globalPrecisionTimer.addTimer(timerId, () => callbackRef.current(), interval);
      globalPrecisionTimer.start();
    }
    
    return () => {
      globalPrecisionTimer.removeTimer(timerId);
    };
  }, [interval, enabled]);
  
  return {
    pause: () => globalPrecisionTimer.disableTimer(timerIdRef.current),
    resume: () => globalPrecisionTimer.enableTimer(timerIdRef.current),
    forceExecute: () => callbackRef.current(),
  };
};