# 在线闹钟 (Online Alarm Clock)

一个功能丰富的在线闹钟应用，完全复刻 https://onlinealarmkur.com/zh-cn/ 的功能和界面。

## 项目特性

- ✅ **实时时钟显示** - 大字体数字时钟，支持12/24小时制
- ✅ **多闹钟管理** - 支持添加多个闹钟，独立控制
- ✅ **快速设置** - 提供5分钟、10分钟、30分钟等快捷按钮
- ✅ **自定义铃声** - 多种内置铃声可选
- ✅ **音量控制** - 可调节闹钟音量
- ✅ **浏览器通知** - 支持系统通知提醒
- ✅ **响应式设计** - 完美适配手机、平板和桌面设备
- ✅ **美观界面** - 采用玻璃拟态设计，梯度背景
- ✅ **主题切换** - 支持明/暗主题模式

## 技术栈

- **前端框架**: React 18 + TypeScript
- **构建工具**: Vite
- **状态管理**: Zustand
- **样式框架**: Tailwind CSS + DaisyUI
- **图标库**: Lucide React
- **时间处理**: date-fns
- **音频管理**: Web Audio API

## 项目结构

```
src/
├── components/          # React 组件
│   ├── AlarmClock.tsx   # 主时钟显示组件
│   ├── TimePicker.tsx   # 时间选择器
│   ├── PresetTimes.tsx  # 快捷时间按钮
│   ├── AlarmList.tsx    # 闹钟列表
│   ├── SettingsModal.tsx # 设置面板
│   └── AlarmRinging.tsx # 闹钟响铃界面
├── hooks/               # 自定义 Hooks
│   ├── useTimer.ts      # 时间更新 Hook
│   └── useAlarmSound.ts # 音频控制 Hook
├── store/               # 状态管理
│   └── alarmStore.ts    # 闹钟状态存储
├── utils/               # 工具函数
│   ├── timeUtils.ts     # 时间处理工具
│   └── audioUtils.ts    # 音频工具
└── assets/              # 静态资源
```

## 开发命令

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 预览构建结果
npm run preview

# 代码检查
npm run lint
```

## 功能说明

### 1. 实时时钟
- 显示当前时间和日期
- 支持12小时制/24小时制切换
- 时区信息显示

### 2. 闹钟设置
- 通过时间选择器设置闹钟
- 可添加闹钟标签
- 支持快速时间设置（5分钟、10分钟等）

### 3. 闹钟管理
- 查看所有设置的闹钟
- 启用/禁用单个闹钟
- 删除不需要的闹钟
- 显示距离闹钟响铃的剩余时间

### 4. 音效设置
- 5种内置铃声可选
- 音量调节滑块
- 铃声试听功能

### 5. 闹钟响铃
- 全屏响铃界面
- 震动动画效果
- 停止和小憩功能
- 浏览器通知

## 浏览器兼容性

- Chrome 60+
- Firefox 55+
- Safari 14+
- Edge 79+

## 部署说明

项目构建后生成静态文件，可以部署到任何静态文件托管服务：

- Vercel (推荐)
- Netlify
- GitHub Pages
- CDN + 对象存储

## 许可证

MIT License - 可自由使用和修改
