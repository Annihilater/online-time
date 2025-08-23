import type { Alarm } from '@/shared/stores/alarmStore'

// 测试用的闹钟数据
export const mockAlarms: Alarm[] = [
  {
    id: 'alarm-1',
    time: new Date('2024-01-01T07:00:00'),
    isActive: true,
    sound: 'clock',
    volume: 0.7,
    label: '起床闹钟',
    isRinging: false,
    createdAt: new Date('2024-01-01T00:00:00'),
    snoozeCount: 0,
    isRecurring: true,
    recurringDays: [1, 2, 3, 4, 5] // 工作日
  },
  {
    id: 'alarm-2',
    time: new Date('2024-01-01T12:30:00'),
    isActive: false,
    sound: 'bell',
    volume: 0.5,
    label: '午休提醒',
    isRinging: false,
    createdAt: new Date('2024-01-01T00:00:00'),
    snoozeCount: 1,
    isRecurring: false
  },
  {
    id: 'alarm-3',
    time: new Date('2024-01-01T18:00:00'),
    isActive: true,
    sound: 'rooster',
    volume: 0.8,
    label: '下班提醒',
    isRinging: true,
    createdAt: new Date('2024-01-01T00:00:00'),
    lastTriggered: new Date('2024-01-01T18:00:00'),
    snoozeCount: 0,
    isRecurring: false
  }
]

// 测试用的预设时间
export const mockPresetTimes = [
  { label: '05:00', hour: 5, minute: 0 },
  { label: '06:00', hour: 6, minute: 0 },
  { label: '07:00', hour: 7, minute: 0 },
  { label: '08:00', hour: 8, minute: 0 }
]

// 测试用的声音选项
export const mockSounds = [
  { key: 'clock', name: '时钟' },
  { key: 'bell', name: '钟声' },
  { key: 'rooster', name: '公鸡声' },
  { key: 'siren', name: '警笛声' }
]

// 初始状态数据
export const mockInitialAlarmState = {
  currentTime: new Date('2024-01-01T10:00:00'),
  alarms: [],
  isAlarmRinging: false,
  selectedSound: 'clock',
  volume: 0.7,
  theme: 'light' as const,
  is24HourFormat: false,
  snoozeMinutes: 10,
  enableNotifications: true,
  enableWakeLock: true
}

// 有闹钟的状态
export const mockStateWithAlarms = {
  ...mockInitialAlarmState,
  alarms: mockAlarms,
  isAlarmRinging: true
}

// 测试时间数据
export const mockTestTimes = {
  morning: new Date('2024-01-01T07:00:00'),
  noon: new Date('2024-01-01T12:00:00'),
  evening: new Date('2024-01-01T18:00:00'),
  midnight: new Date('2024-01-01T00:00:00'),
  almostMidnight: new Date('2024-01-01T23:59:59')
}

// 测试用的设置数据
export const mockSettings = {
  theme: 'dark' as const,
  volume: 0.9,
  selectedSound: 'bell',
  is24HourFormat: true,
  enableNotifications: false,
  enableWakeLock: false,
  snoozeMinutes: 15
}

// 测试用的错误情况
export const mockErrorScenarios = {
  audioContextError: new Error('AudioContext creation failed'),
  notificationPermissionDenied: 'denied' as NotificationPermission,
  wakeLockError: new Error('Wake lock not supported'),
  storageQuotaExceeded: new Error('QuotaExceededError')
}

// 测试用的浏览器能力
export const mockBrowserCapabilities = {
  audioContextSupported: true,
  webkitAudioContextSupported: true,
  notificationSupported: true,
  wakeLockSupported: true,
  localStorageSupported: true,
  requestAnimationFrameSupported: true
}

// 测试用的日期范围
export const mockDateRanges = {
  today: new Date('2024-01-01'),
  tomorrow: new Date('2024-01-02'),
  yesterday: new Date('2023-12-31'),
  nextWeek: new Date('2024-01-08'),
  lastWeek: new Date('2023-12-25')
}

// 性能测试数据
export const mockPerformanceData = {
  manyAlarms: Array.from({ length: 50 }, (_, i) => ({
    ...mockAlarms[0],
    id: `alarm-${i}`,
    time: new Date(`2024-01-01T${(7 + i % 17).toString().padStart(2, '0')}:${(i * 13 % 60).toString().padStart(2, '0')}:00`),
    label: `测试闹钟 ${i + 1}`
  }))
}

// 边界测试数据
export const mockBoundaryData = {
  minVolume: 0,
  maxVolume: 1,
  minSnoozeMinutes: 1,
  maxSnoozeMinutes: 60,
  emptyString: '',
  longString: 'a'.repeat(1000),
  specialCharacters: '!@#$%^&*()_+-={}[]|\\:";\'<>?,./',
  unicode: '🔔⏰🎵📱⚡🌙☀️',
  htmlTags: '<script>alert("test")</script>',
  sqlInjection: "'; DROP TABLE alarms; --"
}

// 国际化测试数据
export const mockI18nData = {
  timezones: [
    'Asia/Shanghai',
    'America/New_York', 
    'Europe/London',
    'Asia/Tokyo'
  ],
  locales: [
    'zh-CN',
    'en-US',
    'ja-JP',
    'es-ES'
  ]
}

export default {
  mockAlarms,
  mockPresetTimes,
  mockSounds,
  mockInitialAlarmState,
  mockStateWithAlarms,
  mockTestTimes,
  mockSettings,
  mockErrorScenarios,
  mockBrowserCapabilities,
  mockDateRanges,
  mockPerformanceData,
  mockBoundaryData,
  mockI18nData
}