import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { addMinutes } from 'date-fns';
import { isSameTimeIgnoreSeconds, createSnoozeTime } from '@/shared/utils/timeUtils';
import { AudioUtils } from '@/shared/utils/audioUtils';

export interface Alarm {
  id: string;
  time: Date;
  isActive: boolean;
  sound: string;
  volume: number;
  label: string;
  isRinging: boolean;
  createdAt: Date;
  lastTriggered?: Date;
  snoozeCount: number;
  isRecurring: boolean;
  recurringDays?: number[]; // 0-6, 周日到周六
}

interface AlarmState {
  currentTime: Date;
  alarms: Alarm[];
  isAlarmRinging: boolean;
  selectedSound: string;
  volume: number;
  theme: 'light' | 'dark';
  is24HourFormat: boolean;
  snoozeMinutes: number;
  enableNotifications: boolean;
  enableWakeLock: boolean;
  
  // Actions
  updateCurrentTime: () => void;
  addAlarm: (time: Date, label?: string, options?: Partial<Alarm>) => void;
  removeAlarm: (id: string) => void;
  toggleAlarm: (id: string) => void;
  setAlarmRinging: (id: string, ringing: boolean) => void;
  stopAllAlarms: () => void;
  setSound: (sound: string) => void;
  setVolume: (volume: number) => void;
  setTheme: (theme: 'light' | 'dark') => void;
  setTimeFormat: (is24Hour: boolean) => void;
  setSnoozeMinutes: (minutes: number) => void;
  setEnableNotifications: (enable: boolean) => void;
  setEnableWakeLock: (enable: boolean) => void;
  
  // Settings update
  updateSettings: (settings: Partial<{
    theme: 'light' | 'dark';
    volume: number;
    selectedSound: string;
    is24HourFormat: boolean;
    enableNotifications: boolean;
    enableWakeLock: boolean;
    snoozeMinutes: number;
  }>) => void;
  
  // Alarm management
  snoozeAlarm: (id: string) => void;
  duplicateAlarm: (id: string) => void;
  editAlarm: (id: string, updates: Partial<Alarm>) => void;
  clearExpiredAlarms: () => void;
  
  // Quick alarm functions
  addQuickAlarm: (minutes: number) => void;
  addPresetAlarm: (hour: number, minute: number, label: string) => void;
  
  // Persistence
  loadFromStorage: () => void;
  resetToDefaults: () => void;
}

const ALARM_SOUNDS = [
  'clock',
  'rooster',
  'siren',
  'rain',
  'whitenoise',
];

const generateId = () => Math.random().toString(36).substr(2, 9);

const initialState = {
  currentTime: new Date(),
  alarms: [],
  isAlarmRinging: false,
  selectedSound: 'clock',
  volume: 0.7,
  theme: 'light' as 'light' | 'dark',
  is24HourFormat: false,
  snoozeMinutes: 10,
  enableNotifications: true,
  enableWakeLock: true,
};

