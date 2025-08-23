---
description: "智能提交系统：自动检查代码质量并按模块分批提交"
allowed-tools: "Bash(*)"
---

执行智能提交流程，自动按模块功能分批提交代码：

!./scripts/smart-commit.sh

🚀 **智能提交特性：**
- **自动质量检查** - lint + test + build 完整验证
- **智能模块分组** - 自动识别文件类型并按模块分类：
  - `claude-commands` - Claude Code自定义命令
  - `scripts` - 自动化脚本和工具  
  - `github-actions` - CI/CD配置
  - `frontend-*` - 前端组件、页面、钩子等
  - `config` - 项目配置文件
  - `docker` - 容器化配置
  - `docs` - 文档更新
  - `misc` - 其他修改
- **语义化提交** - 自动生成规范的提交信息
- **批量提交** - 每个模块单独提交，清晰的变更历史

📊 **提交顺序：** config → scripts → claude-commands → github-actions → docker → deploy → frontend-utils → frontend-hooks → frontend-stores → frontend-components → frontend-pages → frontend-tests → docs → misc

✅ **全自动流程：** 一个命令完成从检查到提交的全部流程
