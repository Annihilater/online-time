import { describe, it, expect, vi } from 'vitest'

describe('测试环境验证', () => {
  it('基本的断言应该工作', () => {
    expect(1 + 1).toBe(2)
    expect('hello').toBe('hello')
    expect(true).toBeTruthy()
  })

  it('Mock函数应该工作', () => {
    const mockFn = vi.fn()
    mockFn('test')
    
    expect(mockFn).toHaveBeenCalledWith('test')
    expect(mockFn).toHaveBeenCalledTimes(1)
  })

  it('假时间应该工作', () => {
    vi.useFakeTimers()
    const start = Date.now()
    
    vi.advanceTimersByTime(1000)
    
    const end = Date.now()
    expect(end - start).toBe(1000)
    
    vi.useRealTimers()
  })

  it('localStorage Mock应该工作', () => {
    localStorage.setItem('test', 'value')
    expect(localStorage.getItem('test')).toBe('value')
    
    localStorage.removeItem('test')
    expect(localStorage.getItem('test')).toBeNull()
  })

  it('AudioContext Mock应该工作', () => {
    expect(() => new AudioContext()).not.toThrow()
    
    const audioContext = new AudioContext()
    expect(audioContext.createOscillator).toBeDefined()
    expect(audioContext.createGain).toBeDefined()
  })

  it('Notification Mock应该工作', () => {
    expect(Notification.permission).toBe('granted')
    expect(Notification.requestPermission).toBeDefined()
    
    const notification = new Notification('Test', { body: 'Test body' })
    expect(notification.title).toBe('Test')
  })

  it('Wake Lock Mock应该工作', async () => {
    expect(navigator.wakeLock).toBeDefined()
    expect(navigator.wakeLock.request).toBeDefined()
    
    const wakeLock = await navigator.wakeLock.request('screen')
    expect(wakeLock.release).toBeDefined()
  })

  it('requestAnimationFrame Mock应该工作', async () => {
    const callback = vi.fn()
    const id = requestAnimationFrame(callback)
    
    expect(id).toBeDefined()
    
    // 等待setTimeout执行
    await new Promise(resolve => setTimeout(resolve, 20))
    
    expect(callback).toHaveBeenCalled()
  })
})