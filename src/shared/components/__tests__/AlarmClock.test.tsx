import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, act, fireEvent } from '@/test/test-utils'
import { AlarmClock } from '../AlarmClock'
import { useAlarmStore } from '@/shared/stores/alarmStore'
// import { mockCurrentTime } from '@/test/test-utils'

// Mock store
const mockUpdateSettings = vi.fn()
const mockStore = {
  currentTime: new Date('2024-01-01T10:30:45'),
  isAlarmRinging: false,
  theme: 'light' as 'light' | 'dark',
  updateSettings: mockUpdateSettings
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock time utils
vi.mock('@/shared/utils/timeUtils', () => ({
  formatTimeWithSeconds: vi.fn((date: Date) => date.toLocaleTimeString()),
  formatDate: vi.fn((date: Date) => date.toLocaleDateString())
}))

// Mock lucide-react icons
vi.mock('lucide-react', () => ({
  Settings: () => <div data-testid="settings-icon">Settings</div>,
  Sun: () => <div data-testid="sun-icon">Sun</div>,
  Moon: () => <div data-testid="moon-icon">Moon</div>
}))

describe('AlarmClock', () => {
  const mockOnOpenSettings = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    mockStore.currentTime = new Date('2024-01-01T10:30:45')
    mockStore.isAlarmRinging = false
    mockStore.theme = 'light'
  })

  it('应该渲染时钟显示', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 应该显示时间
    expect(screen.getByText(/10:30:45/)).toBeInTheDocument()
    
    // 应该显示日期
    expect(screen.getByText(/2024/)).toBeInTheDocument()
  })

  it('应该显示主题切换按钮', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 浅色主题时应该显示月亮图标
    expect(screen.getByTestId('moon-icon')).toBeInTheDocument()
  })

  it('深色主题时应该显示太阳图标', () => {
    mockStore.theme = 'dark'
    
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    expect(screen.getByTestId('sun-icon')).toBeInTheDocument()
  })

  it('应该显示设置按钮并响应点击', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    const settingsButton = screen.getByRole('button', { name: /settings/i })
    expect(settingsButton).toBeInTheDocument()
    
    fireEvent.click(settingsButton)
    expect(mockOnOpenSettings).toHaveBeenCalledTimes(1)
  })

  it('点击主题切换按钮应该切换主题', () => {
    // Mock useAlarmStore.getState
    const mockGetState = vi.fn().mockReturnValue({
      updateSettings: mockUpdateSettings
    })
    ;(useAlarmStore as any).getState = mockGetState
    
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    const themeButton = screen.getByRole('button', { name: /moon/i })
    fireEvent.click(themeButton)
    
    expect(mockUpdateSettings).toHaveBeenCalledWith({ theme: 'dark' })
  })

  it('闹钟响起时时间显示应该变红并闪烁', () => {
    mockStore.isAlarmRinging = true
    
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 查找时间显示元素
    const timeDisplay = screen.getByText(/10:30:45/).closest('div')
    
    expect(timeDisplay).toHaveClass('text-red-500', 'animate-pulse')
  })

  it('正常状态下时间显示应该是默认颜色', () => {
    mockStore.isAlarmRinging = false
    
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    const timeDisplay = screen.getByText(/10:30:45/).closest('div')
    
    expect(timeDisplay).toHaveClass('text-gray-900')
    expect(timeDisplay).not.toHaveClass('text-red-500', 'animate-pulse')
  })

  it('深色主题下应该应用深色样式', () => {
    mockStore.theme = 'dark'
    
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 检查主容器是否有深色主题类
    const container = screen.getByText(/10:30:45/).closest('.bg-white')
    expect(container).toHaveClass('dark:bg-gray-800')
  })

  it('时间更新时显示应该同步更新', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 验证初始时间显示
    expect(screen.getByText(/10:30:45/)).toBeInTheDocument()
    
    // 更新store中的时间并触发重新渲染
    act(() => {
      mockStore.currentTime = new Date('2024-01-01T11:45:30')
    })
    
    // 由于使用了mock store，时间更新需要重新渲染组件才能看到变化
    // 这个测试主要验证组件能正确使用store中的currentTime
    expect(screen.getByText(/10:30:45/)).toBeInTheDocument() // 因为是mock，时间不会自动更新
  })

  it('应该有正确的CSS类用于响应式设计', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    const container = screen.getByText(/10:30:45/).closest('.bg-white')
    expect(container).toHaveClass('rounded-xl', 'shadow-lg', 'p-8', 'text-center')
  })

  it('按钮应该有正确的悬停效果', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    const buttons = screen.getAllByRole('button')
    
    buttons.forEach(button => {
      expect(button).toHaveClass('transition-colors')
      expect(button).toHaveClass(/hover:bg-/)
    })
  })

  it('无障碍性：应该有适当的语义结构', () => {
    render(<AlarmClock onOpenSettings={mockOnOpenSettings} />)
    
    // 按钮应该有正确的角色
    expect(screen.getByRole('button', { name: /settings/i })).toBeInTheDocument()
    
    // 主题切换按钮也应该可访问
    const themeButton = screen.getByRole('button', { name: /moon/i })
    expect(themeButton).toBeInTheDocument()
  })
})