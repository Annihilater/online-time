import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { useAlarmStore } from '../alarmStore'
import { mockCurrentTime, restoreRealTime } from '@/test/test-utils'
// import { mockAlarms, mockInitialAlarmState } from '@/test/fixtures'
import { act } from '@testing-library/react'

// Mock zustand persist middleware
vi.mock('zustand/middleware', () => ({
  persist: vi.fn((createState) => createState),
}))

// Mock AudioUtils
vi.mock('@/shared/utils/audioUtils', () => ({
  AudioUtils: {
    requestNotificationPermission: vi.fn().mockResolvedValue('granted'),
    showNotification: vi.fn().mockReturnValue({
      close: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    }),
    isNotificationSupported: vi.fn().mockReturnValue(true),
    formatVolumePercentage: vi.fn((volume) => `${Math.round(volume * 100)}%`),
    percentageToVolume: vi.fn((percentage) => percentage / 100),
    getSoundDisplayName: vi.fn((soundKey) => soundKey),
  },
  audioManager: {
    play: vi.fn().mockResolvedValue(undefined),
    stop: vi.fn(),
    setVolume: vi.fn(),
    isPlaying: vi.fn().mockReturnValue(false),
    testSound: vi.fn().mockResolvedValue(undefined),
  },
  audioEngine: {
    play: vi.fn().mockResolvedValue(undefined),
    stop: vi.fn(),
    setVolume: vi.fn(),
    getVolume: vi.fn().mockReturnValue(0.7),
    isCurrentlyPlaying: vi.fn().mockReturnValue(false),
    testSound: vi.fn().mockResolvedValue(undefined),
    getSoundName: vi.fn().mockReturnValue('Test Sound'),
  }
}))

