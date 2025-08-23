# 🚀 Just 安装和快速上手指南

## 📦 安装 Just

### macOS
```bash
# 使用 Homebrew (推荐)
brew install just

# 或使用 Cargo
cargo install just
```

### Linux
```bash
# Ubuntu/Debian
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update
sudo apt install just

# Arch Linux
pacman -S just

# 或使用 Cargo
cargo install just
```

### Windows
```bash
# 使用 Chocolatey
choco install just

# 或使用 Scoop
scoop install just

# 或使用 Cargo
cargo install just
```

### 通用方法（所有平台）
```bash
# 从 GitHub 下载
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin

# 确保 ~/bin 在 PATH 中
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## ✅ 验证安装

```bash
# 检查版本
just --version

# 在项目目录中查看可用任务
cd /path/to/online-time
just --list
```

## 🎯 5分钟快速上手

### 1. 基础命令
```bash
# 查看所有可用任务
just --list

# 交互式选择任务
just

# 查看详细帮助
just help
```

### 2. 开发常用命令
```bash
# 启动开发服务器
just dev
# 或使用别名
just d

# 构建生产版本
just build
# 或使用别名  
just b

# 运行测试
just test
# 或使用别名
just t
```

### 3. 代码质量检查
```bash
# 快速检查 (lint + test)
just check
# 或使用别名
just c

# 全面检查 (lint + test + build)
just quality-check

# 只运行 lint
just lint
# 或使用别名
just l
```

### 4. 智能提交流程
```bash
# 执行完整的智能提交流程
just commit

# 快速提交 (带消息)
just commit-msg "feat: 添加新功能"

# 推送代码
just push
```

### 5. Docker 操作
```bash
# 构建 Docker 镜像
just docker-build

# 运行容器 (默认 80 端口)
just docker-run

# 运行在指定端口
just docker-run 8080

# 停止容器
just docker-stop
```

## 🆚 命令对比表

| 功能 | 旧命令 (npm) | 新命令 (Just) | 更短 |
|------|-------------|--------------|------|
| 开发服务器 | `npm run dev` | `just dev` 或 `just d` | ✅ |
| 生产构建 | `npm run build` | `just build` 或 `just b` | ✅ |
| 运行测试 | `npm run test` | `just test` 或 `just t` | ✅ |
| 代码检查 | `npm run lint` | `just lint` 或 `just l` | ✅ |
| 预览构建 | `npm run preview` | `just preview` | ✅ |
| 智能提交 | `./scripts/smart-commit.sh` | `just commit` | ✅ |

## 🎨 高级功能

### 1. 彩色输出
Just 任务包含丰富的彩色输出，让命令执行过程更清晰：
- 🔵 蓝色：一般信息
- 🟢 绿色：成功操作
- 🟡 黄色：警告信息
- 🔴 红色：错误或危险操作
- 🟣 紫色：特殊操作

### 2. 智能别名
```bash
just d    # = just dev
just b    # = just build  
just t    # = just test
just l    # = just lint
just c    # = just check
```

### 3. 项目信息
```bash
# 查看项目信息
just info

# 查看项目统计
just stats

# 项目健康检查
just health
```

### 4. 性能分析
```bash
# 构建性能分析
just perf-build

# Bundle 大小分析
just bundle-analyze

# Lighthouse 性能测试指导
just lighthouse
```

## 🔧 自定义配置

### Tab 补全设置

#### Bash
```bash
# 添加到 ~/.bashrc
echo 'eval "$(just --completions bash)"' >> ~/.bashrc
source ~/.bashrc
```

#### Zsh
```bash
# 添加到 ~/.zshrc
echo 'eval "$(just --completions zsh)"' >> ~/.zshrc
source ~/.zshrc
```

#### Fish
```bash
# 添加到 Fish 配置
just --completions fish > ~/.config/fish/completions/just.fish
```

### VS Code 集成

安装 **Just** 扩展以获得语法高亮和 IntelliSense 支持。

## 📋 迁移检查清单

### ✅ 安装验证
- [ ] Just 成功安装 (`just --version`)
- [ ] Tab 补全配置完成
- [ ] VS Code 扩展安装 (可选)

### ✅ 功能验证
- [ ] 开发服务器启动 (`just dev`)
- [ ] 生产构建成功 (`just build`)
- [ ] 测试执行正常 (`just test-run`)  
- [ ] 代码检查通过 (`just lint`)
- [ ] Docker 操作正常 (`just docker-build`)

### ✅ 工作流验证
- [ ] 快速检查流程 (`just check`)
- [ ] 智能提交流程 (`just commit`)
- [ ] 文档查看正常 (`just help`)

## 🚨 常见问题

### Q1: Just 命令未找到
```bash
# 检查 PATH 设置
echo $PATH

# 查找 just 二进制文件
which just

# 重新安装
brew reinstall just  # macOS
```

### Q2: 权限错误
```bash
# 确保 justfile 可读
chmod +r justfile

# 确保脚本可执行 (如果有)
chmod +x scripts/*.sh
```

### Q3: 与 npm scripts 冲突
```bash
# Just 和 npm scripts 可以并存
# 选择性地使用 Just 命令，保留 npm scripts 作为备用

# 如果要完全迁移，可以清空 package.json 中的 scripts
```

### Q4: 命令不存在
```bash
# 查看所有可用命令
just --list

# 检查 justfile 语法
just --dry-run TASK_NAME
```

## 🎯 最佳实践

### 1. 渐进式采用
- 先用 Just 执行常用命令
- 保留 npm scripts 作为备用
- 逐步习惯新的工作流

### 2. 团队协作
- 在团队中统一使用 Just 命令
- 更新项目文档和 README
- 提供团队培训和支持

### 3. 扩展性考虑
- 为未来多语言项目预留任务空间
- 保持 justfile 的可读性和维护性
- 定期清理不用的任务

## 🔗 有用链接

- [Just 官方文档](https://just.systems/)
- [Just GitHub 仓库](https://github.com/casey/just)
- [Just 配置示例](https://github.com/casey/just/tree/master/examples)

---

## 🎉 开始使用

现在你已经准备好使用 Just 了！试试这些命令：

```bash
# 查看项目信息
just info

# 启动开发环境
just dev

# 享受更高效的开发体验！ 🚀
```