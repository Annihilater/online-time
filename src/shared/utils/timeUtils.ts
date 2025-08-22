import { format, isToday, isTomorrow, differenceInMilliseconds, addMinutes } from 'date-fns';
import { zhCN } from 'date-fns/locale';

export const formatTime = (date: Date, is24Hour: boolean = false): string => {
  if (is24Hour) {
    return format(date, 'HH:mm');
  }
  return format(date, 'h:mm a', { locale: zhCN });
};

export const formatTimeWithSeconds = (date: Date, is24Hour: boolean = false): string => {
  if (is24Hour) {
    return format(date, 'HH:mm:ss');
  }
  return format(date, 'h:mm:ss a', { locale: zhCN });
};

export const formatDate = (date: Date): string => {
  return format(date, 'yyyy年M月d日 EEEE', { locale: zhCN });
};

export const formatAlarmTime = (date: Date): string => {
  if (isToday(date)) {
    return `今天 ${format(date, 'HH:mm')}`;
  } else if (isTomorrow(date)) {
    return `明天 ${format(date, 'HH:mm')}`;
  } else {
    return format(date, 'MM-dd HH:mm', { locale: zhCN });
  }
};

export const getTimeUntilAlarm = (alarmTime: Date): string => {
  return getDetailedTimeUntilAlarm(alarmTime).text;
};

export const createTimeFromInput = (timeString: string): Date => {
  const [hours, minutes] = timeString.split(':').map(Number);
  const now = new Date();
  const alarmTime = new Date(now);
  
  alarmTime.setHours(hours, minutes, 0, 0);
  
  // If the time has already passed today, set it for tomorrow
  if (alarmTime <= now) {
    alarmTime.setDate(alarmTime.getDate() + 1);
  }
  
  return alarmTime;
};

export const getGreeting = (): string => {
  const hour = new Date().getHours();
  
  if (hour < 6) return '深夜好';
  if (hour < 12) return '早上好';
  if (hour < 18) return '下午好';
  return '晚上好';
};

export const isAlarmTimeValid = (timeString: string): boolean => {
  const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
  return timeRegex.test(timeString);
};

/**
 * 高精度时间比较，只比较小时和分钟
 */
export const isSameTimeIgnoreSeconds = (date1: Date, date2: Date): boolean => {
  const time1 = new Date(date1);
  const time2 = new Date(date2);
  
  time1.setSeconds(0, 0);
  time2.setSeconds(0, 0);
  
  return time1.getTime() === time2.getTime();
};

/**
 * 计算精确的倒计时文本
 */
export const getDetailedTimeUntilAlarm = (alarmTime: Date): {
  text: string;
  totalMinutes: number;
  isOverdue: boolean;
} => {
  const now = new Date();
  const diff = differenceInMilliseconds(alarmTime, now);
  
  if (diff <= 0) {
    return {
      text: '已过期',
      totalMinutes: 0,
      isOverdue: true
    };
  }
  
  const totalMinutes = Math.ceil(diff / (1000 * 60));
  const days = Math.floor(totalMinutes / (24 * 60));
  const hours = Math.floor((totalMinutes % (24 * 60)) / 60);
  const minutes = totalMinutes % 60;
  
  let text = '';
  if (days > 0) {
    text += `${days}天`;
  }
  if (hours > 0) {
    text += `${hours}小时`;
  }
  if (minutes > 0 || (days === 0 && hours === 0)) {
    text += `${minutes || 1}分钟`;
  }
  text += '后';
  
  return {
    text,
    totalMinutes,
    isOverdue: false
  };
};

/**
 * 创建贪睡闹钟时间（默认10分钟后）
 */
export const createSnoozeTime = (snoozeMinutes: number = 10): Date => {
  return addMinutes(new Date(), snoozeMinutes);
};

/**
 * 格式化持续时间
 */
export const formatDuration = (milliseconds: number): string => {
  const totalSeconds = Math.floor(milliseconds / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  
  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

/**
 * 检查是否为当前时间（精确到分钟）
 */
export const isCurrentTimeMinute = (date: Date): boolean => {
  const now = new Date();
  return isSameTimeIgnoreSeconds(date, now);
};

/**
 * 获取下一个有效的闹钟时间
 */
export const getNextValidAlarmTime = (hour: number, minute: number): Date => {
  const now = new Date();
  const alarmTime = new Date(now);
  
  alarmTime.setHours(hour, minute, 0, 0);
  
  // 如果时间已过，设置为明天
  if (alarmTime <= now) {
    alarmTime.setDate(alarmTime.getDate() + 1);
  }
  
  return alarmTime;
};

/**
 * 解析时间字符串为小时和分钟
 */
export const parseTimeString = (timeString: string): { hour: number; minute: number } | null => {
  const match = timeString.match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  
  const hour = parseInt(match[1], 10);
  const minute = parseInt(match[2], 10);
  
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  
  return { hour, minute };
};

/**
 * 获取相对时间描述
 */
export const getRelativeTimeDescription = (date: Date): string => {
  const now = new Date();
  const diffInMinutes = Math.floor(differenceInMilliseconds(date, now) / (1000 * 60));
  
  if (diffInMinutes < -1440) { // 超过一天前
    return format(date, 'MM-dd HH:mm', { locale: zhCN });
  } else if (diffInMinutes < -60) { // 超过一小时前
    return `${Math.abs(Math.floor(diffInMinutes / 60))}小时前`;
  } else if (diffInMinutes < -1) { // 超过一分钟前
    return `${Math.abs(diffInMinutes)}分钟前`;
  } else if (diffInMinutes < 1) { // 现在
    return '现在';
  } else if (diffInMinutes < 60) { // 一小时内
    return `${diffInMinutes}分钟后`;
  } else if (diffInMinutes < 1440) { // 一天内
    return `${Math.floor(diffInMinutes / 60)}小时${diffInMinutes % 60}分钟后`;
  } else { // 超过一天后
    return format(date, 'MM-dd HH:mm', { locale: zhCN });
  }
};

/**
 * 时间工具类
 */
export const TimeUtils = {
  format,
  formatTime,
  formatTimeWithSeconds,
  formatAlarmTime,
  getTimeUntilAlarm,
  getDetailedTimeUntilAlarm,
  createTimeFromInput,
  createSnoozeTime,
  getGreeting,
  isAlarmTimeValid,
  isSameTimeIgnoreSeconds,
  isCurrentTimeMinute,
  getNextValidAlarmTime,
  parseTimeString,
  getRelativeTimeDescription,
  formatDuration,
};