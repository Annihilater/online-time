---
description: "热修复提交流程（跳过构建检查，快速修复）"
allowed-tools: "Bash(*)"
argument-hint: "修复信息，如：fix: 修复紧急问题"
---

执行热修复的快速提交流程：

🔥 **热修复提交流程开始**

1. **检查项目状态**
!git status

2. **快速测试验证**
!npm run test:run

3. **添加所有文件**
!git add .

4. **提交修复**
!git commit -m "$ARGUMENTS"

✅ **热修复提交完成！**

⚠️ **重要：** 请立即运行 `git push origin [branch]` 推送修复到远程仓库