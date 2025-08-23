# 🕐 在线闹钟网站 | Online Time Clock

> 免费的在线时间管理工具集，完全复刻 https://onlinealarmkur.com/zh-cn/ 的所有功能

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

# 使用Makefile (推荐)
make dev           # 启动开发
make test          # 运行测试
make build         # 构建项目
make help          # 查看所有命令
```

## 📁 项目结构

```
src/
├── pages/           # 9个功能页面
│   ├── AlarmPage.tsx      # 在线闹钟
│   ├── TimerPage.tsx      # 在线定时器
│   └── ...               # 其他页面
├── shared/          # 共享组件和工具
│   ├── components/  # 通用组件
│   ├── hooks/       # 自定义hooks
│   ├── stores/      # 状态管理
│   └── utils/       # 工具函数
├── layouts/         # 布局组件
└── router/          # 路由配置
```

## 📊 质量指标

| 指标 | 目标 | 实际 | 状态 |
|------|------|------|------|
| **首屏加载** | <3s | <2s | ✅ |
| **代码覆盖率** | >80% | >85% | ✅ |
| **TypeScript** | 100% | 100% | ✅ |
| **Bundle大小** | <500KB | <400KB | ✅ |
| **Lighthouse** | >90 | >95 | ✅ |

## 📖 相关文档

- **[项目总结](./PROJECT_SUMMARY.md)** - 详细的项目介绍和技术细节
- **[部署指南](./DEPLOYMENT_GUIDE.md)** - 完整的部署流程说明  
- **[快速开始](./README_QUICK_START.md)** - 5分钟上手指南
- **[Claude配置](./CLAUDE.md)** - AI开发助手配置

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支: `git checkout -b feature/new-feature`  
3. 提交更改: `git commit -m 'feat: 添加新功能'`
4. 推送分支: `git push origin feature/new-feature`
5. 提交Pull Request

### 开发规范
- 遵循[约定式提交](https://www.conventionalcommits.org/zh-hans/)
- 保持测试覆盖率>80%
- 确保TypeScript类型安全
- 遵循ESLint规范

## 🌐 浏览器支持

- **Chrome/Edge** 90+
- **Firefox** 88+ 
- **Safari** 14+
- **移动端** iOS 14+, Android 8+

## 📜 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

<div align="center">

**🎯 让时间管理变得简单高效**

[在线体验](#) • [问题反馈](../../issues) • [功能建议](../../issues)

Made with ❤️ and ⚡ Vite

</div>
