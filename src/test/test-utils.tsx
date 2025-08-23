import React, { type ReactElement } from 'react'
import { render as rtlRender, type RenderOptions } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { vi, expect } from 'vitest'

// 创建用于测试的Provider包装器
const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <BrowserRouter>
      {children}
    </BrowserRouter>
  )
}

// 自定义render函数，包含所有Provider
const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>,
) => {
  return rtlRender(ui, { wrapper: AllTheProviders, ...options });
}

// 重新导出所有testing-library的内容
export * from '@testing-library/react'
export { customRender as render }

// 测试工具函数
export const waitForTimeout = (ms: number) => 
  new Promise(resolve => setTimeout(resolve, ms))

// Mock时间相关的工具函数
export const mockDate = (dateString: string) => {
  const mockDate = new Date(dateString)
  vi.setSystemTime(mockDate)
  return mockDate
}

export const mockCurrentTime = (hours: number, minutes: number = 0, seconds: number = 0) => {
  const today = new Date()
  today.setHours(hours, minutes, seconds, 0)
  vi.setSystemTime(today)
  return today
}

// 恢复真实时间
export const restoreRealTime = () => {
  vi.useRealTimers()
  vi.useFakeTimers()
}

// 创建假的闹钟数据
export const createMockAlarm = (overrides: Partial<any> = {}) => ({
  id: 'test-alarm-' + Math.random().toString(36).substr(2, 9),
  time: new Date('2024-01-01 08:00:00'),
  isActive: true,
  sound: 'clock',
  volume: 0.7,
  label: 'Test Alarm',
  isRinging: false,
  createdAt: new Date(),
  lastTriggered: undefined,
  snoozeCount: 0,
  isRecurring: false,
  recurringDays: undefined,
  ...overrides
})

// Mock Audio Engine
export const createMockAudioEngine = () => ({
  play: vi.fn().mockResolvedValue(undefined),
  stop: vi.fn(),
  setVolume: vi.fn(),
  getVolume: vi.fn().mockReturnValue(0.7),
  isCurrentlyPlaying: vi.fn().mockReturnValue(false),
  testSound: vi.fn().mockResolvedValue(undefined),
  getSoundName: vi.fn().mockReturnValue('Test Sound'),
  getAllSounds: vi.fn().mockReturnValue([
    { key: 'clock', name: '时钟' },
    { key: 'beep', name: '蜂鸣声' }
  ]),
  dispose: vi.fn()
})

// Mock Zustand Store的工具函数
export const createMockStore = <T extends Record<string, any>>(initialState: T) => {
  let state = { ...initialState }
  
  const setState = vi.fn((updater: any) => {
    if (typeof updater === 'function') {
      state = { ...state, ...updater(state) }
    } else {
      state = { ...state, ...updater }
    }
  })
  
  const getState = vi.fn(() => state)
  
  return {
    setState,
    getState,
    get: (selector?: (state: T) => any) => selector ? selector(state) : state,
    subscribe: vi.fn(),
    unsubscribe: vi.fn(),
    destroy: vi.fn()
  }
}

// 用于测试异步操作的辅助函数
export const flushPromises = () => new Promise(setImmediate)

// 模拟用户交互的工具
export const mockUserInteraction = () => {
  // 模拟用户手势来启用音频上下文
  const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
  if (audioContext.state === 'suspended') {
    return audioContext.resume()
  }
  return Promise.resolve()
}

// DOM事件模拟
export const fireEvent = {
  visibilityChange: () => {
    Object.defineProperty(document, 'hidden', {
      writable: true,
      value: !document.hidden
    })
    document.dispatchEvent(new Event('visibilitychange'))
  },
  
  windowFocus: () => {
    window.dispatchEvent(new Event('focus'))
  },
  
  windowBlur: () => {
    window.dispatchEvent(new Event('blur'))
  },
  
  beforeUnload: () => {
    window.dispatchEvent(new Event('beforeunload'))
  },

  click: (element: Element) => {
    element.dispatchEvent(new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
    }))
  },

  change: (element: Element, value?: any) => {
    if (element instanceof HTMLInputElement && value !== undefined) {
      element.value = String(value)
    }
    element.dispatchEvent(new Event('change', {
      bubbles: true
    }))
  }
}

// 测试ID生成器
export const generateTestId = (prefix: string = 'test') => 
  `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

// 断言辅助函数
export const expectToBeInRange = (value: number, min: number, max: number) => {
  expect(value).toBeGreaterThanOrEqual(min)
  expect(value).toBeLessThanOrEqual(max)
}

export const expectTimeToBeClose = (actual: Date, expected: Date, toleranceMs: number = 1000) => {
  const diff = Math.abs(actual.getTime() - expected.getTime())
  expect(diff).toBeLessThan(toleranceMs)
}

// 模拟网络请求
export const mockFetch = (response: any, options: { ok?: boolean; status?: number } = {}) => {
  const mockResponse = {
    ok: options.ok ?? true,
    status: options.status ?? 200,
    json: vi.fn().mockResolvedValue(response),
    text: vi.fn().mockResolvedValue(JSON.stringify(response)),
  }
  
  global.fetch = vi.fn().mockResolvedValue(mockResponse)
  return mockResponse
}