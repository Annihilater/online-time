import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@/test/test-utils'
import { CountdownPage } from '../CountdownPage'

// Mock store
const mockStore = {
  theme: 'light' as 'light' | 'dark',
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock date-fns
vi.mock('date-fns', () => ({
  format: vi.fn((date, formatStr) => {
    if (formatStr === 'yyyy-MM-dd') {
      return '2024-12-31'
    }
    return date.toISOString()
  }),
  differenceInSeconds: vi.fn(() => {
    // Mock returning 3661 seconds (1 hour, 1 minute, 1 second)
    return 3661
  })
}))

// Mock lucide-react icons
interface MockIconProps {
  size?: number;
  [key: string]: unknown;
}

vi.mock('lucide-react', () => ({
  Calendar: ({ ...props }: MockIconProps) => <div data-testid="calendar-icon" {...props}>Calendar</div>,
  Clock: ({ ...props }: MockIconProps) => <div data-testid="clock-icon" {...props}>Clock</div>,
  Target: ({ ...props }: MockIconProps) => <div data-testid="target-icon" {...props}>Target</div>,
  Share2: ({ ...props }: MockIconProps) => <div data-testid="share-icon" {...props}>Share</div>,
}))

describe('CountdownPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
    
    // Set a fixed current time for consistent testing
    const now = new Date('2024-01-01T12:00:00')
    vi.setSystemTime(now)
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.clearAllTimers()
  })

  it('应该渲染倒数页面界面', () => {
    render(<CountdownPage />)
    
    expect(screen.getByText('倒数计时器')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('选择日期')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('选择时间')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('事件名称（可选）')).toBeInTheDocument()
    expect(screen.getByText('开始倒数')).toBeInTheDocument()
  })

  it('应该显示预设节日选择', () => {
    render(<CountdownPage />)
    
    expect(screen.getByText('快速选择')).toBeInTheDocument()
    expect(screen.getByText('春节')).toBeInTheDocument()
    expect(screen.getByText('新年')).toBeInTheDocument()
    expect(screen.getByText('国庆节')).toBeInTheDocument()
  })

  it('应该能够设置目标日期和时间', () => {
    render(<CountdownPage />)
    
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    const titleInput = screen.getByPlaceholderText('事件名称（可选）')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    fireEvent.change(titleInput, { target: { value: '新年倒数' } })
    
    expect((dateInput as HTMLInputElement).value).toBe('2024-12-31')
    expect((timeInput as HTMLInputElement).value).toBe('23:59')
    expect((titleInput as HTMLInputElement).value).toBe('新年倒数')
  })

  it('应该能够使用预设节日', () => {
    render(<CountdownPage />)
    
    const newYearButton = screen.getByText('新年')
    fireEvent.click(newYearButton)
    
    // 检查日期输入是否被设置
    const dateInput = screen.getByPlaceholderText('选择日期') as HTMLInputElement
    expect(dateInput.value).toBeTruthy()
  })

  it('应该开始倒数计时', async () => {
    render(<CountdownPage />)
    
    // 设置未来日期时间
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待倒数计时显示
    await waitFor(() => {
      expect(screen.getByText('01')).toBeInTheDocument() // 天数
      expect(screen.getByText('01')).toBeInTheDocument() // 小时
      expect(screen.getByText('01')).toBeInTheDocument() // 分钟
      expect(screen.getByText('01')).toBeInTheDocument() // 秒
    })
  })

  it('应该显示倒数计时标签', async () => {
    render(<CountdownPage />)
    
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待标签显示
    await waitFor(() => {
      expect(screen.getByText('天')).toBeInTheDocument()
      expect(screen.getByText('时')).toBeInTheDocument()
      expect(screen.getByText('分')).toBeInTheDocument()
      expect(screen.getByText('秒')).toBeInTheDocument()
    })
  })

  it('应该能够重置倒数计时', async () => {
    render(<CountdownPage />)
    
    // 设置倒数计时
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待倒数显示
    await waitFor(() => {
      expect(screen.getByText('01')).toBeInTheDocument()
    })
    
    // 重置倒数
    const resetButton = screen.getByText('重置')
    fireEvent.click(resetButton)
    
    // 检查是否回到初始状态
    await waitFor(() => {
      expect(screen.getByText('开始倒数')).toBeInTheDocument()
    })
  })

  it('应该能够分享倒数计时', async () => {
    render(<CountdownPage />)
    
    // 设置倒数计时
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    const titleInput = screen.getByPlaceholderText('事件名称（可选）')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    fireEvent.change(titleInput, { target: { value: '新年倒数' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待分享按钮出现
    await waitFor(() => {
      const shareButton = screen.getByText('分享倒数')
      expect(shareButton).toBeInTheDocument()
    })
  })

  it('应该显示倒数完成状态', async () => {
    // Mock differenceInSeconds to return 0 (countdown finished)
    const { differenceInSeconds } = await import('date-fns')
    vi.mocked(differenceInSeconds).mockReturnValue(0)
    
    render(<CountdownPage />)
    
    // 设置倒数计时
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-01-01' } })
    fireEvent.change(timeInput, { target: { value: '11:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待倒数完成显示
    await waitFor(() => {
      expect(screen.getByText('时间到！')).toBeInTheDocument()
    })
  })

  it('应该在深色主题下显示正确的样式', () => {
    mockStore.theme = 'dark'
    
    render(<CountdownPage />)
    
    // 检查深色主题的类名
    const container = screen.getByText('倒数计时器').closest('.min-h-screen')
    expect(container).toHaveClass('bg-gradient-to-b', 'dark:from-gray-900', 'dark:to-gray-800')
  })

  it('应该验证日期输入', () => {
    render(<CountdownPage />)
    
    // 设置过去的日期
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2023-01-01' } })
    fireEvent.change(timeInput, { target: { value: '12:00' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 应该不能开始过去时间的倒数（或显示错误信息）
    expect(screen.getByText('开始倒数')).toBeInTheDocument()
  })

  it('应该显示事件标题', async () => {
    render(<CountdownPage />)
    
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    const titleInput = screen.getByPlaceholderText('事件名称（可选）')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    fireEvent.change(titleInput, { target: { value: '新年庆典' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待事件标题显示
    await waitFor(() => {
      expect(screen.getByText('新年庆典')).toBeInTheDocument()
    })
  })

  it('应该正确格式化时间显示', async () => {
    render(<CountdownPage />)
    
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 检查时间格式（基于mock的返回值3661秒 = 1小时1分1秒）
    await waitFor(() => {
      // 应该显示格式化的时间单位
      expect(screen.getByText('01')).toBeInTheDocument() // 小时
    })
  })

  it('应该能够复制分享链接', async () => {
    // Mock clipboard API
    const mockWriteText = vi.fn().mockResolvedValue(undefined)
    Object.assign(navigator, {
      clipboard: {
        writeText: mockWriteText,
      },
    })

    render(<CountdownPage />)
    
    // 设置倒数计时
    const dateInput = screen.getByPlaceholderText('选择日期')
    const timeInput = screen.getByPlaceholderText('选择时间')
    
    fireEvent.change(dateInput, { target: { value: '2024-12-31' } })
    fireEvent.change(timeInput, { target: { value: '23:59' } })
    
    const startButton = screen.getByText('开始倒数')
    fireEvent.click(startButton)
    
    // 等待分享按钮并点击
    await waitFor(() => {
      const shareButton = screen.getByText('分享倒数')
      fireEvent.click(shareButton)
    })
    
    // 检查clipboard是否被调用
    expect(mockWriteText).toHaveBeenCalled()
  })
})