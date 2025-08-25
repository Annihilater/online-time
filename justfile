# 🚀 Online Time - Universal Task Runner
# 通用脚手架工具，支持前端/后端/多语言项目扩展

# 设置默认 shell
set shell := ["bash", "-c"]

# 彩色输出设置
RED := '\033[0;31m'
GREEN := '\033[0;32m' 
YELLOW := '\033[0;33m'
BLUE := '\033[0;34m'
PURPLE := '\033[0;35m'
CYAN := '\033[0;36m'
WHITE := '\033[1;37m'
NC := '\033[0m' # No Color

# 项目配置
PROJECT_NAME := "Online Time"
DEV_PORT := "3001"
DOCKER_IMAGE := "online-time"
DOCKER_CONTAINER := "online-time-app"

# 默认任务 - 显示帮助
default:
    @just --choose

# ==========================================
# 🚀 开发任务 (Development Tasks)
# ==========================================

# 启动开发服务器 - 主要开发命令
alias d := dev
dev:
    @echo -e "{{BLUE}}🚀 启动开发服务器 (端口: {{DEV_PORT}})...{{NC}}"
    npm run dev

# 构建生产版本 - 主要构建命令  
alias b := build
build:
    @echo -e "{{GREEN}}🔨 构建生产版本...{{NC}}"
    npm run build
    @echo -e "{{GREEN}}✅ 构建完成！输出目录: dist/{{NC}}"
    @ls -lah dist/

# 预览构建结果
preview:
    @echo -e "{{CYAN}}👀 预览构建结果...{{NC}}"
    npm run preview

# 重启开发服务器
dev-restart:
    @echo -e "{{YELLOW}}🔄 重启开发服务器...{{NC}}"
    @echo "请在当前终端按 Ctrl+C 停止服务器，然后运行 'just dev'"

# ==========================================
# 🔍 代码质量 (Code Quality)
# ==========================================

# 运行代码检查 - 主要检查命令
alias l := lint
lint:
    @echo -e "{{PURPLE}}🔍 运行 ESLint 代码检查...{{NC}}"
    npm run lint

# 自动修复代码问题
lint-fix:
    @echo -e "{{GREEN}}🔧 自动修复 ESLint 问题...{{NC}}"
    npm run lint -- --fix

# 代码格式化 (使用 Prettier)
format:
    @echo -e "{{BLUE}}✨ 格式化代码 (Prettier)...{{NC}}"
    npx prettier --write .

# TypeScript 类型检查
type-check:
    @echo -e "{{PURPLE}}📋 TypeScript 类型检查...{{NC}}"
    npx tsc --noEmit

# ==========================================
# 🧪 测试任务 (Testing Tasks)  
# ==========================================

# 运行交互式测试 - 主要测试命令
alias t := test
test:
    @echo -e "{{CYAN}}🧪 启动交互式测试...{{NC}}"
    npm run test

# 运行所有测试 (非交互)
test-run:
    @echo -e "{{CYAN}}🏃 运行所有测试...{{NC}}"
    npm run test:run

# 生成测试覆盖率报告
test-coverage:
    @echo -e "{{BLUE}}📊 生成测试覆盖率报告...{{NC}}"
    npm run test:coverage
    @echo -e "{{GREEN}}📋 覆盖率报告生成完成: coverage/index.html{{NC}}"

# 启动测试 UI 界面
test-ui:
    @echo -e "{{PURPLE}}🖥️ 启动 Vitest UI 界面...{{NC}}"
    npm run test:ui

# 监听模式运行测试
test-watch:
    @echo -e "{{YELLOW}}👀 监听模式运行测试...{{NC}}"
    npm run test:watch

# ==========================================
# 📦 项目管理 (Project Management)
# ==========================================

# 安装项目依赖
install:
    @echo -e "{{GREEN}}📦 安装项目依赖 (npm ci)...{{NC}}"
    npm ci

# 清理项目缓存和构建文件
clean:
    @echo -e "{{RED}}🧹 清理项目缓存...{{NC}}"
    @echo "清理 Vite 缓存..."
    -rm -rf node_modules/.vite
    @echo "清理构建输出..."
    -rm -rf dist
    @echo "清理测试覆盖率..."
    -rm -rf coverage
    @echo -e "{{GREEN}}✅ 清理完成！{{NC}}"

