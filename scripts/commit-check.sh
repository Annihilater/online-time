#!/bin/bash

# 完整提交检查脚本
# 依次执行：status -> lint -> test -> build

set -e  # 遇到错误立即退出

echo "🔍 开始完整提交检查..."
echo

echo "📋 1/4 检查Git状态"
git status
echo

echo "🔧 2/4 代码规范检查" 
npm run lint
echo

echo "🧪 3/4 运行测试套件"
npm run test:run
echo

echo "🏗️ 4/4 验证构建"
npm run build
echo

echo "✅ 所有检查通过！现在可以安全地提交代码了。"
echo
echo "📋 提交规范："
echo "   • 按模块和功能分批提交代码"
echo "   • 每次提交一个完整的模块或功能"
echo "   • 确保每个模块都能正常运行"
echo "   • 使用语义化提交信息 (feat/fix/docs/style/refactor/test/chore)"
echo
echo "💡 下一步："
echo "   git add ."  
echo "   git commit -m \"feat: 你的功能描述\""
echo
echo "📚 提交信息示例："
echo "   feat: 添加用户认证功能"
echo "   fix: 修复登录页面响应问题"
echo "   docs: 更新API文档"