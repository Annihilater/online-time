#!/usr/bin/env bash

# 智能提交脚本 - 按模块功能自动分批提交
set -e

# 确保使用bash并检查版本
if [ -z "$BASH_VERSION" ]; then
    echo "❌ 此脚本需要bash运行环境"
    echo "请使用: bash ./scripts/smart-commit.sh"
    exit 1
fi

# 检查bash版本是否支持关联数组（bash 4.0+）
if [ "${BASH_VERSION:0:1}" -lt 4 ]; then
    echo "❌ 此脚本需要bash 4.0或更高版本"
    echo "当前版本: $BASH_VERSION"
    exit 1
fi

echo "🤖 智能提交流程开始..."
echo

# 1. 先做快速检查（跳过可能阻塞的测试）
echo "🔍 执行代码质量检查..."
echo "🔧 代码规范检查"
if ! npm run lint; then
    echo "❌ 代码规范检查失败，请修复后重试"
    exit 1
fi

echo
echo "🏗️ 验证构建"
if ! npm run build; then
    echo "❌ 构建失败，请修复后重试"
    exit 1
fi

echo
echo "🧪 运行测试（允许部分失败）"
npm run test:run || echo "⚠️  警告：部分测试失败，但将继续提交流程"
echo

# 2. 分析修改的文件，按模块分组
echo "📊 分析文件修改，按模块分组提交..."
echo

# 检查是否有修改
if [[ -z $(git status --porcelain) ]]; then
    echo "✅ 没有需要提交的修改"
    exit 0
fi

# 获取所有修改的文件
MODIFIED_FILES=$(git status --porcelain | awk '{print $2}')
echo "发现修改的文件："
echo "$MODIFIED_FILES" | sed 's/^/  - /'
echo

# 模块匹配函数
get_module_for_file() {
    local file="$1"
    
    # 按优先级检查模块
    if echo "$file" | grep -qE "\.claude/commands/.*\.md$"; then
        echo "claude-commands"
    elif echo "$file" | grep -qE "scripts/.*\.sh$"; then
        echo "scripts"
    elif echo "$file" | grep -qE "\.github/.*\.ya?ml$"; then
        echo "github-actions"
    elif echo "$file" | grep -qE "src/.*(components|shared/components)/.*\.(tsx?|css)$"; then
        echo "frontend-components"
    elif echo "$file" | grep -qE "src/.*pages/.*\.tsx?$"; then
        echo "frontend-pages"
    elif echo "$file" | grep -qE "src/.*hooks/.*\.tsx?$"; then
        echo "frontend-hooks"
    elif echo "$file" | grep -qE "src/.*stores/.*\.tsx?$"; then
        echo "frontend-stores"
    elif echo "$file" | grep -qE "src/.*utils/.*\.tsx?$"; then
        echo "frontend-utils"
    elif echo "$file" | grep -qE "src/.*test.*\.(tsx?|test\.tsx?|spec\.tsx?)$"; then
        echo "frontend-tests"
    elif echo "$file" | grep -qE "(.*config.*\.(json|js|ts)$|package\.json|tsconfig\.json|vite\.config\..*|tailwind\.config\..*|eslint\.config\..*|vitest\.config\..*)"; then
        echo "config"
    elif echo "$file" | grep -qE "(docker/.*|Dockerfile.*|\.dockerignore|docker-compose\..*\.ya?ml)"; then
        echo "docker"
    elif echo "$file" | grep -qE "deploy/.*"; then
        echo "deploy"
    elif echo "$file" | grep -qE ".*\.md$|README.*|CHANGELOG.*|LICENSE.*"; then
        echo "docs"
    else
        echo "misc"
    fi
}

# 按模块分组文件
echo "🔍 按模块分组文件..."

# 创建临时文件存储分组结果
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for file in $MODIFIED_FILES; do
    module=$(get_module_for_file "$file")
    echo "$file" >> "$TEMP_DIR/$module.txt"
    echo "  $file → $module"
done
echo

# 定义提交顺序（重要的先提交）
commit_order=("config" "scripts" "claude-commands" "github-actions" "docker" "deploy" "frontend-utils" "frontend-hooks" "frontend-stores" "frontend-components" "frontend-pages" "frontend-tests" "docs" "misc")

commit_count=0

# 按顺序提交每个模块
for module in "${commit_order[@]}"; do
    module_file="$TEMP_DIR/$module.txt"
    if [[ -f "$module_file" && -s "$module_file" ]]; then
        echo "📦 提交模块: $module"
        
        # 读取该模块的文件列表
        files=()
        while IFS= read -r file; do
            files+=("$file")
        done < "$module_file"
        
        echo "  文件: ${files[@]}"
        
        # 添加该模块的文件
        for file in "${files[@]}"; do
            git add "$file"
        done
        
        # 生成提交信息
        case "$module" in
            "claude-commands")
                commit_msg="feat: 更新Claude Code自定义命令配置"
                ;;
            "scripts")
                commit_msg="feat: 更新自动化脚本和工具"
                ;;
            "github-actions")
                commit_msg="ci: 更新GitHub Actions CI/CD配置"
                ;;
            "docs")
                commit_msg="docs: 更新项目文档"
                ;;
            "frontend-components")
                commit_msg="feat: 更新前端组件"
                ;;
            "frontend-pages")
                commit_msg="feat: 更新前端页面"
                ;;
            "frontend-hooks")
                commit_msg="feat: 更新React Hooks"
                ;;
            "frontend-stores")
                commit_msg="feat: 更新状态管理"
                ;;
            "frontend-utils")
                commit_msg="feat: 更新工具函数"
                ;;
            "frontend-tests")
                commit_msg="test: 更新测试用例"
                ;;
            "config")
                commit_msg="config: 更新项目配置"
                ;;
            "docker")
                commit_msg="docker: 更新Docker配置"
                ;;
            "deploy")
                commit_msg="deploy: 更新部署配置"
                ;;
            "misc")
                commit_msg="chore: 更新其他文件"
                ;;
            *)
                commit_msg="feat: 更新${module}模块"
                ;;
        esac
        
        # 提交
        git commit -m "$(cat <<EOF
$commit_msg

- $(echo "${files[@]}" | tr ' ' '\n' | sed 's/^/  /')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
        
        echo "  ✅ 已提交 $(echo "${files[@]}" | wc -w | tr -d ' ') 个文件"
        echo
        ((commit_count++))
    fi
done

echo "🎉 智能提交完成！"
echo "📊 总共创建了 $commit_count 个模块化提交"
echo

# 显示最近的提交
echo "📋 最近的提交记录："
git log --oneline -n $commit_count

echo
echo "💡 下一步：运行 'git push origin $(git branch --show-current)' 推送到远程仓库"