# 完全重置项目环境
reset: clean
    @echo -e "{{YELLOW}}🔄 完全重置项目环境...{{NC}}"
    @echo "重新安装依赖..."
    npm ci
    @echo -e "{{GREEN}}✅ 项目环境重置完成！{{NC}}"

# 检查依赖更新
deps-check:
    @echo -e "{{CYAN}}🔍 检查依赖更新...{{NC}}"
    npm outdated

# 更新项目依赖
deps-update:
    @echo -e "{{BLUE}}⬆️ 更新项目依赖...{{NC}}"
    npm update

# 安全漏洞检查
security-audit:
    @echo -e "{{RED}}🔒 安全漏洞检查...{{NC}}"
    npm audit

# 自动修复安全漏洞
security-fix:
    @echo -e "{{GREEN}}🛡️ 自动修复安全漏洞...{{NC}}"
    npm audit fix

# ==========================================
# 🎯 组合任务 (Composite Tasks)
# ==========================================

# 快速质量检查 - lint + test (不构建)
alias c := check
check:
    @echo -e "{{BLUE}}⚡ 快速质量检查 (lint + test)...{{NC}}"
    just lint
    just test-run
    @echo -e "{{GREEN}}✅ 快速检查完成！{{NC}}"

# 全面质量检查 - lint + test + build
quality-check:
    @echo -e "{{PURPLE}}🏆 全面质量检查 (lint + test + build)...{{NC}}"
    just lint
    just test-run  
    just build
    @echo -e "{{GREEN}}✅ 全面检查通过！项目可以部署！{{NC}}"

# 部署前检查
deploy-check: quality-check
    @echo -e "{{GREEN}}🎯 部署检查通过！项目已准备好部署。{{NC}}"

# ==========================================
# 📊 Git 和版本控制 (Git & Version Control)
# ==========================================

# 检查 Git 仓库状态
status:
    @echo -e "{{CYAN}}📊 Git 仓库状态:{{NC}}"
    git status --porcelain

# 显示文件修改差异
diff:
    @echo -e "{{YELLOW}}📝 文件修改差异:{{NC}}"
    git diff --name-status

# 添加所有文件到暂存区
add:
    @echo -e "{{GREEN}}➕ 添加文件到暂存区...{{NC}}"
    git add .

# 智能提交流程 - 质量检查 + 提交
commit:
    @echo -e "{{BLUE}}🤖 执行智能提交流程...{{NC}}"
    ./scripts/smart-commit.sh

# 快速提交 (带消息)
commit-msg message:
    @echo -e "{{GREEN}}💬 提交更改: {{message}}{{NC}}"
    just check
    git add .
    git commit -m "{{message}}"
    @echo -e "{{GREEN}}✅ 提交完成！{{NC}}"

# 推送到远程仓库
push:
    @echo -e "{{BLUE}}🚀 推送到远程仓库...{{NC}}"
    git push origin master

# 提交并推送
commit-push: commit push

# ==========================================
# 🐳 Docker 操作 (Docker Operations)
# ==========================================

# 构建 Docker 镜像 (本地)
docker-build:
    @echo -e "{{BLUE}}🐳 构建 Docker 镜像...{{NC}}"
    docker build -t {{DOCKER_IMAGE}}:latest .
    @echo -e "{{GREEN}}✅ Docker 镜像构建完成！{{NC}}"

# 跨平台构建并推送到Docker Hub
docker-build-multi:
    @echo -e "{{BLUE}}🚀 跨平台构建并推送...{{NC}}"
    ./scripts/quick-build.sh
    @echo -e "{{GREEN}}✅ 多架构镜像推送完成！{{NC}}"

# 完整的跨平台构建 (含详细选项)
docker-build-full *args:
    @echo -e "{{BLUE}}🔧 完整跨平台构建...{{NC}}"
    ./scripts/docker-build-push.sh {{args}}
    @echo -e "{{GREEN}}✅ 完整构建完成！{{NC}}"

