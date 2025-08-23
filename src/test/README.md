# 测试框架说明

本项目已成功搭建了基于 Vitest + React Testing Library 的完整自动化测试框架。

## 测试环境配置

### 已安装的依赖
- **vitest**: 与 Vite 深度集成的测试框架
- **@testing-library/react**: React 组件测试库
- **@testing-library/jest-dom**: 额外的 DOM 断言
- **@testing-library/user-event**: 用户事件模拟
- **jsdom**: 浏览器环境模拟
- **happy-dom**: 更快的 DOM 实现（备选）
- **@vitest/coverage-v8**: 代码覆盖率报告

### 配置文件
- `/vitest.config.ts`: Vitest 主配置文件
- `/src/test/setup.ts`: 测试环境初始化
- `/src/test/test-utils.tsx`: 测试工具函数
- `/src/test/fixtures.ts`: 测试数据和 Mock 对象

## Mock 功能

### 浏览器 API Mock
- ✅ AudioContext / webkitAudioContext
- ✅ Notification API
- ✅ Wake Lock API
- ✅ localStorage / sessionStorage
- ✅ requestAnimationFrame
- ✅ matchMedia
- ✅ ResizeObserver / IntersectionObserver

### 音频相关 Mock
```typescript
// 创建 Mock 音频引擎
const mockAudioEngine = createMockAudioEngine()
mockAudioEngine.play.mockResolvedValue(undefined)
```

### 时间相关 Mock
```typescript
// Mock 当前时间
mockCurrentTime(8, 30, 0) // 08:30:00

// Mock 特定日期
mockDate('2024-01-01T10:00:00')
```

## 测试命令

```bash
# 运行所有测试
npm test

# 运行测试并监听文件变化
npm run test:watch

# 运行一次测试（CI 模式）
npm run test:run

# 运行测试并生成覆盖率报告
npm run test:coverage

# 启动测试 UI 界面
npm run test:ui
```

## 测试文件结构

```
src/
├── test/
│   ├── __tests__/          # 通用测试
│   │   └── environment.test.ts
│   ├── setup.ts            # 测试环境初始化
│   ├── test-utils.tsx      # 测试工具函数
│   ├── fixtures.ts         # 测试数据
│   └── README.md           # 本文档
├── shared/
│   ├── components/__tests__/    # 组件测试
│   │   ├── AlarmClock.test.tsx
│   │   └── AlarmList.test.tsx
│   ├── hooks/__tests__/         # Hook 测试
│   │   └── useTimer.test.ts
│   └── stores/__tests__/        # Store 测试
│       └── alarmStore.test.ts
```

## 测试最佳实践

### 组件测试
```typescript
import { render, screen, fireEvent } from '@/test/test-utils'
import { MyComponent } from '../MyComponent'

describe('MyComponent', () => {
  it('应该渲染正确的内容', () => {
    render(<MyComponent />)
    expect(screen.getByText('预期文本')).toBeInTheDocument()
  })
})
```

### Store 测试
```typescript
import { useMyStore } from '../myStore'

describe('MyStore', () => {
  beforeEach(() => {
    useMyStore.getState().reset() // 重置状态
  })

  it('应该正确更新状态', () => {
    const { setState } = useMyStore.getState()
    act(() => {
      setState({ value: 'new value' })
    })
    expect(useMyStore.getState().value).toBe('new value')
  })
})
```

### Hook 测试
```typescript
import { renderHook } from '@testing-library/react'
import { useMyHook } from '../useMyHook'

describe('useMyHook', () => {
  it('应该返回正确的值', () => {
    const { result } = renderHook(() => useMyHook())
    expect(result.current.value).toBe('expected')
  })
})
```

## 覆盖率目标

当前配置的覆盖率阈值：
- 分支覆盖率：70%
- 函数覆盖率：70%
- 代码行覆盖率：70%
- 语句覆盖率：70%

## 示例测试

项目包含以下测试示例：

1. **环境测试** (`src/test/__tests__/environment.test.ts`)
   - 验证测试环境的基本功能
   - Mock 功能验证
   - 浏览器 API Mock 验证

2. **Store 测试** (`src/shared/stores/__tests__/alarmStore.test.ts`)
   - 闹钟状态管理测试
   - 闹钟触发逻辑测试
   - 设置和持久化测试

3. **组件测试** (`src/shared/components/__tests__/`)
   - UI 渲染测试
   - 用户交互测试
   - 主题和样式测试

4. **Hook 测试** (`src/shared/hooks/__tests__/`)
   - 定时器功能测试
   - 生命周期测试
   - 副作用处理测试

## 调试提示

1. 使用 `npm run test:ui` 启动可视化测试界面
2. 在测试中使用 `screen.debug()` 查看当前 DOM
3. 使用 `vi.spyOn(console, 'error').mockImplementation(() => {})` 忽略预期的错误日志
4. 对于异步测试使用 `waitFor` 或 `findBy*` 方法

## CI/CD 集成

测试框架已为 CI/CD 准备就绪：
- 使用 `npm run test:run` 进行一次性测试
- 覆盖率报告生成 HTML 文件（`coverage/index.html`）
- 支持 JSON 格式的覆盖率输出用于集成其他工具