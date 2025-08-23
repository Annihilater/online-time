# 开发环境快速设置命令

## 环境检查和设置

### 检查开发环境

```bash
# 检查Node版本
node --version

# 检查npm版本
npm --version

# 检查项目依赖状态
npm ls --depth=0
```

### 项目初始化

```bash
# 完整的项目设置流程
npm ci                    # 清洁安装依赖
npm run lint             # 代码规范检查
npm run test:run         # 运行测试套件
npm run build            # 验证构建成功
```

## 开发工作流程

### 功能开发流程

```bash
# 1. 开始新功能开发
git checkout -b feature/new-feature
npm run dev              # 启动开发服务器

# 2. 开发过程中的检查
npm run lint             # 代码规范
npm run test             # 交互式测试

# 3. 提交前检查
npm run test:run         # 所有测试
npm run build            # 构建验证
git add .
git commit -m "feat: 添加新功能"

# 4. 合并到主分支
git checkout master
git merge feature/new-feature
```

### 问题排查命令

```bash
# 清理和重新安装
rm -rf node_modules package-lock.json
npm install

# 清理缓存
rm -rf node_modules/.vite
npm run dev

# TypeScript检查
npx tsc --noEmit

# 依赖分析
npm ls
npm outdated
npm audit
```

## 性能优化检查

### 构建分析

```bash
# 构建大小分析
npm run build
ls -la dist/assets/      # 查看文件大小

# 依赖分析
npm run build -- --analyze  # 如果配置了bundle analyzer
```

### 测试覆盖率

```bash
# 生成覆盖率报告
npm run test:coverage

# 查看覆盖率结果
open coverage/index.html  # macOS
# 或者在浏览器中打开 coverage/index.html
```

## 部署准备

### 生产构建检查

```bash
# 完整的部署前检查清单
npm run lint             # ✓ 代码规范
npm run test:run         # ✓ 所有测试通过
npm run build            # ✓ 构建成功
npm run preview          # ✓ 预览构建结果

# 验证构建输出
ls -la dist/
du -sh dist/             # 查看总大小
```

### 部署到不同平台

```bash
# Vercel部署
npx vercel --prod

# Netlify部署
netlify deploy --prod --dir=dist

# GitHub Pages部署
git checkout gh-pages
cp -r dist/* .
git add . && git commit -m "Deploy" && git push
```

## 常用别名设置

可以在 ~/.bashrc 或 ~/.zshrc 中添加这些别名：

```bash
# 在线闹钟项目别名
alias ot="cd /Users/ziji/github/online-time"
alias otdev="cd /Users/ziji/github/online-time && npm run dev"
alias otbuild="cd /Users/ziji/github/online-time && npm run build"
alias ottest="cd /Users/ziji/github/online-time && npm run test"
alias otlint="cd /Users/ziji/github/online-time && npm run lint"
```

使用方法：

- `ot` - 快速进入项目目录
- `otdev` - 快速启动开发环境
- `otbuild` - 快速构建项目
- `ottest` - 快速运行测试
- `otlint` - 快速代码检查
