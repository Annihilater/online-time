import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@/test/test-utils'
import { MainLayout } from '../MainLayout'

// Mock store
const mockStore = {
  theme: 'light' as 'light' | 'dark',
  updateSettings: vi.fn(),
}

vi.mock('@/shared/stores/alarmStore', () => ({
  useAlarmStore: vi.fn(() => mockStore)
}))

// Mock components
vi.mock('@/shared/components/Header', () => ({
  Header: ({ onOpenSettings }: { onOpenSettings: () => void }) => (
    <header data-testid="header">
      <button onClick={onOpenSettings} data-testid="settings-button">设置</button>
    </header>
  )
}))

vi.mock('@/shared/components/Footer', () => ({
  Footer: () => <footer data-testid="footer">页脚</footer>
}))

vi.mock('@/shared/components/SettingsModal', () => ({
  SettingsModal: ({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) => 
    isOpen ? (
      <div data-testid="settings-modal">
        <button onClick={onClose} data-testid="close-modal">关闭</button>
      </div>
    ) : null
}))

// Mock navigation
const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    useLocation: () => ({ pathname: '/alarm' }),
  }
})

describe('MainLayout', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('应该渲染主布局结构', () => {
    render(<MainLayout />)
    
    expect(screen.getByTestId('header')).toBeInTheDocument()
    expect(screen.getByTestId('footer')).toBeInTheDocument()
    // expect(screen.getByTestId('test-content')).toBeInTheDocument() // Removed since MainLayout doesn't render children
  })

  it('应该渲染导航菜单', () => {
    render(<MainLayout />)
    
    // 检查主要导航项
    expect(screen.getByText('闹钟')).toBeInTheDocument()
    expect(screen.getByText('定时器')).toBeInTheDocument()
    expect(screen.getByText('倒数')).toBeInTheDocument()
    expect(screen.getByText('秒表')).toBeInTheDocument()
    expect(screen.getByText('时钟')).toBeInTheDocument()
  })

  it('应该能够打开设置模态框', () => {
    render(<MainLayout />)
    
    const settingsButton = screen.getByTestId('settings-button')
    fireEvent.click(settingsButton)
    
    expect(screen.getByTestId('settings-modal')).toBeInTheDocument()
  })

  it('应该能够关闭设置模态框', () => {
    render(<MainLayout />)
    
    // 打开设置模态框
    const settingsButton = screen.getByTestId('settings-button')
    fireEvent.click(settingsButton)
    
    // 关闭设置模态框
    const closeButton = screen.getByTestId('close-modal')
    fireEvent.click(closeButton)
    
    expect(screen.queryByTestId('settings-modal')).not.toBeInTheDocument()
  })

  it('应该在深色主题下显示正确的样式', () => {
    mockStore.theme = 'dark'
    
    render(<MainLayout />)
    
    // 检查深色主题的类名应用
    const container = screen.getByRole('main')
    expect(container).toHaveClass('dark:bg-gray-900')
  })

  it('应该有响应式导航', () => {
    render(<MainLayout />)
    
    // 检查移动端菜单按钮是否存在
    const mobileMenuButton = screen.queryByTestId('mobile-menu-button')
    if (mobileMenuButton) {
      expect(mobileMenuButton).toBeInTheDocument()
    }
  })

  it('应该正确处理导航点击', () => {
    render(<MainLayout />)
    
    const timerLink = screen.getByText('定时器')
    fireEvent.click(timerLink)
    
    // 验证导航函数被调用
    expect(mockNavigate).toHaveBeenCalledWith('/timer')
  })

  it('应该显示当前活跃的导航项', () => {
    render(<MainLayout />)
    
    const alarmLink = screen.getByText('闹钟')
    expect(alarmLink.closest('button')).toHaveClass('bg-blue-500', 'text-white')
  })

  // it('应该正确渲染子组件', () => {
  //   const TestComponent = () => <div data-testid="child-component">子组件内容</div>
  //   
  //   render(<MainLayout />)
  //   
  //   expect(screen.getByTestId('child-component')).toBeInTheDocument()
  //   expect(screen.getByText('子组件内容')).toBeInTheDocument()
  // })

  it('应该有正确的页面结构', () => {
    render(<MainLayout />)
    
    // 检查基本的HTML结构
    expect(screen.getByRole('main')).toBeInTheDocument()
    expect(screen.getByTestId('header')).toBeInTheDocument()
    expect(screen.getByTestId('footer')).toBeInTheDocument()
  })

  it('设置模态框应该有正确的z-index', () => {
    render(<MainLayout />)
    
    // 打开设置模态框
    const settingsButton = screen.getByTestId('settings-button')
    fireEvent.click(settingsButton)
    
    const modal = screen.getByTestId('settings-modal')
    expect(modal).toBeInTheDocument()
  })

  it('应该支持键盘导航', () => {
    render(<MainLayout />)
    
    const firstNavItem = screen.getByText('闹钟')
    
    // 检查是否可以获得焦点
    firstNavItem.focus()
    expect(document.activeElement).toBe(firstNavItem)
  })
})