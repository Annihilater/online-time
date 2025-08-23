#!/bin/bash

# 完整功能提交脚本
# 用法: ./scripts/feature-commit.sh "feat: 添加新功能"

if [ -z "$1" ]; then
  echo "❌ 错误：请提供提交信息"
  echo "用法：./scripts/feature-commit.sh \"feat: 添加新功能描述\""
  exit 1
fi

COMMIT_MESSAGE="$1"

set -e

echo "🚀 新功能提交流程开始..."
echo "📝 提交信息：$COMMIT_MESSAGE"
echo
echo "📋 请确认提交符合规范："
echo "   ✓ 该提交包含一个完整的模块或功能"
echo "   ✓ 该功能已经测试并能正常运行"
echo "   ✓ 提交信息遵循语义化规范"
echo

# 1. 完整检查
echo "🔍 执行完整检查流程..."
./scripts/commit-check.sh
echo

# 2. 添加文件
echo "📦 添加所有文件到暂存区"
git add .
echo

# 3. 提交
echo "💾 提交代码"
git commit -m "$COMMIT_MESSAGE"
echo

echo "✅ 功能提交完成！"
echo "💡 下一步：运行 'git push origin [branch]' 推送到远程仓库"