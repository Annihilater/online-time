import { useEffect, useRef, useCallback } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { audioEngine, AudioUtils } from '@/shared/utils/audioUtils';

export const useAlarmSound = () => {
  const { 
    alarms, 
    isAlarmRinging, 
    volume,
    enableNotifications,
    setAlarmRinging,
    stopAllAlarms,
    snoozeAlarm 
  } = useAlarmStore();
  
  const lastRingingState = useRef(false);
  const activeAlarmIds = useRef<Set<string>>(new Set());
  const notificationRefs = useRef<Map<string, Notification>>(new Map());

  useEffect(() => {
    audioEngine.setVolume(volume);
  }, [volume]);

  useEffect(() => {
    const ringingAlarms = alarms.filter(alarm => alarm.isRinging);
    const currentRingingIds = new Set(ringingAlarms.map(alarm => alarm.id));
    
    // 处理新开始响铃的闹钟
    ringingAlarms.forEach(alarm => {
      if (!activeAlarmIds.current.has(alarm.id)) {
        // 闹钟开始响铃
        activeAlarmIds.current.add(alarm.id);
        
        // 播放声音（如果是第一个响铃的闹钟）
        if (activeAlarmIds.current.size === 1) {
          audioEngine.play(alarm.sound).catch(error => {
            console.error('Failed to play alarm sound:', error);
          });
        }
        
        // 显示浏览器通知
        if (enableNotifications) {
          const notification = AudioUtils.showNotification('闹钟响了!', {
            body: alarm.label || `闹钟时间: ${alarm.time.toLocaleTimeString()}`,
            tag: `alarm-${alarm.id}`,
            requireInteraction: true,
            // actions: [
            //   { action: 'stop', title: '停止' },
            //   { action: 'snooze', title: '贪睡' }
            // ] // Not supported in all browsers
          });
          
          if (notification) {
            notificationRefs.current.set(alarm.id, notification);
            
            // 处理通知点击事件
            notification.onclick = () => {
              stopAlarm(alarm.id);
              notification.close();
            };
          }
        }
      }
    });
    
    // 处理停止响铃的闹钟
    activeAlarmIds.current.forEach(alarmId => {
      if (!currentRingingIds.has(alarmId)) {
        activeAlarmIds.current.delete(alarmId);
        
        // 关闭对应的通知
        const notification = notificationRefs.current.get(alarmId);
        if (notification) {
          notification.close();
          notificationRefs.current.delete(alarmId);
        }
      }
    });
    
    // 如果没有闹钟在响，停止音频
    if (currentRingingIds.size === 0 && activeAlarmIds.current.size === 0) {
      audioEngine.stop();
      lastRingingState.current = false;
    } else {
      lastRingingState.current = true;
    }
    
    return () => {
      // 清理通知 - 复制ref值避免闭包问题
      const currentNotifications = notificationRefs.current;
      currentNotifications.forEach(notification => {
        notification.close();
      });
      currentNotifications.clear();
    };
  }, [alarms, enableNotifications]);

  // 请求通知权限
  useEffect(() => {
    if (enableNotifications) {
      AudioUtils.requestNotificationPermission();
    }
  }, [enableNotifications]);

  const stopAlarm = useCallback((alarmId?: string) => {
    if (alarmId) {
      setAlarmRinging(alarmId, false);
      
      // 从活跃闹钟列表中移除
      activeAlarmIds.current.delete(alarmId);
      
      // 关闭通知
      const notification = notificationRefs.current.get(alarmId);
      if (notification) {
        notification.close();
        notificationRefs.current.delete(alarmId);
      }
      
      // 如果没有其他闹钟在响，停止音频
      if (activeAlarmIds.current.size === 0) {
        audioEngine.stop();
      }
    } else {
      stopAllAlarms();
      
      // 清理所有状态
      activeAlarmIds.current.clear();
      notificationRefs.current.forEach(notification => notification.close());
      notificationRefs.current.clear();
      audioEngine.stop();
    }
  }, [setAlarmRinging, stopAllAlarms]);

  const snooze = useCallback((alarmId: string) => {
    snoozeAlarm(alarmId);
    
    // 清理当前闹钟的状态
    activeAlarmIds.current.delete(alarmId);
    const notification = notificationRefs.current.get(alarmId);
    if (notification) {
      notification.close();
      notificationRefs.current.delete(alarmId);
    }
    
    // 如果没有其他闹钟在响，停止音频
    if (activeAlarmIds.current.size === 0) {
      audioEngine.stop();
    }
  }, [snoozeAlarm]);

  const testSound = useCallback(async (soundName: string) => {
    try {
      await audioEngine.testSound(soundName, 3000);
    } catch (error) {
      console.error('Failed to test sound:', error);
    }
  }, []);

  const getCurrentVolume = useCallback(() => {
    return audioEngine.getVolume();
  }, []);

  const isAudioPlaying = useCallback(() => {
    return audioEngine.isCurrentlyPlaying();
  }, []);

  // 页面卸载时清理资源
  useEffect(() => {
    const handleBeforeUnload = () => {
      audioEngine.stop();
      notificationRefs.current.forEach(notification => notification.close());
    };
    
    window.addEventListener('beforeunload', handleBeforeUnload);
    
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
      handleBeforeUnload();
    };
  }, []);

  return {
    isRinging: isAlarmRinging,
    ringingAlarms: alarms.filter(alarm => alarm.isRinging),
    activeAlarmCount: activeAlarmIds.current.size,
    stopAlarm,
    snooze,
    testSound,
    getCurrentVolume,
    isAudioPlaying,
    isNotificationSupported: AudioUtils.isNotificationSupported(),
    isWakeLockSupported: AudioUtils.isWakeLockSupported(),
  };
};