# 1Panel单容器部署 - 端口9653
alias deploy := deploy-1panel
deploy-1panel:
    @echo -e "{{BLUE}}🚀 1Panel单容器部署 (端口: 9653)...{{NC}}"
    -docker stop {{DOCKER_CONTAINER}} 2>/dev/null || true
    -docker rm {{DOCKER_CONTAINER}} 2>/dev/null || true
    docker build -t {{DOCKER_IMAGE}}:latest .
    docker run -d --name {{DOCKER_CONTAINER}} -p 9653:9653 --restart unless-stopped {{DOCKER_IMAGE}}:latest
    @echo -e "{{GREEN}}✅ 容器已启动！{{NC}}"
    @echo -e "{{CYAN}}📍 内部端口: 9653 (用于1Panel反向代理){{NC}}"
    @echo -e "{{CYAN}}💡 在1Panel中配置反向代理指向: localhost:9653{{NC}}"

# 使用docker-compose部署
deploy-compose:
    @echo -e "{{BLUE}}🐳 使用docker-compose部署...{{NC}}"
    docker-compose -f docker-compose.simple.yml down || true
    docker-compose -f docker-compose.simple.yml up --build -d
    @echo -e "{{GREEN}}✅ 部署完成！端口: 9653{{NC}}"

# 使用deploy目录的生产脚本部署
deploy-prod mode="1panel":
    @echo -e "{{BLUE}}🚀 生产环境部署 (模式: {{mode}})...{{NC}}"
    cd deploy && ./deploy.sh {{mode}}
    @echo -e "{{GREEN}}✅ 生产部署完成！{{NC}}"

# 启动deploy目录的服务
deploy-start mode="1panel":
    @echo -e "{{GREEN}}▶️  启动服务 (模式: {{mode}})...{{NC}}"
    cd deploy && ./start.sh {{mode}}

# 停止deploy目录的服务
deploy-stop:
    @echo -e "{{RED}}⏹️  停止服务...{{NC}}"
    cd deploy && ./stop.sh

# 运行 Docker 容器
docker-run port="9653":
    @echo -e "{{GREEN}}🏃 运行 Docker 容器 (端口: {{port}})...{{NC}}"
    -docker stop {{DOCKER_CONTAINER}} 2>/dev/null
    -docker rm {{DOCKER_CONTAINER}} 2>/dev/null
    docker run -d --name {{DOCKER_CONTAINER}} -p {{port}}:9653 {{DOCKER_IMAGE}}:latest
    @echo -e "{{GREEN}}✅ 容器已启动！访问: http://localhost:{{port}}{{NC}}"

# 停止 Docker 容器
docker-stop:
    @echo -e "{{RED}}🛑 停止 Docker 容器...{{NC}}"
    -docker stop {{DOCKER_CONTAINER}}
    -docker rm {{DOCKER_CONTAINER}}
    @echo -e "{{GREEN}}✅ 容器已停止并删除{{NC}}"

# 查看 Docker 容器日志
docker-logs:
    @echo -e "{{CYAN}}📜 Docker 容器日志:{{NC}}"
    docker logs -f {{DOCKER_CONTAINER}}

# Docker 健康检查
docker-health:
    @echo -e "{{PURPLE}}🩺 Docker 容器健康检查...{{NC}}"
    @curl -f http://localhost/ || echo -e "{{RED}}❌ 服务不可用{{NC}}"

# 完整 Docker 工作流
docker-deploy: docker-build docker-run

# 清理 Docker 资源
docker-clean:
    @echo -e "{{RED}}🧹 清理 Docker 资源...{{NC}}"
    -docker stop {{DOCKER_CONTAINER}} 2>/dev/null
    -docker rm {{DOCKER_CONTAINER}} 2>/dev/null  
    -docker rmi {{DOCKER_IMAGE}}:latest 2>/dev/null
    docker system prune -f
    @echo -e "{{GREEN}}✅ Docker 资源清理完成{{NC}}"

# ==========================================
# 📈 性能和分析 (Performance & Analysis)
# ==========================================

# 构建性能分析
perf-build:
    @echo -e "{{PURPLE}}⚡ 构建性能分析...{{NC}}"
    just build
    @echo -e "{{BLUE}}📦 Bundle 大小分析:{{NC}}"
    @du -sh dist/
    @echo -e "{{BLUE}}📋 资源文件详情:{{NC}}"
    @ls -lah dist/assets/ 2>/dev/null || echo "无 assets 目录"

