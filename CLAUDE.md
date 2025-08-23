# CLAUDE.md - 在线闹钟项目配置

## 项目概况

**项目名称**: Online Time - 在线时间工具集  
**项目类型**: React 19 + TypeScript 单页应用  
**技术栈**: React, TypeScript, Vite, Tailwind CSS, DaisyUI, Zustand  
**项目状态**: 生产就绪 ✅  

### 核心功能

- 9个完整的时间管理工具页面
- 在线闹钟、定时器、倒计时、秒表、时钟
- 世界时间、日期计算器、小时数计算器、周数计算器
- 主题切换、响应式设计、数据持久化、音效系统

### 架构特点

- 模块化组件设计，高度可复用
- 100% TypeScript 覆盖，类型安全
- Zustand 状态管理，简洁高效
- Web Worker 高精度定时器
- 性能优化：代码分割、懒加载、缓存策略

## 开发环境设置

### 快速启动

```bash
# 安装依赖
npm install

# 启动开发服务器 (http://localhost:3001)
npm run dev

# 构建生产版本
npm run build

# 预览构建结果
npm run preview
```

### 环境要求

- Node.js >= 18.0.0
- npm >= 8.0.0
- 现代浏览器支持 ES2020+

## 开发命令参考

### 核心开发命令

```bash
npm run dev          # 启动开发服务器，端口3001，自动打开浏览器
npm run build        # TypeScript编译 + Vite构建，输出到dist/
npm run preview      # 预览构建结果，验证生产版本
```

### 代码质量命令

```bash
npm run lint         # ESLint代码检查，发现潜在问题
npm run lint -- --fix # ESLint自动修复可修复的问题
```

### 测试命令

```bash
npm run test         # Vitest交互式测试模式
npm run test:run     # Vitest单次运行所有测试
npm run test:watch   # Vitest监听模式，文件变化时重新测试
npm run test:ui      # Vitest图形界面测试
npm run test:coverage # 生成测试覆盖率报告
```

### Claude Code 自定义命令

项目已配置Claude Code自定义命令（存储在`.claude/commands/`），简化开发流程：

```bash
# 完整提交流程（推荐）
/commit                       # 执行完整检查：lint + test + build
/feature-commit "feat: 新功能"  # 全流程：检查 + 添加 + 提交
/hotfix-commit "fix: 修复"      # 热修复：快速检查 + 提交

# 快速检查命令
/check                        # 快速检查：lint + test（不构建）
/quality-check                # 全面检查：lint + test + build + status

# 单步操作命令
/status                       # 检查Git仓库状态
/diff                         # 显示文件修改差异
/add                          # 添加所有文件到暂存区
/lint                         # 运行ESLint代码检查
/lint-fix                     # 自动修复ESLint问题
/test                         # 运行完整测试套件
/build                        # 验证生产构建

# 开发辅助命令
/dev-restart                  # 重启开发服务器
/commit-guide                 # 查看完整的提交规范指南
```

**命令设计原则：**
1. **单一职责** - 每个基础命令只做一件事
2. **组合调用** - 复合命令通过shell脚本调用基础命令
3. **清晰依赖** - 组合命令明确显示调用了哪些基础命令

**使用方法：**
1. 在Claude Code中输入`/`可看到所有自定义命令
2. 选择命令后按回车执行
3. 带参数的命令（如`/feature-commit`）会提示输入参数
4. 复合命令会自动调用相关的单一命令

### 传统Git操作（备用）

```bash
# 手动提交流程
git status                    # 检查文件状态
npm run lint                  # 代码规范检查
npm run test:run             # 运行测试套件
npm run build                # 验证构建成功
git add .
git commit -m "feat: 添加新功能描述"
git push origin master
```

## Agent协作配置

### Agent角色分工

#### 1. Frontend Developer Agent

**权限范围**:

- 完整项目读写权限
- 组件开发和功能实现
- 状态管理和路由配置

