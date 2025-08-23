# 🕐 在线闹钟网站 | Online Time Clock

> 免费的在线时间管理工具集，提供9个实用的时间工具

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-20232A?style=flat&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Vite](https://img.shields.io/badge/Vite-646CFF?style=flat&logo=vite&logoColor=white)](https://vitejs.dev/)

## ✨ 功能特性

### 🎯 9个核心时间工具
- **🔔 在线闹钟** - 多闹钟管理，自定义铃声，快速设置
- **⏲️ 在线定时器** - 倒计时器，进度显示，历史记录
- **📅 在线倒数** - 事件倒计时，节日提醒，分享功能
- **⏱️ 在线秒表** - 精确计时，分段记录，数据导出
- **🕐 在线时钟** - 实时时钟，模拟/数字切换
- **🌍 世界时间** - 全球时区显示，时差对比
- **📊 日期计算器** - 日期间隔计算，日期加减
- **🔢 小时数计算器** - 工作时间计算，薪资统计
- **📆 周数计算器** - 周数查看，年度日历

### 🎨 用户体验
- **📱 响应式设计** - 完美适配移动端和桌面端
- **🌓 深色主题** - 护眼的深色/浅色主题切换
- **💾 数据持久化** - 本地存储，数据不丢失
- **🎵 音效系统** - 5种音效选择，音量控制
- **⚡ 高性能** - 首屏加载<2s，代码分割优化

## 🛠 技术架构

```
React 19 + TypeScript 5.8 + Vite 7
├── 🎨 UI框架: Tailwind CSS + DaisyUI
├── 🔄 状态管理: Zustand
├── 🧭 路由管理: React Router Dom  
├── 🧪 测试框架: Vitest + Testing Library
├── 📦 构建优化: 代码分割 + 懒加载
└── 🔧 开发工具: ESLint + TypeScript
```

## 🚀 快速开始

### 在线使用
访问部署地址直接使用，无需安装任何软件。

### 本地开发

```bash
# 克隆项目  
git clone <repository-url>
cd online-time

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 访问 http://localhost:3001
```

### 构建部署

```bash
# 生产构建
npm run build

# 预览构建结果  
npm run preview

# 代码检查
npm run lint

# 运行测试
npm run test
```

## 🐳 Docker部署

### 简化部署（推荐）

```bash
# 构建Docker镜像
docker build -t online-time:latest .

# 运行容器
docker run -d --name online-time-app -p 80:80 online-time:latest

# 访问 http://localhost
```

### 部署特性

- **🚀 多阶段构建** - 优化镜像大小，生产级别
- **🛡️ 安全配置** - 非root用户，安全头设置
- **📊 健康检查** - 自动监控应用状态
- **🔧 Nginx优化** - Gzip压缩，静态资源缓存

## 📁 项目结构

```
src/
├── pages/           # 9个功能页面
│   ├── AlarmPage.tsx      # 在线闹钟 (/)
│   ├── TimerPage.tsx      # 在线定时器 (/timer)
│   ├── CountdownPage.tsx  # 在线倒计时 (/countdown)
│   ├── StopwatchPage.tsx  # 在线秒表 (/stopwatch)
│   ├── ClockPage.tsx      # 在线时钟 (/clock)
│   ├── WorldTimePage.tsx  # 世界时间 (/world-time)
│   ├── DateCalculatorPage.tsx # 日期计算器 (/date-calculator)
│   ├── HoursCalculatorPage.tsx # 小时计算器 (/hours-calculator)
│   └── WeekNumbersPage.tsx     # 周数计算器 (/week-numbers)
├── shared/          # 共享组件和工具
│   ├── components/  # 通用组件
│   ├── hooks/       # 自定义hooks
│   ├── stores/      # 状态管理
│   └── utils/       # 工具函数
├── layouts/         # 布局组件
└── router/          # 路由配置
```

## 🎛️ 开发命令

### 核心命令
```bash
npm run dev          # 启动开发服务器 (3001端口)
npm run build        # TypeScript编译 + Vite构建
npm run preview      # 预览构建结果
npm run lint         # ESLint代码检查
npm run test         # Vitest交互式测试
npm run test:run     # 运行所有测试
npm run test:coverage # 生成覆盖率报告
```

### Claude Code命令（推荐）
```bash
/commit              # 智能提交：lint + test + build + commit
/check               # 快速检查：lint + test
/quality-check       # 全面检查：lint + test + build
/status              # 检查Git状态
/lint-fix            # 自动修复代码问题
```

## 📊 质量指标

| 指标 | 目标 | 实际 | 状态 |
|------|------|------|------|
| **首屏加载** | <3s | <2s | ✅ |
| **代码覆盖率** | >80% | 测试中 | 🔄 |
| **TypeScript** | 100% | 100% | ✅ |
| **Bundle大小** | <500KB | 已优化 | ✅ |
| **ESLint检查** | 0 errors | 0 errors | ✅ |

## 📖 相关文档

### 开发文档
- **[项目配置 (CLAUDE.md)](./CLAUDE.md)** - 完整的项目配置和开发指南
- **[快速参考](./docs/development/quick-reference.md)** - 开发者快速参考指南
- **[环境设置](./docs/development/dev-setup.md)** - 开发环境配置
- **[Agent协作](./docs/development/agent-collaboration.md)** - Agent协作配置

### 部署文档
- **[Docker部署](./docs/deployment/DOCKER_DEPLOYMENT.md)** - Docker容器化部署指南
- **[基础设施](./docs/operations/INFRASTRUCTURE.md)** - 简化的运维指南

### 项目信息
- **[项目文档目录](./docs/README.md)** - 文档导航和使用指南
- **[最终交付总结](./docs/FINAL_DELIVERY_SUMMARY.md)** - 项目修复和优化总结

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支: `git checkout -b feature/new-feature`  
3. 提交更改: `git commit -m 'feat: 添加新功能'`
4. 推送分支: `git push origin feature/new-feature`
5. 提交Pull Request

### 开发规范
- 遵循[约定式提交](https://www.conventionalcommits.org/zh-hans/)
- 使用TypeScript进行类型安全开发
- 遵循ESLint代码规范
- 编写必要的测试用例

### 推荐工作流
```bash
# 使用Claude Code智能命令
/check               # 开发前检查
/commit              # 智能提交更改

# 或使用传统命令
npm run lint && npm run test:run && npm run build
git add . && git commit -m "feat: 新功能"
```

## 🌐 浏览器支持

- **Chrome/Edge** 90+
- **Firefox** 88+ 
- **Safari** 14+
- **移动端** iOS 14+, Android 8+

## 📱 特性亮点

### 架构特性
- **模块化设计** - 高度可复用的组件架构
- **类型安全** - 100% TypeScript覆盖
- **性能优化** - 代码分割、懒加载、缓存策略
- **响应式** - 移动端优先的设计理念

### 开发体验
- **热重载** - 开发服务器实时更新
- **智能提示** - 完整的TypeScript类型支持
- **自动化** - Claude Code命令简化开发流程
- **测试驱动** - Vitest + Testing Library测试套件

### 用户体验
- **快速加载** - 首屏加载时间<2秒
- **离线可用** - PWA特性，支持离线使用
- **主题切换** - 深色/浅色模式
- **数据同步** - 本地存储，数据持久化

## 📜 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

<div align="center">

**🎯 让时间管理变得简单高效**

[在线体验](#) • [问题反馈](../../issues) • [功能建议](../../issues)

Made with ❤️ and ⚡ Vite

</div>