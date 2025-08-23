# Online Time Project Makefile
# 简化常用开发操作

.PHONY: help install dev build test lint clean deploy status

# 默认目标 - 显示帮助信息
help:
	@echo "在线闹钟项目 - 可用命令:"
	@echo ""
	@echo "  make install     安装项目依赖"
	@echo "  make dev         启动开发服务器"
	@echo "  make build       构建生产版本"
	@echo "  make test        运行测试套件"
	@echo "  make test-ui     启动测试UI界面"
	@echo "  make lint        运行代码检查"
	@echo "  make lint-fix    自动修复代码问题"
	@echo "  make preview     预览构建结果"
	@echo "  make clean       清理缓存和临时文件"
	@echo "  make status      检查项目状态"
	@echo "  make deps        检查依赖状态"
	@echo "  make coverage    生成测试覆盖率报告"
	@echo ""

# 安装依赖
install:
	@echo "📦 安装项目依赖..."
	npm ci

# 启动开发服务器
dev:
	@echo "🚀 启动开发服务器..."
	npm run dev

# 构建生产版本
build:
	@echo "🔨 构建生产版本..."
	npm run build
	@echo "✅ 构建完成! 输出目录: dist/"

# 运行测试
test:
	@echo "🧪 运行测试套件..."
	npm run test

# 测试UI界面
test-ui:
	@echo "🧪 启动测试UI界面..."
	npm run test:ui

# 运行所有测试 (CI模式)
test-ci:
	@echo "🧪 运行所有测试 (CI模式)..."
	npm run test:run

# 生成测试覆盖率
coverage:
	@echo "📊 生成测试覆盖率报告..."
	npm run test:coverage
	@echo "📈 覆盖率报告生成完成: coverage/index.html"

# 代码检查
lint:
	@echo "🔍 运行代码检查..."
	npm run lint

# 自动修复代码问题
lint-fix:
	@echo "🔧 自动修复代码问题..."
	npm run lint -- --fix

# 预览构建结果
preview: build
	@echo "👀 预览构建结果..."
	npm run preview

# 完整的CI检查流程
ci-check:
	@echo "🔄 运行完整CI检查流程..."
	@echo "1. 依赖安装..."
	npm ci
	@echo "2. 代码检查..."
	npm run lint
	@echo "3. 运行测试..."
	npm run test:run
	@echo "4. 构建验证..."
	npm run build
	@echo "✅ CI检查流程完成!"

# 清理缓存和临时文件
clean:
	@echo "🧹 清理缓存和临时文件..."
	rm -rf node_modules/.vite
	rm -rf node_modules/.cache
	rm -rf .eslintcache
	rm -rf coverage
	rm -rf dist
	@echo "✅ 清理完成!"

# 完全重置项目
reset: clean
	@echo "🔄 完全重置项目..."
	rm -rf node_modules
	rm -rf package-lock.json
	npm install
	@echo "✅ 项目重置完成!"

# 检查项目状态
status:
	@echo "📊 项目状态检查:"
	@echo ""
	@echo "Node版本:"
	@node --version 2>/dev/null || echo "❌ Node.js未安装"
	@echo ""
	@echo "npm版本:"
	@npm --version 2>/dev/null || echo "❌ npm未安装"
	@echo ""
	@echo "项目依赖状态:"
	@npm ls --depth=0 2>/dev/null || echo "❌ 依赖有问题，运行 'make install'"
	@echo ""
	@echo "Git状态:"
	@git status --porcelain 2>/dev/null || echo "❌ 不在Git仓库中"

# 检查依赖状态
deps:
	@echo "📦 依赖状态检查:"
	@echo ""
	@echo "过时的依赖:"
	@npm outdated 2>/dev/null || echo "✅ 所有依赖都是最新的"
	@echo ""
	@echo "安全审计:"
	@npm audit --audit-level=moderate 2>/dev/null || echo "⚠️  发现安全问题，运行 'npm audit fix'"

# 性能检查
perf:
	@echo "⚡ 性能检查:"
	@echo ""
	@echo "构建大小分析:"
	@if [ ! -d "dist" ]; then \
		echo "🔨 正在构建项目..."; \
		make build >/dev/null 2>&1; \
	fi
	@echo "📁 dist/ 目录大小:"
	@du -sh dist/ 2>/dev/null || echo "❌ 构建失败或目录不存在"
	@echo ""
	@echo "📄 主要文件大小:"
	@if [ -d "dist/assets" ]; then \
		ls -lah dist/assets/ | head -10; \
	else \
		echo "❌ assets目录不存在"; \
	fi

# 部署准备检查
deploy-check:
	@echo "🚀 部署准备检查:"
	@echo ""
	@echo "1. Git状态检查..."
	@git status --porcelain 2>/dev/null || echo "❌ Git状态有问题"
	@echo ""
	@echo "2. 运行CI检查..."
	@make ci-check 2>/dev/null || echo "⚠️ CI检查完成（可能有警告）"
	@echo ""
	@echo "3. 构建大小检查..."
	@make perf 2>/dev/null || echo "⚠️ 性能检查完成（可能有警告）"
	@echo ""
	@echo "✅ 部署准备检查完成!"

# 开发环境设置 (新项目初始化)
setup:
	@echo "🛠️  设置开发环境..."
	@echo "1. 安装依赖..."
	@make install
	@echo "2. 运行初始检查..."
	@make status
	@echo "3. 运行测试验证..."
	@make test-ci
	@echo "4. 构建验证..."
	@make build
	@echo ""
	@echo "✅ 开发环境设置完成!"
	@echo "💡 现在可以运行 'make dev' 启动开发服务器"

# Git相关操作
git-clean:
	@echo "🧹 清理Git缓存..."
	git rm -r --cached .
	git add .
	@echo "✅ Git缓存清理完成"

# 更新依赖 (小心使用)
update-deps:
	@echo "📦 更新依赖 (保守更新)..."
	npm update
	@echo "🧪 测试更新后的依赖..."
	@make test-ci
	@echo "✅ 依赖更新完成!"

# 快速修复常见问题
fix:
	@echo "🔧 快速修复常见问题..."
	@echo "1. 清理缓存..."
	@make clean
	@echo "2. 重新安装依赖..."
	npm ci
	@echo "3. 修复代码格式..."
	@make lint-fix
	@echo "4. 验证修复结果..."
	@make test-ci
	@echo "✅ 快速修复完成!"