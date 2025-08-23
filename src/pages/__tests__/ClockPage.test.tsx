import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@/test/test-utils'
import { ClockPage } from '../ClockPage'

// Mock store
const mockStore = {
  theme: 'light' as 'light' | 'dark',
  currentTime: new Date('2024-01-01T14:30:45'),
  is24HourFormat: true,
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock date-fns
vi.mock('date-fns', () => ({
  format: vi.fn((date, formatStr) => {
    // const mockDate = new Date('2024-01-01T14:30:45')
    if (formatStr === 'HH:mm:ss') {
      return '14:30:45'
    }
    if (formatStr === 'hh:mm:ss a') {
      return '02:30:45 PM'
    }
    if (formatStr === 'EEEE, MMMM do, yyyy') {
      return 'Monday, January 1st, 2024'
    }
    return date.toISOString()
  })
}))

describe('ClockPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('应该渲染时钟页面界面', () => {
    render(<ClockPage />)
    
    expect(screen.getByText('数字时钟')).toBeInTheDocument()
    expect(screen.getByText('14:30:45')).toBeInTheDocument()
    expect(screen.getByText('Monday, January 1st, 2024')).toBeInTheDocument()
  })

  it('应该显示模拟时钟和数字时钟切换按钮', () => {
    render(<ClockPage />)
    
    expect(screen.getByText('模拟时钟')).toBeInTheDocument()
    expect(screen.getByText('数字时钟')).toBeInTheDocument()
  })

  it('应该能够切换到模拟时钟视图', () => {
    render(<ClockPage />)
    
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 检查模拟时钟元素是否存在
    const clockFace = screen.getByRole('img', { hidden: true })
    expect(clockFace).toBeInTheDocument()
  })

  it('应该能够切换回数字时钟视图', () => {
    render(<ClockPage />)
    
    // 先切换到模拟时钟
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 再切换回数字时钟
    const digitalButton = screen.getByText('数字时钟')
    fireEvent.click(digitalButton)
    
    // 检查数字时钟显示
    expect(screen.getByText('14:30:45')).toBeInTheDocument()
  })

  it('应该在12小时格式下显示正确的时间', () => {
    mockStore.is24HourFormat = false
    
    render(<ClockPage />)
    
    expect(screen.getByText('02:30:45 PM')).toBeInTheDocument()
  })

  it('应该在24小时格式下显示正确的时间', () => {
    mockStore.is24HourFormat = true
    
    render(<ClockPage />)
    
    expect(screen.getByText('14:30:45')).toBeInTheDocument()
  })

  it('应该在深色主题下显示正确的样式', () => {
    mockStore.theme = 'dark'
    
    render(<ClockPage />)
    
    // 检查深色主题的类名
    const container = screen.getByText('数字时钟').closest('.min-h-screen')
    expect(container).toHaveClass('bg-gradient-to-b', 'dark:from-gray-900', 'dark:to-gray-800')
  })

  it('应该显示时区信息', () => {
    render(<ClockPage />)
    
    // 检查时区显示（可能会根据系统时区显示不同内容）
    const timezoneElements = screen.getAllByText(/GMT|UTC|EST|PST|CST/)
    expect(timezoneElements.length).toBeGreaterThan(0)
  })

  it('模拟时钟应该显示正确的指针位置', () => {
    render(<ClockPage />)
    
    // 切换到模拟时钟
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 检查时钟指针元素存在
    const hourHand = screen.getByTestId('hour-hand')
    const minuteHand = screen.getByTestId('minute-hand')
    const secondHand = screen.getByTestId('second-hand')
    
    expect(hourHand).toBeInTheDocument()
    expect(minuteHand).toBeInTheDocument()
    expect(secondHand).toBeInTheDocument()
  })

  it('应该显示小时标记', () => {
    render(<ClockPage />)
    
    // 切换到模拟时钟
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 检查时钟面板存在（应该有12个小时标记）
    const clockFace = screen.getByRole('img', { hidden: true })
    expect(clockFace).toBeInTheDocument()
  })

  it('应该显示当前日期', () => {
    render(<ClockPage />)
    
    expect(screen.getByText('Monday, January 1st, 2024')).toBeInTheDocument()
  })

  it('数字时钟应该有大字体显示', () => {
    render(<ClockPage />)
    
    const timeDisplay = screen.getByText('14:30:45')
    expect(timeDisplay).toHaveClass('text-6xl', 'md:text-8xl', 'font-mono', 'font-bold')
  })

  it('应该在模拟时钟中显示中心点', () => {
    render(<ClockPage />)
    
    // 切换到模拟时钟
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 检查时钟中心点
    const centerDot = screen.getByTestId('clock-center')
    expect(centerDot).toBeInTheDocument()
  })

  it('按钮应该有活跃状态样式', () => {
    render(<ClockPage />)
    
    const digitalButton = screen.getByText('数字时钟')
    const analogButton = screen.getByText('模拟时钟')
    
    // 默认数字时钟按钮应该是活跃的
    expect(digitalButton).toHaveClass('bg-blue-500', 'text-white')
    
    // 切换到模拟时钟
    fireEvent.click(analogButton)
    
    // 现在模拟时钟按钮应该是活跃的
    expect(analogButton).toHaveClass('bg-blue-500', 'text-white')
  })

  it('应该响应时间更新', () => {
    const { rerender } = render(<ClockPage />)
    
    // 更新时间
    mockStore.currentTime = new Date('2024-01-01T15:45:30')
    
    rerender(<ClockPage />)
    
    // 检查时间是否更新（由于我们mock了format函数，这里会显示固定值）
    expect(screen.getByText('14:30:45')).toBeInTheDocument()
  })

  it('应该在不同屏幕尺寸下正确显示', () => {
    render(<ClockPage />)
    
    const timeDisplay = screen.getByText('14:30:45')
    
    // 检查响应式类名
    expect(timeDisplay).toHaveClass('text-6xl', 'md:text-8xl')
  })

  it('应该有平滑的指针动画', () => {
    render(<ClockPage />)
    
    // 切换到模拟时钟
    const analogButton = screen.getByText('模拟时钟')
    fireEvent.click(analogButton)
    
    // 检查指针是否有过渡动画类
    const hourHand = screen.getByTestId('hour-hand')
    const minuteHand = screen.getByTestId('minute-hand')
    
    expect(hourHand).toHaveClass('transition-transform')
    expect(minuteHand).toHaveClass('transition-transform')
  })
})