**主要职责**:

- React组件开发和重构
- TypeScript类型定义
- 业务逻辑实现
- API集成和数据处理

**最佳实践**:

```bash
# 开发前准备
npm run test:run    # 确保现有测试通过
npm run lint        # 代码规范检查

# 开发过程
npm run dev         # 启动开发服务器
# 实时查看修改效果

# 开发完成
npm run test        # 运行相关测试
npm run build       # 验证构建
```

#### 2. UI/UX Designer Agent

**权限范围**:

- 样式文件读写 (CSS, Tailwind)
- 组件界面设计
- 用户体验优化

**主要职责**:

- Tailwind CSS + DaisyUI样式开发
- 响应式设计实现
- 动画效果设计
- 用户交互优化

**设计系统**:

```css
/* 主题色彩 */
primary: #3B82F6    /* 蓝色 */
secondary: #8B5CF6  /* 紫色 */
accent: #10B981     /* 绿色 */
neutral: #374151    /* 深灰 */

/* 断点设置 */
sm: 640px   /* 手机横屏 */
md: 768px   /* 平板 */
lg: 1024px  /* 桌面 */
xl: 1280px  /* 大屏幕 */
```

#### 3. Test Engineer Agent

**权限范围**:

- 测试文件读写 (**tests**/ 目录)
- 测试配置修改
- 测试工具使用

**主要职责**:

- 单元测试编写
- 组件测试
- 集成测试
- 测试覆盖率优化

**测试策略**:

```bash
# 组件测试
src/components/__tests__/
src/pages/__tests__/
src/hooks/__tests__/

# 测试工具
@testing-library/react      # 组件测试
@testing-library/user-event # 用户交互测试
vitest                      # 测试运行器
```

#### 4. Performance Optimizer Agent

**权限范围**:

- 构建配置优化
- 性能监控代码
- 资源优化

**主要职责**:

- Vite配置优化
- 代码分割策略
- 资源加载优化
- 性能监控集成

**优化检查清单**:

- [ ] Bundle大小分析
- [ ] 代码分割效果
- [ ] 图片资源优化
- [ ] 缓存策略验证
- [ ] 首屏加载时间

### Agent协作流程

#### 1. 功能开发流程

```
1. Frontend Developer: 实现功能逻辑
2. UI/UX Designer: 完善界面设计
3. Test Engineer: 编写测试用例
4. Performance Optimizer: 性能优化
5. 集成测试和验收
```

#### 2. 问题修复流程

```
1. 问题识别和分析
2. 相关Agent协作修复
3. 测试验证修复效果
4. 性能影响评估
5. 部署和监控
```

#### 3. 代码审查标准

- **功能性**: 实现符合需求，逻辑正确
- **可读性**: 代码清晰，注释恰当
- **性能**: 无明显性能问题
- **测试**: 关键功能有测试覆盖
- **规范性**: 符合项目代码规范

## 项目结构导航

### 核心目录结构