# Bundle 分析 (如果配置了)
bundle-analyze:
    @echo -e "{{CYAN}}🔍 Bundle 分析...{{NC}}"
    @echo "运行 npm run build 并检查输出以查看 bundle 分析"
    npm run build

# Lighthouse 性能测试提示
lighthouse:
    @echo -e "{{YELLOW}}🔍 Lighthouse 性能测试说明:{{NC}}"
    @echo "1. 首先启动服务: just dev"
    @echo "2. 安装 Lighthouse: npm install -g lighthouse" 
    @echo "3. 运行测试: lighthouse http://localhost:{{DEV_PORT}} --view"
    @echo "4. 或在 Chrome DevTools > Lighthouse 中运行"

# ==========================================
# 🛠️ 开发工具 (Development Tools)
# ==========================================

# 项目信息显示
info:
    @echo -e "{{WHITE}}📋 {{PROJECT_NAME}} 项目信息:{{NC}}"
    @echo -e "  {{CYAN}}项目名称:{{NC}} {{PROJECT_NAME}}"
    @echo -e "  {{CYAN}}技术栈:{{NC}} React 19 + TypeScript + Vite"
    @echo -e "  {{CYAN}}开发端口:{{NC}} {{DEV_PORT}}"
    @echo -e "  {{CYAN}}构建目录:{{NC}} dist/"
    @echo -e "  {{CYAN}}测试框架:{{NC}} Vitest + Testing Library"
    @echo -e "  {{CYAN}}样式方案:{{NC}} Tailwind CSS + DaisyUI"

# 显示项目统计
stats:
    @echo -e "{{PURPLE}}📊 项目统计信息:{{NC}}"
    @echo -e "{{CYAN}}源码行数:{{NC}}"
    @find src -name "*.ts" -o -name "*.tsx" | xargs wc -l | tail -1
    @echo -e "{{CYAN}}组件数量:{{NC}}"
    @find src -name "*.tsx" | wc -l
    @echo -e "{{CYAN}}测试文件:{{NC}}"
    @find . -name "*.test.*" | wc -l

# 开发环境设置
dev-setup: install
    @echo -e "{{GREEN}}⚙️ 开发环境设置完成检查:{{NC}}"
    just lint
    just test-run
    @echo -e "{{GREEN}}✅ 开发环境设置完成！可以开始开发了！{{NC}}"

# ==========================================
# 📚 文档和帮助 (Documentation & Help)
# ==========================================

# 启动文档服务器
docs-serve:
    @echo -e "{{BLUE}}📖 项目文档:{{NC}}"
    @echo "📁 文档位置: docs/"
    @echo "📋 主要文档:"
    @echo "  - README.md - 项目介绍"
    @echo "  - CLAUDE.md - 项目配置"  
    @echo "  - justfile - 任务定义"
    @ls -la docs/ 2>/dev/null || echo "docs 目录不存在"

# 显示详细帮助信息
help:
    @echo -e "{{WHITE}}🚀 {{PROJECT_NAME}} - Just 任务运行器{{NC}}"
    @echo ""
    @echo -e "{{GREEN}}📖 快速开始:{{NC}}"
    @echo -e "  {{CYAN}}just dev{{NC}}          # 启动开发服务器"
    @echo -e "  {{CYAN}}just build{{NC}}        # 构建生产版本" 
    @echo -e "  {{CYAN}}just test{{NC}}         # 运行测试"
    @echo -e "  {{CYAN}}just check{{NC}}        # 快速检查 (lint + test)"
    @echo -e "  {{CYAN}}just commit{{NC}}       # 智能提交"
    @echo ""
    @echo -e "{{BLUE}}🎯 常用别名:{{NC}}"
    @echo -e "  {{YELLOW}}just d{{NC}} = just dev"
    @echo -e "  {{YELLOW}}just b{{NC}} = just build"
    @echo -e "  {{YELLOW}}just t{{NC}} = just test"
    @echo -e "  {{YELLOW}}just l{{NC}} = just lint"
    @echo -e "  {{YELLOW}}just c{{NC}} = just check"
    @echo ""
    @echo -e "{{PURPLE}}🐳 Docker 操作:{{NC}}"
    @echo -e "  {{CYAN}}just docker-build{{NC}} # 构建镜像"
    @echo -e "  {{CYAN}}just docker-run{{NC}}   # 运行容器"
    @echo -e "  {{CYAN}}just docker-stop{{NC}}  # 停止容器"
    @echo ""
    @echo -e "{{RED}}📋 查看所有任务:{{NC}} {{WHITE}}just --list{{NC}}"
    @echo -e "{{RED}}📝 交互式选择:{{NC}} {{WHITE}}just{{NC}} (无参数)"

