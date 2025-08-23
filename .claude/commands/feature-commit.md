---
description: "新功能完整提交流程（自动添加和提交）"
allowed-tools: "Bash(*)"
argument-hint: "提交信息，如：feat: 添加新功能"
---

执行新功能的完整提交流程：

!./scripts/feature-commit.sh "$ARGUMENTS"

🔗 **此命令组合了以下操作：**
1. `/commit` - 完整检查流程 (status + lint + test + build)
2. `/add` - 添加所有文件到暂存区  
3. `git commit` - 提交代码

📋 **提交信息规范：**
- 必须使用语义化前缀：`feat:` `fix:` `docs:` `style:` `refactor:` `test:` `chore:`
- 描述要简洁明确，说明做了什么，而不是怎么做的
- 一个提交对应一个完整的功能模块

📚 **示例：**
```bash
/feature-commit "feat: 添加用户登录功能"
/feature-commit "fix: 修复定时器精度问题"
/feature-commit "docs: 更新部署说明文档"
```

💡 **最佳实践：** 确保提交前该功能已完整测试并能正常运行