```
src/
├── layouts/           # 布局组件
│   └── MainLayout.tsx # 主布局：Header + Router + Footer
├── pages/            # 9个功能页面
│   ├── AlarmPage.tsx        # 在线闹钟 (主页)
│   ├── TimerPage.tsx        # 在线定时器
│   ├── CountdownPage.tsx    # 在线倒计时
│   ├── StopwatchPage.tsx    # 在线秒表
│   ├── ClockPage.tsx        # 在线时钟
│   ├── WorldTimePage.tsx    # 世界时间
│   ├── DateCalculatorPage.tsx    # 日期计算器
│   ├── HoursCalculatorPage.tsx   # 小时数计算器
│   └── WeekNumbersPage.tsx       # 周数计算器
├── router/           # 路由配置
│   └── index.tsx     # React Router配置
├── shared/           # 共享资源
│   ├── components/   # 通用组件
│   │   ├── AlarmClock.tsx     # 闹钟核心组件
│   │   ├── AudioVisualizer.tsx # 音频可视化
│   │   ├── Header.tsx         # 导航头部
│   │   ├── Footer.tsx         # 页脚信息
│   │   ├── SettingsModal.tsx  # 设置弹窗
│   │   ├── SoundSelector.tsx  # 音效选择器
│   │   └── TimePicker.tsx     # 时间选择器
│   ├── hooks/        # 自定义钩子
│   │   ├── useTimer.ts        # 定时器钩子
│   │   ├── useAlarmSound.ts   # 音效钩子
│   │   └── useAnimation.ts    # 动画钩子
│   ├── stores/       # Zustand状态管理
│   │   └── alarmStore.ts      # 闹钟状态管理
│   └── utils/        # 工具函数
│       ├── timeUtils.ts       # 时间处理工具
│       ├── audioEngine.ts     # 音频引擎
│       └── precisionTimer.ts  # 高精度定时器
└── test/            # 测试配置
    ├── setup.ts     # 测试环境设置
    └── test-utils.tsx # 测试工具函数
```

### 重要文件说明

#### 配置文件

- `vite.config.ts` - Vite构建配置，已优化性能
- `tailwind.config.js` - Tailwind CSS配置
- `tsconfig.json` - TypeScript配置
- `eslint.config.js` - ESLint代码规范配置
- `vitest.config.ts` - 测试框架配置

#### 入口文件

- `src/main.tsx` - React应用入口
- `src/App.tsx` - 应用根组件
- `index.html` - HTML模板

## 技术栈详解

### React 19 + TypeScript

```typescript
// 组件开发模式
interface ComponentProps {
  // 严格类型定义
}

const Component: React.FC<ComponentProps> = ({ ...props }) => {
  // 使用最新React特性
  return <div>...</div>
}
```

### Zustand 状态管理

```typescript
// 轻量级状态管理
const useStore = create<StoreState>((set) => ({
  // 状态定义
  // 方法定义
}))
```

### Vite 构建优化

- 开发模式：热模块替换，快速启动
- 生产模式：代码分割，资源优化
- 别名配置：@/ 指向 src/

### Tailwind CSS + DaisyUI

- 实用优先的CSS框架
- 预构建组件库
- 深色/浅色主题切换
- 响应式设计支持

## 开发最佳实践

### 1. 组件开发规范

```typescript
// ✅ 好的实践
interface Props {
  title: string;
  isActive?: boolean;
  onAction?: () => void;
}

export const MyComponent: React.FC<Props> = ({ 
  title, 
  isActive = false, 
  onAction 
}) => {
  return (
    <div className="p-4 rounded-lg bg-base-100">
      <h2 className="text-lg font-semibold">{title}</h2>
      {isActive && (
        <button onClick={onAction} className="btn btn-primary">
          Action
        </button>
      )}
    </div>
  );
};
```

### 2. 钩子使用规范

```typescript
// ✅ 自定义钩子
export const useTimer = (initialTime: number) => {
  const [time, setTime] = useState(initialTime);
  const [isRunning, setIsRunning] = useState(false);
  
  // 钩子逻辑...
  
  return { time, isRunning, start, stop, reset };
};
```

### 3. 状态管理模式

```typescript
// ✅ Zustand store
export const useAlarmStore = create<AlarmStore>()((set, get) => ({
  alarms: [],
  addAlarm: (alarm) => set((state) => ({ 
    alarms: [...state.alarms, alarm] 
  })),
  // 其他方法...
}));
```

### 4. 样式组织

```typescript
// ✅ Tailwind类名组织
const buttonClasses = cn(
  'btn',
  isActive ? 'btn-primary' : 'btn-outline',
  isLarge ? 'btn-lg' : 'btn-md',
  className
);
```

## 性能优化策略

### 1. 代码分割

- 页面级别分割：React.lazy + Suspense
- 第三方库分离：Vite配置手动分包
- 动态导入：按需加载组件