export const useAlarmStore = create<AlarmState>()(persist((set, get) => ({
  ...initialState,

  updateCurrentTime: () => {
    const now = new Date();
    const { alarms, enableNotifications } = get();
    
    // 检查哪些闹钟应该响起
    let hasRingingAlarm = false;
    const updatedAlarms = alarms.map(alarm => {
      if (alarm.isActive && !alarm.isRinging) {
        if (isSameTimeIgnoreSeconds(alarm.time, now)) {
          hasRingingAlarm = true;
          
          // 显示浏览器通知
          if (enableNotifications) {
            AudioUtils.showNotification('闹钟响了!', {
              body: alarm.label || `闹钟时间: ${alarm.time.toLocaleTimeString()}`,
              tag: `alarm-${alarm.id}`,
              requireInteraction: true,
            });
          }
          
          return { 
            ...alarm, 
            isRinging: true,
            lastTriggered: now
          };
        }
      }
      return alarm;
    });
    
    set({
      currentTime: now,
      alarms: updatedAlarms,
      isAlarmRinging: hasRingingAlarm || get().isAlarmRinging
    });
  },

  addAlarm: (time: Date, label = '', options = {}) => {
    const newAlarm: Alarm = {
      id: generateId(),
      time,
      isActive: true,
      sound: get().selectedSound,
      volume: get().volume,
      label,
      isRinging: false,
      createdAt: new Date(),
      snoozeCount: 0,
      isRecurring: false,
      ...options,
    };
    
    set(state => ({
      alarms: [...state.alarms, newAlarm].sort((a, b) => a.time.getTime() - b.time.getTime())
    }));
  },

  removeAlarm: (id: string) => {
    set(state => ({
      alarms: state.alarms.filter(alarm => alarm.id !== id)
    }));
  },

  toggleAlarm: (id: string) => {
    set(state => ({
      alarms: state.alarms.map(alarm =>
        alarm.id === id ? { ...alarm, isActive: !alarm.isActive, isRinging: false } : alarm
      )
    }));
  },

  setAlarmRinging: (id: string, ringing: boolean) => {
    set(state => {
      const updatedAlarms = state.alarms.map(alarm =>
        alarm.id === id ? { ...alarm, isRinging: ringing } : alarm
      );
      
      const stillRinging = updatedAlarms.some(alarm => alarm.isRinging);
      
      return {
        alarms: updatedAlarms,
        isAlarmRinging: stillRinging
      };
    });
  },

  stopAllAlarms: () => {
    set(state => ({
      alarms: state.alarms.map(alarm => ({ ...alarm, isRinging: false })),
      isAlarmRinging: false
    }));
  },

  setSound: (sound: string) => {
    set({ selectedSound: sound });
  },

  setVolume: (volume: number) => {
    set({ volume });
  },

  setTheme: (theme: 'light' | 'dark') => {
    set({ theme });
    document.documentElement.setAttribute('data-theme', theme);
  },

  setTimeFormat: (is24Hour: boolean) => {
    set({ is24HourFormat: is24Hour });
  },

  setSnoozeMinutes: (minutes: number) => {
    set({ snoozeMinutes: Math.max(1, Math.min(60, minutes)) });
  },

  setEnableNotifications: async (enable: boolean) => {
    if (enable) {
      const permission = await AudioUtils.requestNotificationPermission();
      set({ enableNotifications: permission === 'granted' });
    } else {
      set({ enableNotifications: false });
    }
  },

  setEnableWakeLock: (enable: boolean) => {
    set({ enableWakeLock: enable });
  },

  // 通用设置更新方法
  updateSettings: (settings: Partial<{
    theme: 'light' | 'dark';
    volume: number;
    selectedSound: string;
    is24HourFormat: boolean;
    enableNotifications: boolean;
    enableWakeLock: boolean;
    snoozeMinutes: number;
  }>) => {
    const updates: any = {};
    
    if (settings.theme) {
      updates.theme = settings.theme;
      document.documentElement.setAttribute('data-theme', settings.theme);
    }
    if (settings.volume !== undefined) updates.volume = settings.volume;
    if (settings.selectedSound) updates.selectedSound = settings.selectedSound;
    if (settings.is24HourFormat !== undefined) updates.is24HourFormat = settings.is24HourFormat;
    if (settings.enableNotifications !== undefined) updates.enableNotifications = settings.enableNotifications;
    if (settings.enableWakeLock !== undefined) updates.enableWakeLock = settings.enableWakeLock;
    if (settings.snoozeMinutes !== undefined) updates.snoozeMinutes = Math.max(1, Math.min(60, settings.snoozeMinutes));
    
    set(updates);
  },

  snoozeAlarm: (id: string) => {
    const { alarms, snoozeMinutes } = get();
    const alarm = alarms.find(a => a.id === id);
    if (!alarm) return;
    
    const snoozeTime = createSnoozeTime(snoozeMinutes);
    
    set(state => ({
      alarms: state.alarms.map(a => 
        a.id === id 
          ? { 
              ...a, 
              time: snoozeTime,
              isRinging: false,
              snoozeCount: a.snoozeCount + 1
            }
          : a
      ).sort((a, b) => a.time.getTime() - b.time.getTime()),
      isAlarmRinging: state.alarms.filter(a => a.id !== id).some(a => a.isRinging)
    }));
  },

  duplicateAlarm: (id: string) => {
    const { alarms, addAlarm } = get();
    const alarm = alarms.find(a => a.id === id);
    if (!alarm) return;
    
    const duplicatedTime = new Date(alarm.time);
    duplicatedTime.setDate(duplicatedTime.getDate() + 1); // 复制到明天同一时间
    
    addAlarm(duplicatedTime, `${alarm.label} (复制)`, {
      sound: alarm.sound,
      volume: alarm.volume,
      isRecurring: alarm.isRecurring,
      recurringDays: alarm.recurringDays
    });
  },

  editAlarm: (id: string, updates: Partial<Alarm>) => {
    set(state => ({
      alarms: state.alarms.map(alarm =>
        alarm.id === id ? { ...alarm, ...updates } : alarm
      ).sort((a, b) => a.time.getTime() - b.time.getTime())
    }));
  },

  clearExpiredAlarms: () => {
    const now = new Date();
    set(state => ({
      alarms: state.alarms.filter(alarm => {
        // 保留正在响的、未来的或重复的闹钟
        return alarm.isRinging || 
               alarm.time > now || 
               alarm.isRecurring;
      })
    }));
  },

  addQuickAlarm: (minutes: number) => {
    const alarmTime = addMinutes(new Date(), minutes);
    get().addAlarm(alarmTime, `${minutes} 分钟后`);
  },

  addPresetAlarm: (hour: number, minute: number, label: string) => {
    const now = new Date();
    const alarmTime = new Date(now);
    alarmTime.setHours(hour, minute, 0, 0);
    
    // 如果时间已过，设置为明天
    if (alarmTime <= now) {
      alarmTime.setDate(alarmTime.getDate() + 1);
    }
    
    get().addAlarm(alarmTime, label);
  },

  loadFromStorage: () => {
    // 由 persist 中间件自动处理
  },

  resetToDefaults: () => {
    set(initialState);
    localStorage.removeItem('alarm-storage');
  },
}), {
  name: 'alarm-storage',
  partialize: (state) => ({
    alarms: state.alarms.map(alarm => ({
      ...alarm,
      isRinging: false, // 不保存响铃状态
    })),
    selectedSound: state.selectedSound,
    volume: state.volume,
    theme: state.theme,
    is24HourFormat: state.is24HourFormat,
    snoozeMinutes: state.snoozeMinutes,
    enableNotifications: state.enableNotifications,
    enableWakeLock: state.enableWakeLock,
  }),
  onRehydrateStorage: () => (state) => {
    if (state) {
      // 恢复后清理过期闹钟
      state.clearExpiredAlarms();
      
      // 设置主题
      document.documentElement.setAttribute('data-theme', state.theme);
      
      // 请求通知权限
      if (state.enableNotifications) {
        AudioUtils.requestNotificationPermission();
      }
    }
  },
}));

export const PRESET_TIMES = [
  { label: '05:00', hour: 5, minute: 0 },
  { label: '05:30', hour: 5, minute: 30 },
  { label: '06:00', hour: 6, minute: 0 },
  { label: '06:30', hour: 6, minute: 30 },
  { label: '07:00', hour: 7, minute: 0 },
  { label: '07:30', hour: 7, minute: 30 },
  { label: '08:00', hour: 8, minute: 0 },
  { label: '08:30', hour: 8, minute: 30 },
];

export { ALARM_SOUNDS };