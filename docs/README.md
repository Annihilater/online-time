# 项目文档目录

这里包含了在线时间工具项目的各类文档资源。

## 目录结构

### 📁 development/
开发相关的文档和指南

- **quick-reference.md** - 开发者快速参考指南
- **dev-setup.md** - 开发环境设置指南  
- **agent-collaboration.md** - Agent协作配置文档
- **project-context.md** - 项目上下文信息
- **README_QUICK_START.md** - 快速启动指南

### 📁 deployment/
部署相关的文档（位于deploy/docs/）

- **DEPLOYMENT_SUMMARY.md** - 部署概览
- **MONITORING.md** - 监控配置
- **OPERATIONS_SUMMARY.md** - 运维指南
- **QUICK_START.md** - 部署快速开始

### 📁 api/
API文档和接口说明

### 📁 architecture/
项目架构设计文档

## 文档使用指南

### 🚀 新手快速上手
1. 先读 `development/quick-reference.md` - 快速了解项目
2. 再读 `development/dev-setup.md` - 设置开发环境
3. 查看 `deployment/QUICK_START.md` - 了解部署流程

### 🔧 开发团队
- **Agent协作**: `development/agent-collaboration.md`
- **项目上下文**: `development/project-context.md`
- **部署指南**: `deploy/docs/` 目录

### 📝 文档维护
- 保持文档与代码同步更新
- 新功能需要对应的文档说明
- 定期审查文档的准确性和完整性

## Claude Code配置

**重要说明**: 
- ✅ Claude Code命令位于 `.claude/commands/` 
- ❌ **不要**将Claude配置放在 `.config/.claude/`
- 本目录下的文档仅供参考，不会被Claude Code识别为命令

## 获取帮助

如果你在使用过程中遇到问题：
1. 查看相关文档
2. 使用Claude Code命令 `/help`
3. 查看项目的CLAUDE.md配置文件