### 2. 渲染优化

- React.memo 防止不必要重渲染
- useMemo/useCallback 缓存计算结果
- 虚拟化长列表（如需要）

### 3. 资源优化

- 图片懒加载和压缩
- 音频文件按需加载
- 静态资源CDN加速

### 4. 缓存策略

- Service Worker 缓存
- 浏览器缓存配置
- API数据缓存

## 调试和开发工具

### 1. 浏览器开发工具

- React Developer Tools
- Redux/Zustand DevTools
- Performance 标签页分析

### 2. VS Code推荐扩展

```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next",
    "ms-vscode.vscode-json"
  ]
}
```

### 3. 调试配置

```typescript
// 开发模式调试
if (process.env.NODE_ENV === 'development') {
  console.log('Debug info:', debugInfo);
}
```

## 测试策略

### 1. 单元测试

```typescript
// 组件测试
describe('TimerComponent', () => {
  it('should start timer correctly', () => {
    render(<TimerComponent />);
    const startButton = screen.getByText('Start');
    fireEvent.click(startButton);
    // 断言...
  });
});
```

### 2. 集成测试

- 页面级别功能测试
- 路由导航测试
- 状态管理集成测试

### 3. E2E测试建议

- 用户完整流程测试
- 跨浏览器兼容性测试
- 移动端响应式测试

## 部署指南

### 1. 生产构建

```bash
# 构建命令
npm run build

# 验证构建结果
npm run preview

# 构建输出
dist/
├── assets/     # 静态资源
├── sounds/     # 音频文件
└── index.html  # 入口文件
```

### 2. 部署选项

#### 静态托管

- **Vercel**: 零配置部署，自动CI/CD
- **Netlify**: 拖拽部署，表单处理
- **GitHub Pages**: 免费，适合演示

#### CDN部署

```bash
# 上传到CDN
aws s3 sync dist/ s3://bucket-name/
# 或
ali oss sync dist/ oss://bucket-name/
```

#### Docker容器化

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 3. 环境变量配置

```bash
# .env.production
VITE_APP_TITLE="Online Time Tools"
VITE_API_BASE_URL="https://api.example.com"
```

## 故障排除

### 1. 常见问题

#### 构建失败

```bash
# 清理缓存
rm -rf node_modules package-lock.json
npm install

# TypeScript错误
npx tsc --noEmit
```

#### 开发服务器问题

```bash
# 端口冲突
npm run dev -- --port 3001

# 清理Vite缓存
rm -rf node_modules/.vite
```

#### 音频播放问题

- 检查浏览器自动播放策略
- 确认音频文件路径正确
- 验证音频格式支持

### 2. 性能问题诊断

```bash
# Bundle分析
npm run build -- --analyze

# 内存泄漏检查
# 使用浏览器Performance工具

# 网络请求优化
# 使用Network面板分析
```

### 3. 兼容性问题

- 检查 browserlist 配置
- 验证 polyfill 是否需要
- 测试目标浏览器版本

## 扩展开发指南

### 1. 添加新页面

```typescript
// 1. 创建页面组件
// src/pages/NewPage.tsx

// 2. 添加路由配置
// src/router/index.tsx

// 3. 更新导航
// src/shared/components/Header.tsx
```

### 2. 集成新功能

- 评估现有架构适配性
- 添加必要的依赖
- 更新类型定义
- 编写测试用例

### 3. 第三方库集成

```bash
# 安装依赖
npm install library-name
npm install --save-dev @types/library-name

# 配置集成
# 更新 vite.config.ts optimizeDeps
```

## 项目维护

### 1. 依赖更新

```bash
# 检查过时依赖
npm outdated

# 更新依赖
npm update

# 主要依赖升级
npm install react@latest
```

### 2. 安全检查

```bash
# 安全审计
npm audit

# 修复安全问题
npm audit fix
```