# ==========================================
# 🔮 多语言扩展示例 (Multi-language Examples)
# ==========================================

# Python 项目支持 (示例)
py-install:
    @echo -e "{{GREEN}}🐍 Python 依赖安装...{{NC}}"
    pip install -r requirements.txt

py-test:
    @echo -e "{{CYAN}}🧪 Python 测试...{{NC}}"
    python -m pytest

py-lint:
    @echo -e "{{PURPLE}}🔍 Python 代码检查...{{NC}}"
    flake8 . && black --check .

# Rust 项目支持 (示例)
rust-build:
    @echo -e "{{RED}}🦀 Rust 项目构建...{{NC}}"
    cargo build --release

rust-test:
    @echo -e "{{CYAN}}🧪 Rust 测试...{{NC}}"
    cargo test

rust-lint:
    @echo -e "{{PURPLE}}🔍 Rust 代码检查...{{NC}}"
    cargo clippy

# Go 项目支持 (示例)
go-build:
    @echo -e "{{BLUE}}🐹 Go 项目构建...{{NC}}"
    go build -o bin/ ./...

go-test:
    @echo -e "{{CYAN}}🧪 Go 测试...{{NC}}"
    go test ./...

go-lint:
    @echo -e "{{PURPLE}}🔍 Go 代码检查...{{NC}}"
    golangci-lint run

# ==========================================
# 🎨 项目初始化模板 (Project Templates)
# ==========================================

# 初始化新的前端项目
init-frontend:
    @echo -e "{{GREEN}}🎨 初始化前端项目...{{NC}}"
    @echo "可用选项:"
    @echo "  - React: npm create vite@latest . --template react-ts"
    @echo "  - Vue: npm create vite@latest . --template vue-ts"
    @echo "  - Svelte: npm create vite@latest . --template svelte-ts"

# 初始化新的后端项目  
init-backend:
    @echo -e "{{BLUE}}⚙️ 初始化后端项目...{{NC}}"
    @echo "可用选项:"
    @echo "  - Node.js: npm init"
    @echo "  - Python: python -m venv venv"  
    @echo "  - Rust: cargo init"
    @echo "  - Go: go mod init project-name"

# ==========================================
# 🎪 自定义任务示例 (Custom Tasks Examples)
# ==========================================

# 生成项目报告
report:
    @echo -e "{{WHITE}}📄 生成项目报告...{{NC}}"
    @echo "=== {{PROJECT_NAME}} 项目报告 ===" > project-report.txt
    @echo "生成时间: $(date)" >> project-report.txt
    @echo "" >> project-report.txt
    @echo "依赖信息:" >> project-report.txt
    @npm list --depth=0 >> project-report.txt 2>/dev/null
    @echo "" >> project-report.txt
    @echo "Git 状态:" >> project-report.txt  
    @git status >> project-report.txt
    @echo -e "{{GREEN}}✅ 项目报告已生成: project-report.txt{{NC}}"

# 项目健康检查
health:
    @echo -e "{{PURPLE}}🩺 项目健康检查...{{NC}}"
    @echo -e "{{CYAN}}检查 Node.js 版本...{{NC}}"
    @node --version
    @echo -e "{{CYAN}}检查 npm 版本...{{NC}}"
    @npm --version
    @echo -e "{{CYAN}}检查依赖状态...{{NC}}"
    @npm ls --depth=0 >/dev/null && echo -e "{{GREEN}}✅ 依赖正常{{NC}}" || echo -e "{{RED}}❌ 依赖有问题{{NC}}"
    @echo -e "{{CYAN}}检查 Git 仓库...{{NC}}"
    @git status >/dev/null && echo -e "{{GREEN}}✅ Git 仓库正常{{NC}}" || echo -e "{{RED}}❌ Git 仓库异常{{NC}}"