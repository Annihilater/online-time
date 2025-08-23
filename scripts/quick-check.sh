#!/bin/bash

# 快速检查脚本
# 依次执行：lint -> test

set -e

echo "⚡ 开始快速检查..."
echo

echo "🔧 1/2 代码规范检查"
npm run lint
echo

echo "🧪 2/2 运行测试套件"
npm run test:run
echo

echo "✅ 快速检查完成！代码质量良好。"