### 3. 性能监控

- 定期构建分析
- 用户体验指标监控
- 错误日志收集

## 团队协作

### 1. 代码规范

- ESLint + Prettier 统一格式
- 提交信息规范
- 分支管理策略

### 2. 文档更新

- README 维护
- API 文档更新
- 变更日志记录

### 3. 代码审查清单

- [ ] 功能实现正确
- [ ] 代码风格规范
- [ ] 类型定义完整
- [ ] 测试覆盖充分
- [ ] 性能影响评估
- [ ] 兼容性考虑

---

## 快速参考

### 常用命令

```bash
npm run dev        # 开发模式
npm run build      # 生产构建
npm run test       # 运行测试
npm run lint       # 代码检查
```

### 项目信息

- **端口**: 3001 (开发)
- **构建目录**: dist/
- **测试框架**: Vitest
- **样式方案**: Tailwind + DaisyUI

### 联系方式

- **技术支持**: Claude Code
- **项目位置**: /Users/ziji/github/online-time
- **文档**: 项目根目录各类.md文件

---

## Claude Code 使用指南

### 什么是Claude Code？

Claude Code是Anthropic官方的CLI工具，为开发者提供AI驱动的代码助手功能。与网络传言不同，Claude Code实际上是一个简洁而强大的工具。

### 实际功能特性

Claude Code提供以下核心功能：

#### 1. 智能代码协助

- 代码解释和分析
- 代码重构建议
- Bug修复建议
- 代码优化指导

#### 2. 项目理解

- 基于CLAUDE.md配置理解项目结构
- 遵循项目特定的编码规范
- 提供上下文相关的建议

#### 3. 多语言支持

- 原生支持JavaScript/TypeScript
- 理解React、Vue、Angular等框架
- 支持Python、Go、Rust等多种语言

### 使用最佳实践

#### 1. 项目配置优化

- 保持CLAUDE.md文件更新
- 明确项目的技术栈和架构
- 定义清晰的编码规范

#### 2. 有效的交互方式

```bash
# 询问代码改进建议
"如何优化这个React组件的性能？"

# 请求代码解释
"请解释这个函数的工作原理"

# 寻求调试帮助
"这个错误的可能原因是什么？"
```

#### 3. 项目特定指导

- 提供足够的上下文信息
- 引用项目文档和规范
- 描述具体的业务需求

### 实际配置示例

#### VS Code集成

```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next"
  ]
}
```

#### 开发工作流

1. **问题识别**: 使用Claude Code分析代码问题
2. **解决方案**: 获取针对性的修复建议
3. **代码审查**: 让Claude Code检查代码质量
4. **文档生成**: 协助编写技术文档

### 注意事项

#### 避免的误区

- Claude Code不是独立的CLI命令行工具
- 没有npm包需要全局安装
- 不存在`claude-code`命令
- 不需要API密钥配置

#### 实际使用方式

- 通过官方界面与Claude Code交互
- 基于CLAUDE.md配置提供项目上下文
- 利用对话形式获取编程协助
- 集成到开发工作流中

### 故障排除

#### 常见问题

1. **响应不够准确**: 检查CLAUDE.md配置是否完整
2. **缺乏上下文**: 提供更多项目背景信息
3. **建议不合适**: 明确指定技术约束和要求

#### 优化建议

- 定期更新项目文档
- 保持代码结构清晰
- 使用描述性的变量和函数名
- 添加必要的注释和文档

### 进阶用法

#### 1. 架构设计讨论

"请评估这个组件架构的可扩展性"

#### 2. 性能优化咨询

"如何减少这个页面的加载时间？"

#### 3. 测试策略制定

"为这个功能设计测试用例"

#### 4. 代码重构指导

"如何将这个组件拆分为更小的部分？"

---

**最后更新**: 2025-08-23  
**配置版本**: 1.0.0  
**项目状态**: 生产就绪 ✅