describe('AlarmStore', () => {
  // 重置store状态
  beforeEach(() => {
    // 清除localStorage
    localStorage.clear()
    
    // 重置假时间
    vi.useFakeTimers()
    mockCurrentTime(10, 0, 0) // 设置为10:00:00
    
    // 重置store状态
    useAlarmStore.getState().resetToDefaults()
  })

  afterEach(() => {
    vi.clearAllMocks()
    restoreRealTime()
  })

  describe('初始状态', () => {
    it('应该有正确的初始状态', () => {
      const state = useAlarmStore.getState()
      
      expect(state.alarms).toEqual([])
      expect(state.isAlarmRinging).toBe(false)
      expect(state.selectedSound).toBe('clock')
      expect(state.volume).toBe(0.7)
      expect(state.theme).toBe('light')
      expect(state.is24HourFormat).toBe(false)
      expect(state.snoozeMinutes).toBe(10)
      expect(state.enableNotifications).toBe(true)
      expect(state.enableWakeLock).toBe(true)
    })

    it('当前时间应该被正确初始化', () => {
      const state = useAlarmStore.getState()
      expect(state.currentTime).toBeInstanceOf(Date)
    })
  })

  describe('闹钟管理', () => {
    it('应该能够添加闹钟', () => {
      const { addAlarm } = useAlarmStore.getState()
      const alarmTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(alarmTime, '测试闹钟')
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(1)
      expect(state.alarms[0]).toMatchObject({
        time: alarmTime,
        label: '测试闹钟',
        isActive: true,
        sound: 'clock',
        volume: 0.7,
        isRinging: false,
        snoozeCount: 0,
        isRecurring: false
      })
      expect(state.alarms[0].id).toBeDefined()
      expect(state.alarms[0].createdAt).toBeInstanceOf(Date)
    })

    it('应该能够删除闹钟', () => {
      const { addAlarm, removeAlarm } = useAlarmStore.getState()
      const alarmTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(alarmTime)
      })
      
      const alarmId = useAlarmStore.getState().alarms[0].id
      
      act(() => {
        removeAlarm(alarmId)
      })
      
      expect(useAlarmStore.getState().alarms).toHaveLength(0)
    })

    it('应该能够切换闹钟的激活状态', () => {
      const { addAlarm, toggleAlarm } = useAlarmStore.getState()
      const alarmTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(alarmTime)
      })
      
      const alarmId = useAlarmStore.getState().alarms[0].id
      expect(useAlarmStore.getState().alarms[0].isActive).toBe(true)
      
      act(() => {
        toggleAlarm(alarmId)
      })
      
      expect(useAlarmStore.getState().alarms[0].isActive).toBe(false)
      expect(useAlarmStore.getState().alarms[0].isRinging).toBe(false)
    })

    it('添加的闹钟应该按时间排序', () => {
      const { addAlarm } = useAlarmStore.getState()
      
      act(() => {
        addAlarm(new Date('2024-01-01T10:00:00'), '闹钟2')
        addAlarm(new Date('2024-01-01T08:00:00'), '闹钟1')
        addAlarm(new Date('2024-01-01T12:00:00'), '闹钟3')
      })
      
      const alarms = useAlarmStore.getState().alarms
      expect(alarms[0].label).toBe('闹钟1')
      expect(alarms[1].label).toBe('闹钟2')
      expect(alarms[2].label).toBe('闹钟3')
    })
  })

  describe('闹钟触发', () => {
    it('当时间匹配时应该触发闹钟', () => {
      const { addAlarm, updateCurrentTime } = useAlarmStore.getState()
      
      // 设置当前时间为今天8点
      const targetTime = mockCurrentTime(8, 0, 0)
      const alarmTime = new Date(targetTime)
      
      act(() => {
        addAlarm(alarmTime, '测试闹钟')
      })
      
      // 确保时间完全匹配
      vi.setSystemTime(targetTime)
      
      act(() => {
        updateCurrentTime()
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms[0].isRinging).toBe(true)
      expect(state.isAlarmRinging).toBe(true)
      expect(state.alarms[0].lastTriggered).toBeInstanceOf(Date)
    })

    it('不活跃的闹钟不应该响起', () => {
      const { addAlarm, toggleAlarm, updateCurrentTime } = useAlarmStore.getState()
      const alarmTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(alarmTime)
      })
      
      const alarmId = useAlarmStore.getState().alarms[0].id
      
      act(() => {
        toggleAlarm(alarmId) // 停用闹钟
      })
      
      mockCurrentTime(8, 0, 0)
      
      act(() => {
        updateCurrentTime()
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms[0].isRinging).toBe(false)
      expect(state.isAlarmRinging).toBe(false)
    })

    it('应该能够停止所有闹钟', () => {
      const { addAlarm, stopAllAlarms, updateCurrentTime } = useAlarmStore.getState()
      
      // 创建两个闹钟时间
      const time1 = mockCurrentTime(8, 0, 0)
      const time2 = mockCurrentTime(8, 1, 0)
      
      act(() => {
        addAlarm(new Date(time1), '闹钟1')
        addAlarm(new Date(time2), '闹钟2')
      })
      
      // 触发第一个闹钟
      vi.setSystemTime(time1)
      act(() => {
        updateCurrentTime()
      })
      
      // 触发第二个闹钟
      vi.setSystemTime(time2) 
      act(() => {
        updateCurrentTime()
      })
      
      expect(useAlarmStore.getState().isAlarmRinging).toBe(true)
      
      act(() => {
        stopAllAlarms()
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms.every(alarm => !alarm.isRinging)).toBe(true)
      expect(state.isAlarmRinging).toBe(false)
    })
  })

  describe('贪睡功能', () => {
    it('应该能够贪睡闹钟', () => {
      const { addAlarm, snoozeAlarm, updateCurrentTime } = useAlarmStore.getState()
      const originalTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(originalTime, '测试闹钟')
      })
      
      // 触发闹钟
      mockCurrentTime(8, 0, 0)
      act(() => {
        updateCurrentTime()
      })
      
      const alarmId = useAlarmStore.getState().alarms[0].id
      
      act(() => {
        snoozeAlarm(alarmId)
      })
      
      const state = useAlarmStore.getState()
      const snoozedAlarm = state.alarms[0]
      
      expect(snoozedAlarm.isRinging).toBe(false)
      expect(snoozedAlarm.snoozeCount).toBe(1)
      expect(snoozedAlarm.time.getTime()).toBeGreaterThan(originalTime.getTime())
      expect(state.isAlarmRinging).toBe(false)
    })
  })

  describe('快速闹钟', () => {
    it('应该能够添加快速闹钟', () => {
      const { addQuickAlarm } = useAlarmStore.getState()
      
      act(() => {
        addQuickAlarm(15) // 15分钟后
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(1)
      expect(state.alarms[0].label).toBe('15 分钟后')
      
      // 验证时间是否正确（当前时间 + 15分钟）
      const expectedTime = new Date()
      expectedTime.setMinutes(expectedTime.getMinutes() + 15)
      const actualTime = state.alarms[0].time
      
      // 允许1分钟的误差
      expect(Math.abs(actualTime.getTime() - expectedTime.getTime())).toBeLessThan(60000)
    })

    it('应该能够添加预设闹钟', () => {
      const { addPresetAlarm } = useAlarmStore.getState()
      
      // 当前时间是10:00，添加明天7:00的闹钟
      act(() => {
        addPresetAlarm(7, 30, '起床闹钟')
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(1)
      expect(state.alarms[0].label).toBe('起床闹钟')
      expect(state.alarms[0].time.getHours()).toBe(7)
      expect(state.alarms[0].time.getMinutes()).toBe(30)
    })
  })

  describe('设置管理', () => {
    it('应该能够更新音量', () => {
      const { setVolume } = useAlarmStore.getState()
      
      act(() => {
        setVolume(0.5)
      })
      
      expect(useAlarmStore.getState().volume).toBe(0.5)
    })

    it('应该能够更改声音', () => {
      const { setSound } = useAlarmStore.getState()
      
      act(() => {
        setSound('bell')
      })
      
      expect(useAlarmStore.getState().selectedSound).toBe('bell')
    })

    it('应该能够切换主题', () => {
      const { setTheme } = useAlarmStore.getState()
      
      act(() => {
        setTheme('dark')
      })
      
      expect(useAlarmStore.getState().theme).toBe('dark')
      expect(document.documentElement.getAttribute('data-theme')).toBe('dark')
    })

    it('应该能够更新多个设置', () => {
      const { updateSettings } = useAlarmStore.getState()
      
      act(() => {
        updateSettings({
          theme: 'dark',
          volume: 0.9,
          selectedSound: 'bell',
          is24HourFormat: true,
          snoozeMinutes: 15
        })
      })
      
      const state = useAlarmStore.getState()
      expect(state.theme).toBe('dark')
      expect(state.volume).toBe(0.9)
      expect(state.selectedSound).toBe('bell')
      expect(state.is24HourFormat).toBe(true)
      expect(state.snoozeMinutes).toBe(15)
    })

    it('贪睡分钟应该在合理范围内', () => {
      const { setSnoozeMinutes } = useAlarmStore.getState()
      
      // 测试最小值
      act(() => {
        setSnoozeMinutes(0)
      })
      expect(useAlarmStore.getState().snoozeMinutes).toBe(1)
      
      // 测试最大值
      act(() => {
        setSnoozeMinutes(100)
      })
      expect(useAlarmStore.getState().snoozeMinutes).toBe(60)
      
      // 测试正常值
      act(() => {
        setSnoozeMinutes(15)
      })
      expect(useAlarmStore.getState().snoozeMinutes).toBe(15)
    })
  })

  describe('闹钟编辑', () => {
    it('应该能够编辑闹钟', () => {
      const { addAlarm, editAlarm } = useAlarmStore.getState()
      const originalTime = new Date('2024-01-01T08:00:00')
      
      act(() => {
        addAlarm(originalTime, '原始闹钟')
      })
      
      const alarmId = useAlarmStore.getState().alarms[0].id
      const newTime = new Date('2024-01-01T09:00:00')
      
      act(() => {
        editAlarm(alarmId, {
          time: newTime,
          label: '修改后的闹钟',
          sound: 'bell',
          volume: 0.9
        })
      })
      
      const updatedAlarm = useAlarmStore.getState().alarms[0]
      expect(updatedAlarm.time).toEqual(newTime)
      expect(updatedAlarm.label).toBe('修改后的闹钟')
      expect(updatedAlarm.sound).toBe('bell')
      expect(updatedAlarm.volume).toBe(0.9)
    })

    it('应该能够复制闹钟', () => {
      const { addAlarm, duplicateAlarm } = useAlarmStore.getState()
      
      act(() => {
        addAlarm(new Date('2024-01-01T08:00:00'), '原始闹钟', {
          sound: 'bell',
          volume: 0.8,
          isRecurring: true
        })
      })
      
      const originalId = useAlarmStore.getState().alarms[0].id
      
      act(() => {
        duplicateAlarm(originalId)
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(2)
      
      const duplicated = state.alarms[1]
      expect(duplicated.label).toBe('原始闹钟 (复制)')
      expect(duplicated.sound).toBe('bell')
      expect(duplicated.volume).toBe(0.8)
      expect(duplicated.isRecurring).toBe(true)
      expect(duplicated.id).not.toBe(originalId)
    })
  })

  describe('过期闹钟清理', () => {
    it('应该能够清理过期闹钟', () => {
      const { addAlarm, clearExpiredAlarms } = useAlarmStore.getState()
      
      // 获取当前时间（已在beforeEach中设置为10:00）
      const currentTime = new Date()
      
      // 添加过去的闹钟（7:00，比当前时间早）
      const pastTime = new Date(currentTime)
      pastTime.setHours(7, 0, 0, 0)
      
      // 添加未来的闹钟（11:00，比当前时间晚）  
      const futureTime = new Date(currentTime)
      futureTime.setHours(11, 0, 0, 0)
      
      // 添加过去的重复闹钟（6:00，但是重复的，不应被清理）
      const pastRecurringTime = new Date(currentTime)
      pastRecurringTime.setHours(6, 0, 0, 0)
      
      act(() => {
        addAlarm(pastTime, '过期闹钟')
        addAlarm(futureTime, '未来闹钟')
        addAlarm(pastRecurringTime, '重复闹钟', { isRecurring: true })
      })
      
      act(() => {
        clearExpiredAlarms()
      })
      
      const state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(2)
      expect(state.alarms.find(a => a.label === '过期闹钟')).toBeUndefined()
      expect(state.alarms.find(a => a.label === '未来闹钟')).toBeDefined()
      expect(state.alarms.find(a => a.label === '重复闹钟')).toBeDefined()
    })
  })

  describe('通知权限', () => {
    it('应该能够请求通知权限', async () => {
      const { setEnableNotifications } = useAlarmStore.getState()
      const { AudioUtils } = await import('@/shared/utils/audioUtils')
      
      // Mock成功的权限请求
      vi.mocked(AudioUtils.requestNotificationPermission).mockResolvedValue('granted')
      
      await act(async () => {
        await setEnableNotifications(true)
      })
      
      expect(useAlarmStore.getState().enableNotifications).toBe(true)
      expect(AudioUtils.requestNotificationPermission).toHaveBeenCalled()
    })

    it('权限被拒绝时应该禁用通知', async () => {
      const { setEnableNotifications } = useAlarmStore.getState()
      const { AudioUtils } = await import('@/shared/utils/audioUtils')
      
      // Mock被拒绝的权限请求
      vi.mocked(AudioUtils.requestNotificationPermission).mockResolvedValue('denied')
      
      await act(async () => {
        await setEnableNotifications(true)
      })
      
      expect(useAlarmStore.getState().enableNotifications).toBe(false)
    })
  })

  describe('状态重置', () => {
    it('应该能够重置到默认状态', () => {
      const { addAlarm, setVolume, setTheme, resetToDefaults } = useAlarmStore.getState()
      
      // 修改一些状态
      act(() => {
        addAlarm(new Date(), '测试闹钟')
        setVolume(0.9)
        setTheme('dark')
      })
      
      // 验证状态已修改
      let state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(1)
      expect(state.volume).toBe(0.9)
      expect(state.theme).toBe('dark')
      
      // 重置状态
      act(() => {
        resetToDefaults()
      })
      
      // 验证已重置
      state = useAlarmStore.getState()
      expect(state.alarms).toHaveLength(0)
      expect(state.volume).toBe(0.7)
      expect(state.theme).toBe('light')
    })
  })
})