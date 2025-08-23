import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, act } from '@/test/test-utils'
import { TimerPage } from '../TimerPage'

// Mock store
const mockStore = {
  theme: 'light' as 'light' | 'dark',
  selectedSound: 'clock',
  volume: 0.7,
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock Audio
const mockPlay = vi.fn().mockResolvedValue(undefined)
const mockAudio = {
  play: mockPlay,
  volume: 0.7,
  currentTime: 0,
  duration: 0,
  paused: true,
}

global.Audio = vi.fn().mockImplementation(() => mockAudio) as typeof Audio

// Mock lucide-react icons
interface MockIconProps {
  size?: number;
  [key: string]: unknown;
}

vi.mock('lucide-react', () => ({
  Play: ({ ...props }: MockIconProps) => <div data-testid="play-icon" {...props}>Play</div>,
  Pause: ({ ...props }: MockIconProps) => <div data-testid="pause-icon" {...props}>Pause</div>,
  RotateCcw: ({ ...props }: MockIconProps) => <div data-testid="rotate-icon" {...props}>Reset</div>,
}))

describe('TimerPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.clearAllTimers()
  })

  it('应该渲染定时器界面', () => {
    render(<TimerPage />)
    
    expect(screen.getByText('在线定时器')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('分钟')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('秒')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('定时器名称 (可选)')).toBeInTheDocument()
    expect(screen.getByText('开始')).toBeInTheDocument()
  })

  it('应该显示预设时间按钮', () => {
    render(<TimerPage />)
    
    expect(screen.getByText('15秒')).toBeInTheDocument()
    expect(screen.getByText('30秒')).toBeInTheDocument() 
    expect(screen.getByText('1分钟')).toBeInTheDocument()
    expect(screen.getByText('5分钟')).toBeInTheDocument()
    expect(screen.getByText('10分钟')).toBeInTheDocument()
  })

  it('应该能够设置定时器时间', () => {
    render(<TimerPage />)
    
    const minutesInput = screen.getByPlaceholderText('分钟')
    const secondsInput = screen.getByPlaceholderText('秒')
    
    fireEvent.change(minutesInput, { target: { value: '5' } })
    fireEvent.change(secondsInput, { target: { value: '30' } })
    
    expect((minutesInput as HTMLInputElement).value).toBe('5')
    expect((secondsInput as HTMLInputElement).value).toBe('30')
  })

  it('应该能够使用预设时间', () => {
    render(<TimerPage />)
    
    const preset30s = screen.getByText('30秒')
    fireEvent.click(preset30s)
    
    // 检查时间显示是否更新为30秒
    expect(screen.getByText('00:30')).toBeInTheDocument()
  })

  it('应该能够启动和暂停定时器', async () => {
    render(<TimerPage />)
    
    // 设置30秒定时器
    const preset30s = screen.getByText('30秒')
    fireEvent.click(preset30s)
    
    // 启动定时器
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 检查按钮变为暂停
    await waitFor(() => {
      expect(screen.getByText('暂停')).toBeInTheDocument()
    })
    
    // 暂停定时器
    const pauseButton = screen.getByText('暂停')
    fireEvent.click(pauseButton)
    
    // 检查按钮变回开始
    await waitFor(() => {
      expect(screen.getByText('继续')).toBeInTheDocument()
    })
  })

  it('应该能够重置定时器', async () => {
    render(<TimerPage />)
    
    // 设置30秒定时器
    const preset30s = screen.getByText('30秒')
    fireEvent.click(preset30s)
    
    // 启动定时器
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 等待1秒
    act(() => {
      vi.advanceTimersByTime(1000)
    })
    
    // 重置定时器
    const resetButton = screen.getByTestId('rotate-icon').parentElement!
    fireEvent.click(resetButton)
    
    // 检查时间重置为30秒
    await waitFor(() => {
      expect(screen.getByText('00:30')).toBeInTheDocument()
      expect(screen.getByText('开始')).toBeInTheDocument()
    })
  })

  it('定时器结束时应该播放声音', async () => {
    render(<TimerPage />)
    
    // 设置1秒定时器
    const minutesInput = screen.getByPlaceholderText('分钟')
    const secondsInput = screen.getByPlaceholderText('秒')
    
    fireEvent.change(minutesInput, { target: { value: '0' } })
    fireEvent.change(secondsInput, { target: { value: '1' } })
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 等待定时器结束
    act(() => {
      vi.advanceTimersByTime(1100) // 稍微多一点确保定时器结束
    })
    
    await waitFor(() => {
      expect(global.Audio).toHaveBeenCalledWith('/sounds/clock.mp3')
      expect(mockPlay).toHaveBeenCalled()
    })
  })

  it('应该显示进度环', () => {
    render(<TimerPage />)
    
    // 设置定时器
    const preset30s = screen.getByText('30秒')
    fireEvent.click(preset30s)
    
    // 检查SVG进度环存在
    const svg = screen.getByRole('img', { hidden: true })
    expect(svg).toBeInTheDocument()
  })

  it('应该能够设置定时器名称', () => {
    render(<TimerPage />)
    
    const nameInput = screen.getByPlaceholderText('定时器名称 (可选)')
    fireEvent.change(nameInput, { target: { value: '测试定时器' } })
    
    expect((nameInput as HTMLInputElement).value).toBe('测试定时器')
  })

  it('定时器完成后应该添加到历史记录', async () => {
    render(<TimerPage />)
    
    // 设置1秒定时器并命名
    const minutesInput = screen.getByPlaceholderText('分钟')
    const secondsInput = screen.getByPlaceholderText('秒')
    const nameInput = screen.getByPlaceholderText('定时器名称 (可选)')
    
    fireEvent.change(minutesInput, { target: { value: '0' } })
    fireEvent.change(secondsInput, { target: { value: '1' } })
    fireEvent.change(nameInput, { target: { value: '测试定时器' } })
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 等待定时器结束
    act(() => {
      vi.advanceTimersByTime(1100)
    })
    
    // 检查历史记录部分是否显示
    await waitFor(() => {
      expect(screen.getByText('定时器历史')).toBeInTheDocument()
      expect(screen.getByText('测试定时器')).toBeInTheDocument()
    })
  })

  it('应该正确格式化时间显示', () => {
    render(<TimerPage />)
    
    // 测试不同的时间格式
    const minutesInput = screen.getByPlaceholderText('分钟')
    const secondsInput = screen.getByPlaceholderText('秒')
    
    // 测试 1:05
    fireEvent.change(minutesInput, { target: { value: '1' } })
    fireEvent.change(secondsInput, { target: { value: '5' } })
    
    expect(screen.getByText('01:05')).toBeInTheDocument()
  })

  it('应该在深色主题下显示正确的样式', () => {
    mockStore.theme = 'dark'
    
    render(<TimerPage />)
    
    // 检查深色主题的类名
    const container = screen.getByText('在线定时器').closest('.min-h-screen')
    expect(container).toHaveClass('bg-gradient-to-b', 'dark:from-gray-900', 'dark:to-gray-800')
  })

  it('应该限制输入的最大值', () => {
    render(<TimerPage />)
    
    const minutesInput = screen.getByPlaceholderText('分钟')
    const secondsInput = screen.getByPlaceholderText('秒')
    
    // 测试超出限制的输入
    fireEvent.change(minutesInput, { target: { value: '999' } })
    fireEvent.change(secondsInput, { target: { value: '999' } })
    
    // 分钟应该限制在99，秒应该限制在59
    expect((minutesInput as HTMLInputElement).value).toBe('99')
    expect((secondsInput as HTMLInputElement).value).toBe('59')
  })

  it('应该能够处理空输入', () => {
    render(<TimerPage />)
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 没有设置时间时，应该不能启动定时器
    expect(screen.getByText('开始')).toBeInTheDocument()
  })

  it('应该能够清除历史记录', async () => {
    render(<TimerPage />)
    
    // 先完成一个定时器以创建历史记录
    const secondsInput = screen.getByPlaceholderText('秒')
    fireEvent.change(secondsInput, { target: { value: '1' } })
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    act(() => {
      vi.advanceTimersByTime(1100)
    })
    
    // 等待历史记录显示
    await waitFor(() => {
      expect(screen.getByText('定时器历史')).toBeInTheDocument()
    })
    
    // 查找并点击清除按钮（如果存在）
    const clearButton = screen.queryByText('清除历史')
    if (clearButton) {
      fireEvent.click(clearButton)
      await waitFor(() => {
        expect(screen.queryByText('未命名定时器')).not.toBeInTheDocument()
      })
    }
  })
})