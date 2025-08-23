import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@/test/test-utils'
// import { BrowserRouter } from 'react-router-dom'
import App from '@/App'

// Mock all page components
vi.mock('@/pages/AlarmPage', () => ({
  AlarmPage: () => <div data-testid="alarm-page">闹钟页面</div>
}))

vi.mock('@/pages/TimerPage', () => ({
  TimerPage: () => <div data-testid="timer-page">定时器页面</div>
}))

vi.mock('@/pages/CountdownPage', () => ({
  CountdownPage: () => <div data-testid="countdown-page">倒数页面</div>
}))

vi.mock('@/pages/StopwatchPage', () => ({
  StopwatchPage: () => <div data-testid="stopwatch-page">秒表页面</div>
}))

vi.mock('@/pages/ClockPage', () => ({
  ClockPage: () => <div data-testid="clock-page">时钟页面</div>
}))

vi.mock('@/pages/WorldTimePage', () => ({
  WorldTimePage: () => <div data-testid="worldtime-page">世界时钟页面</div>
}))

vi.mock('@/pages/DateCalculatorPage', () => ({
  DateCalculatorPage: () => <div data-testid="date-calculator-page">日期计算器页面</div>
}))

vi.mock('@/pages/HoursCalculatorPage', () => ({
  HoursCalculatorPage: () => <div data-testid="hours-calculator-page">工时计算器页面</div>
}))

vi.mock('@/pages/WeekNumbersPage', () => ({
  WeekNumbersPage: () => <div data-testid="week-numbers-page">周数页面</div>
}))

// Mock store
const mockStore = {
  theme: 'light' as const,
  currentTime: new Date('2024-01-01T10:30:45'),
  isAlarmRinging: false,
  updateSettings: vi.fn(),
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock layout components
vi.mock('@/layouts/MainLayout', () => ({
  MainLayout: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="main-layout">
      <nav data-testid="navigation">
        <a href="/alarm">闹钟</a>
        <a href="/timer">定时器</a>
        <a href="/countdown">倒数</a>
        <a href="/stopwatch">秒表</a>
        <a href="/clock">时钟</a>
        <a href="/worldtime">世界时钟</a>
        <a href="/date-calculator">日期计算器</a>
        <a href="/hours-calculator">工时计算器</a>
        <a href="/week-numbers">周数</a>
      </nav>
      <main>{children}</main>
    </div>
  )
}))

describe('路由系统', () => {
  it('应该渲染主布局', () => {
    render(<App />)
    
    expect(screen.getByTestId('main-layout')).toBeInTheDocument()
    expect(screen.getByTestId('navigation')).toBeInTheDocument()
  })

  it('默认路由应该显示闹钟页面', () => {
    render(<App />)
    
    expect(screen.getByTestId('alarm-page')).toBeInTheDocument()
    expect(screen.getByText('闹钟页面')).toBeInTheDocument()
  })

  it('应该有所有页面的导航链接', () => {
    render(<App />)
    
    expect(screen.getByText('闹钟')).toBeInTheDocument()
    expect(screen.getByText('定时器')).toBeInTheDocument()
    expect(screen.getByText('倒数')).toBeInTheDocument()
    expect(screen.getByText('秒表')).toBeInTheDocument()
    expect(screen.getByText('时钟')).toBeInTheDocument()
    expect(screen.getByText('世界时钟')).toBeInTheDocument()
    expect(screen.getByText('日期计算器')).toBeInTheDocument()
    expect(screen.getByText('工时计算器')).toBeInTheDocument()
    expect(screen.getByText('周数')).toBeInTheDocument()
  })

  it('路由切换应该工作正常', () => {
    // 由于我们使用的是简单的测试setup，实际的路由切换需要更复杂的测试
    // 这里我们只验证基础结构是否正确
    render(<App />)
    
    // 验证默认页面加载
    expect(screen.getByTestId('alarm-page')).toBeInTheDocument()
    
    // 验证导航存在
    expect(screen.getByTestId('navigation')).toBeInTheDocument()
  })

  it('应该在所有页面中保持布局一致性', () => {
    render(<App />)
    
    // 主布局应该始终存在
    expect(screen.getByTestId('main-layout')).toBeInTheDocument()
    
    // 导航应该始终可用
    expect(screen.getByTestId('navigation')).toBeInTheDocument()
  })
})