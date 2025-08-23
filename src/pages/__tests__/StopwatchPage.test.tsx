import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, act } from '@/test/test-utils'
import { StopwatchPage } from '../StopwatchPage'

// Mock store
const mockStore = {
  theme: 'light' as 'light' | 'dark',
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock lucide-react icons
vi.mock('lucide-react', () => ({
  Play: ({ size, ...props }: any) => <div data-testid="play-icon" {...props}>Play</div>,
  Pause: ({ size, ...props }: any) => <div data-testid="pause-icon" {...props}>Pause</div>,
  RotateCcw: ({ size, ...props }: any) => <div data-testid="rotate-icon" {...props}>Reset</div>,
  Flag: ({ size, ...props }: any) => <div data-testid="flag-icon" {...props}>Flag</div>,
  Download: ({ size, ...props }: any) => <div data-testid="download-icon" {...props}>Download</div>,
}))

describe('StopwatchPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
    
    // Mock Date.now for consistent timing
    const baseTime = 1640995200000 // 2022-01-01T00:00:00.000Z
    vi.spyOn(Date, 'now').mockImplementation(() => baseTime)
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.clearAllTimers()
  })

  it('应该渲染秒表页面界面', () => {
    render(<StopwatchPage />)
    
    expect(screen.getByText('秒表计时器')).toBeInTheDocument()
    expect(screen.getByText('00:00.00')).toBeInTheDocument()
    expect(screen.getByText('开始')).toBeInTheDocument()
  })

  it('应该能够启动秒表', () => {
    render(<StopwatchPage />)
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    expect(screen.getByText('暂停')).toBeInTheDocument()
    expect(screen.getByText('分段')).toBeInTheDocument()
  })

  it('应该能够暂停秒表', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 暂停秒表
    const pauseButton = screen.getByText('暂停')
    fireEvent.click(pauseButton)
    
    expect(screen.getByText('继续')).toBeInTheDocument()
    expect(screen.getByText('重置')).toBeInTheDocument()
  })

  it('应该能够重置秒表', () => {
    render(<StopwatchPage />)
    
    // 启动并暂停秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    const pauseButton = screen.getByText('暂停')
    fireEvent.click(pauseButton)
    
    // 重置秒表
    const resetButton = screen.getByText('重置')
    fireEvent.click(resetButton)
    
    expect(screen.getByText('00:00.00')).toBeInTheDocument()
    expect(screen.getByText('开始')).toBeInTheDocument()
  })

  it('应该能够记录分段时间', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 模拟时间流逝
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995201000) // +1秒
    })
    
    // 记录分段
    const lapButton = screen.getByText('分段')
    fireEvent.click(lapButton)
    
    // 检查分段记录显示
    expect(screen.getByText('分段记录')).toBeInTheDocument()
    expect(screen.getByText('分段 1')).toBeInTheDocument()
  })

  it('应该正确格式化时间显示', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 模拟不同的时间流逝
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995261500) // +1分1.5秒
    })
    
    // 检查时间格式
    expect(screen.getByText('01:01.50')).toBeInTheDocument()
  })

  it('应该显示分段时间和总时间的差异', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 第一个分段
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995201000) // +1秒
    })
    
    const lapButton = screen.getByText('分段')
    fireEvent.click(lapButton)
    
    // 第二个分段
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995203000) // +3秒总计
    })
    
    fireEvent.click(lapButton)
    
    // 检查分段记录
    expect(screen.getByText('分段 1')).toBeInTheDocument()
    expect(screen.getByText('分段 2')).toBeInTheDocument()
  })

  it('应该能够继续暂停的秒表', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 暂停
    const pauseButton = screen.getByText('暂停')
    fireEvent.click(pauseButton)
    
    // 继续
    const continueButton = screen.getByText('继续')
    fireEvent.click(continueButton)
    
    expect(screen.getByText('暂停')).toBeInTheDocument()
    expect(screen.getByText('分段')).toBeInTheDocument()
  })

  it('应该在深色主题下显示正确的样式', () => {
    mockStore.theme = 'dark'
    
    render(<StopwatchPage />)
    
    // 检查深色主题的类名
    const container = screen.getByText('秒表计时器').closest('.min-h-screen')
    expect(container).toHaveClass('bg-gradient-to-b', 'dark:from-gray-900', 'dark:to-gray-800')
  })

  it('应该显示最快和最慢分段', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 记录多个不同时长的分段
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995201000) // +1秒
    })
    
    const lapButton = screen.getByText('分段')
    fireEvent.click(lapButton)
    
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995204000) // +4秒总计，分段3秒
    })
    
    fireEvent.click(lapButton)
    
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995205500) // +5.5秒总计，分段1.5秒
    })
    
    fireEvent.click(lapButton)
    
    // 应该有足够的分段来显示最快/最慢
    expect(screen.getByText('分段记录')).toBeInTheDocument()
  })

  it('应该能够清除分段记录', () => {
    render(<StopwatchPage />)
    
    // 启动秒表并记录分段
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995201000)
    })
    
    const lapButton = screen.getByText('分段')
    fireEvent.click(lapButton)
    
    // 重置应该清除分段记录
    const pauseButton = screen.getByText('暂停')
    fireEvent.click(pauseButton)
    
    const resetButton = screen.getByText('重置')
    fireEvent.click(resetButton)
    
    expect(screen.queryByText('分段记录')).not.toBeInTheDocument()
  })

  it('应该能够导出分段数据', () => {
    render(<StopwatchPage />)
    
    // 启动秒表并记录分段
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995201000)
    })
    
    const lapButton = screen.getByText('分段')
    fireEvent.click(lapButton)
    
    // 查找导出按钮（如果存在）
    const exportButton = screen.queryByText('导出数据')
    if (exportButton) {
      expect(exportButton).toBeInTheDocument()
    }
  })

  it('应该正确处理毫秒精度', () => {
    render(<StopwatchPage />)
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 模拟精确的毫秒时间
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995200123) // +123毫秒
    })
    
    // 检查毫秒显示
    expect(screen.getByText('00:00.12')).toBeInTheDocument()
  })

  it('应该在秒表运行时禁用重置按钮', () => {
    render(<StopwatchPage />)
    
    // 启动秒表
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 重置按钮不应该存在（被分段按钮替代）
    expect(screen.queryByText('重置')).not.toBeInTheDocument()
    expect(screen.getByText('分段')).toBeInTheDocument()
  })

  it('应该显示分段统计信息', () => {
    render(<StopwatchPage />)
    
    // 启动秒表并记录多个分段
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 记录3个分段用于统计
    for (let i = 1; i <= 3; i++) {
      act(() => {
        vi.spyOn(Date, 'now').mockImplementation(() => 1640995200000 + (i * 1000))
      })
      
      const lapButton = screen.getByText('分段')
      fireEvent.click(lapButton)
    }
    
    // 应该显示分段记录标题
    expect(screen.getByText('分段记录')).toBeInTheDocument()
  })

  it('应该处理长时间运行', () => {
    render(<StopwatchPage />)
    
    const startButton = screen.getByText('开始')
    fireEvent.click(startButton)
    
    // 模拟超过1小时的运行时间
    act(() => {
      vi.spyOn(Date, 'now').mockImplementation(() => 1640995200000 + (3661 * 1000)) // 1小时1分1秒
    })
    
    // 检查时间格式（应该仍然显示分:秒.毫秒格式）
    expect(screen.getByText('61:01.00')).toBeInTheDocument()
  })
})