# 开发者快速参考指南

## 一分钟快速上手

```bash
# 克隆并设置项目
git clone <project-url>
cd online-time
make setup              # 一键设置开发环境
make dev                # 启动开发服务器 (http://localhost:3000)
```

## 核心命令速查

### 开发常用
```bash
make dev                # 🚀 启动开发环境
make build              # 🔨 构建生产版本
make test               # 🧪 运行测试
make lint               # 🔍 代码检查
```

### 问题排查
```bash
make status             # 📊 项目状态检查
make clean              # 🧹 清理缓存
make fix                # 🔧 快速修复
make reset              # 🔄 完全重置
```

## 项目结构速览

```
src/
├── pages/              # 9个功能页面
│   ├── AlarmPage.tsx          # 在线闹钟 (/)
│   ├── TimerPage.tsx          # 定时器 (/timer)
│   ├── CountdownPage.tsx      # 倒计时 (/countdown)
│   ├── StopwatchPage.tsx      # 秒表 (/stopwatch)
│   ├── ClockPage.tsx          # 时钟 (/clock)
│   ├── WorldTimePage.tsx      # 世界时间 (/world-time)
│   ├── DateCalculatorPage.tsx # 日期计算器 (/date-calculator)
│   ├── HoursCalculatorPage.tsx # 小时计算器 (/hours-calculator)
│   └── WeekNumbersPage.tsx    # 周数计算器 (/week-numbers)
├── shared/             # 共享资源
│   ├── components/     # 通用组件
│   ├── hooks/          # 自定义钩子
│   ├── stores/         # 状态管理
│   └── utils/          # 工具函数
└── layouts/            # 布局组件
```

## 技术栈速查

### 核心框架
- **React 19**: 前端框架
- **TypeScript**: 类型安全
- **Vite**: 构建工具
- **Zustand**: 状态管理

### UI框架
- **Tailwind CSS**: 样式框架
- **DaisyUI**: 组件库
- **Lucide React**: 图标库

### 工具链
- **ESLint**: 代码规范
- **Vitest**: 测试框架
- **React Router**: 路由管理

## 常用代码片段

### 新建页面组件
```typescript
import React from 'react';

interface PageProps {
  // 定义props类型
}

const NewPage: React.FC<PageProps> = () => {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">页面标题</h1>
      {/* 页面内容 */}
    </div>
  );
};

export default NewPage;
```

### 自定义钩子
```typescript
import { useState, useEffect } from 'react';

export const useCustomHook = (initialValue: any) => {
  const [value, setValue] = useState(initialValue);
  
  useEffect(() => {
    // 副作用逻辑
  }, []);
  
  return { value, setValue };
};
```

### Zustand状态管理
```typescript
import { create } from 'zustand';

interface StoreState {
  // 状态类型定义
}

export const useStore = create<StoreState>((set, get) => ({
  // 状态和方法定义
}));
```

## 样式规范

### Tailwind类名组织
```typescript
// ✅ 好的实践 - 使用cn工具函数
const buttonClasses = cn(
  'btn',                    // 基础样式
  isActive && 'btn-primary', // 条件样式
  size === 'large' && 'btn-lg', // 变体样式
  className                 // 外部传入样式
);
```

### 响应式设计
```css
/* 移动端优先 */
.component {
  @apply p-4;           /* 默认 */
  @apply md:p-6;        /* 平板及以上 */
  @apply lg:p-8;        /* 桌面及以上 */
}
```

## 测试规范

### 组件测试
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import Component from './Component';

describe('Component', () => {
  it('should render correctly', () => {
    render(<Component />);
    expect(screen.getByText('预期文本')).toBeInTheDocument();
  });
  
  it('should handle click events', () => {
    render(<Component />);
    fireEvent.click(screen.getByRole('button'));
    // 断言结果
  });
});
```

### 钩子测试
```typescript
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useCustomHook } from './useCustomHook';

describe('useCustomHook', () => {
  it('should return initial value', () => {
    const { result } = renderHook(() => useCustomHook('initial'));
    expect(result.current.value).toBe('initial');
  });
});
```

## Git工作流程

### 标准提交流程
```bash
# 1. 检查状态
git status
make lint               # 代码检查
make test:run          # 运行测试

# 2. 提交代码
git add .
git commit -m "feat: 添加新功能"

# 3. 推送代码
git push origin master
```

### 提交信息规范
```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 样式修改
refactor: 重构代码
test: 测试相关
chore: 构建过程或辅助工具变动
```

## 性能优化检查清单

### 构建优化
- [ ] Bundle大小 < 500KB (已配置警告)
- [ ] 代码分割正常工作
- [ ] 静态资源压缩
- [ ] 图片资源优化

### 运行时优化
- [ ] 组件懒加载
- [ ] React.memo 使用
- [ ] useMemo/useCallback 优化
- [ ] 避免不必要的重渲染

## 故障排除速查

### 常见问题及解决方案

#### 构建失败
```bash
make clean              # 清理缓存
npm ci                  # 重新安装依赖
make build              # 重新构建
```

#### 测试失败
```bash
make test:run           # 运行所有测试
npm run test:coverage   # 查看覆盖率
```

#### 端口冲突
```bash
# 使用不同端口启动
npm run dev -- --port 3001
```

#### TypeScript错误
```bash
npx tsc --noEmit        # 只检查类型，不生成文件
```

## 部署检查清单

### 部署前验证
- [ ] `make ci-check` 通过
- [ ] 构建大小合理 (`make perf`)
- [ ] 所有测试通过
- [ ] 代码规范检查通过
- [ ] 功能手动验证

### 部署命令 (根据平台选择)
```bash
# Vercel
vercel --prod

# Netlify  
netlify deploy --prod --dir=dist

# 自定义服务器
rsync -av dist/ user@server:/var/www/html/
```

## VS Code配置

### 推荐扩展
- Tailwind CSS IntelliSense
- Prettier
- ESLint
- TypeScript Hero
- Vitest Explorer

### 快捷键
- `Ctrl/Cmd + Shift + P`: 命令面板
- `Ctrl/Cmd + /`: 切换注释
- `Alt + Shift + F`: 格式化代码
- `F5`: 启动调试

## 有用的链接

- **本地开发**: http://localhost:3000
- **Vite文档**: https://vitejs.dev
- **React文档**: https://react.dev
- **Tailwind文档**: https://tailwindcss.com
- **DaisyUI组件**: https://daisyui.com

## 获取帮助

```bash
make help               # 查看所有可用命令
make status             # 检查项目状态
make deps               # 检查依赖状态
```

**记住**: 当遇到问题时，首先尝试 `make fix` - 它能解决大部分常见问题！