/* eslint-disable @typescript-eslint/no-explicit-any */
import '@testing-library/jest-dom'
import { expect, afterEach, beforeAll, afterAll, vi } from 'vitest'
import { cleanup } from '@testing-library/react'

// 清理React组件测试
afterEach(() => {
  cleanup()
})

// Mock浏览器API
beforeAll(() => {
  // Mock AudioContext
  const MockAudioContext = vi.fn().mockImplementation(() => ({
    createOscillator: vi.fn().mockReturnValue({
      connect: vi.fn(),
      disconnect: vi.fn(),
      start: vi.fn(),
      stop: vi.fn(),
      frequency: { 
        value: 440,
        setValueAtTime: vi.fn(),
        linearRampToValueAtTime: vi.fn(),
        exponentialRampToValueAtTime: vi.fn()
      },
      type: 'sine'
    }),
    createGain: vi.fn().mockReturnValue({
      connect: vi.fn(),
      disconnect: vi.fn(),
      gain: {
        value: 0.5,
        setValueAtTime: vi.fn(),
        linearRampToValueAtTime: vi.fn()
      }
    }),
    createBuffer: vi.fn(),
    createBufferSource: vi.fn().mockReturnValue({
      connect: vi.fn(),
      start: vi.fn(),
      buffer: null
    }),
    destination: {},
    currentTime: 0,
    sampleRate: 44100,
    state: 'running',
    resume: vi.fn().mockResolvedValue(undefined),
    close: vi.fn().mockResolvedValue(undefined)
  }))

  // 设置全局AudioContext
  global.AudioContext = MockAudioContext as typeof AudioContext;
  
  // Mock webkitAudioContext for older browsers
  ;(global as typeof global & { webkitAudioContext: typeof AudioContext }).webkitAudioContext = MockAudioContext

  // Mock Notification API
  global.Notification = vi.fn().mockImplementation((title, options) => ({
    title,
    ...options,
    close: vi.fn()
  })) as unknown as typeof Notification

  Object.defineProperty(global.Notification, 'permission', {
    value: 'granted',
    writable: true
  })

  Object.defineProperty(global.Notification, 'requestPermission', {
    value: vi.fn().mockResolvedValue('granted'),
    writable: true,
    configurable: true
  })

  // Mock localStorage
  const localStorageMock = (() => {
    let store: Record<string, string> = {}

    return {
      getItem: vi.fn((key: string) => store[key] || null),
      setItem: vi.fn((key: string, value: string) => {
        store[key] = value.toString()
      }),
      removeItem: vi.fn((key: string) => {
        delete store[key]
      }),
      clear: vi.fn(() => {
        store = {}
      }),
      get length() {
        return Object.keys(store).length
      },
      key: vi.fn((index: number) => {
        const keys = Object.keys(store)
        return keys[index] || null
      })
    }
  })()

  Object.defineProperty(window, 'localStorage', {
    value: localStorageMock
  })

  // Mock sessionStorage
  Object.defineProperty(window, 'sessionStorage', {
    value: localStorageMock
  })

  // Mock requestAnimationFrame
  global.requestAnimationFrame = vi.fn((callback) => {
    setTimeout(callback, 16) // 60fps
    return 1
  })

  global.cancelAnimationFrame = vi.fn()

  // Mock Wake Lock API
  Object.defineProperty(navigator, 'wakeLock', {
    value: {
      request: vi.fn().mockResolvedValue({
        release: vi.fn(),
        released: false,
        type: 'screen',
        addEventListener: vi.fn(),
        removeEventListener: vi.fn()
      })
    },
    writable: true
  })

  // Mock matchMedia
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(), // deprecated
      removeListener: vi.fn(), // deprecated
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  })

  // Mock ResizeObserver
  global.ResizeObserver = vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  }))

  // Mock IntersectionObserver
  global.IntersectionObserver = vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  }))

  // Mock Date for consistent testing
  vi.useFakeTimers()
})

afterAll(() => {
  vi.useRealTimers()
})

// Custom matchers
expect.extend({
  toHaveBeenCalledWithAudio(received, expectedSound) {
    const pass = received.mock.calls.some((call: any[]) => 
      call.some(arg => arg === expectedSound || (typeof arg === 'object' && arg?.sound === expectedSound))
    )
    
    return {
      message: () => `expected function to have been called with audio "${expectedSound}"`,
      pass
    }
  }
})

// Declare custom matcher types
declare module 'vitest' {
  interface Assertion<T = any> {
    toHaveBeenCalledWithAudio(expectedSound: string): T
  }
}