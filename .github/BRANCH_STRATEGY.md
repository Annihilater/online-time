# 🌿 分支策略和CI/CD工作流

## 📋 分支策略

### 主要分支

| 分支 | 用途 | 触发构建 | 是否发布 | 部署环境 |
|------|------|----------|----------|----------|
| `master` | 主分支，稳定代码 | ✅ | ❌ | - |
| `release` | 生产发布分支 | ✅ | ✅ GitHub Container Registry | 🎯 Production |
| `test` | 测试分支 | ✅ | ❌ | 🧪 Testing |
| `dev` | 开发分支 | ✅ | ❌ | 🚀 Development |

### 标签策略

- **语义化版本**：`v1.0.0`, `v1.1.0`, `v2.0.0`
- **预发布版本**：`v1.0.0-alpha.1`, `v1.0.0-beta.1`, `v1.0.0-rc.1`
- **标签自动触发**：生产构建和发布

## 🔄 CI/CD工作流

### 1. 开发阶段 (`dev` 分支)
```bash
git checkout dev
git add .
git commit -m "feat: 新功能开发"
git push origin dev
```

**触发的Actions：**
- ✅ 构建Docker镜像 (不推送)
- ✅ 运行测试
- 🚀 自动部署到开发环境
- 🏷️ 镜像标签：`dev-{commit-sha}`

### 2. 测试阶段 (`test` 分支)
```bash
git checkout test
git merge dev
git push origin test
```

**触发的Actions：**
- ✅ 构建Docker镜像 (不推送)
- ✅ 运行完整测试套件
- 🧪 自动部署到测试环境
- 🏷️ 镜像标签：`test-{commit-sha}`

### 3. 生产发布 (`release` 分支)
```bash
git checkout release
git merge test
git push origin release
```

**触发的Actions：**
- ✅ 构建Docker镜像
- 🐳 **推送到GitHub Container Registry**
- 🔒 安全漏洞扫描
- 🎯 自动部署到生产环境
- 🏷️ 镜像标签：`latest`, `release-{commit-sha}`

### 4. 版本发布 (Git Tags)
```bash
git checkout release
git tag v1.0.0
git push origin v1.0.0
```

**触发的Actions：**
- ✅ 构建Docker镜像
- 🐳 **推送到GitHub Container Registry**
- 🔒 安全漏洞扫描
- 📝 自动创建GitHub Release
- 🏷️ 镜像标签：`latest`, `1.0.0`, `1.0`

## 🐳 Docker镜像标签策略

### 发布标签（仅release分支和tag触发）
- `latest` - 最新稳定版本
- `v1.0.0` - 具体版本号
- `1.0` - 主要版本号
- `release-abc123` - release分支特定提交

### 开发标签（仅构建，不推送）
- `dev-abc123` - dev分支开发版本
- `test-abc123` - test分支测试版本
- `pr-123` - Pull Request版本

## 🔧 GitHub Secrets配置

GitHub Container Registry 使用内置的 `GITHUB_TOKEN`，**无需额外配置Secrets**！

- ✅ **自动认证**：GitHub Actions 自动提供认证令牌
- ✅ **零配置**：无需设置用户名密码
- ✅ **安全可靠**：基于仓库权限自动管理

## 📊 环境部署策略

### Development Environment
- **触发**：`dev`分支推送
- **用途**：最新功能验证
- **镜像**：`dev-{sha}` (不推送到Hub)

### Testing Environment  
- **触发**：`test`分支推送
- **用途**：完整功能测试
- **镜像**：`test-{sha}` (不推送到Hub)

### Production Environment
- **触发**：`release`分支推送或版本标签
- **用途**：生产环境部署
- **镜像**：`latest`, `v1.0.0` (推送到Hub)

## 🚀 快速开始

### 1. 开发新功能
```bash
# 从master创建feature分支
git checkout master
git pull origin master
git checkout -b feature/new-feature

# 开发完成后合并到dev
git checkout dev
git merge feature/new-feature
git push origin dev
```

### 2. 发布新版本
```bash
# 测试通过后发布
git checkout test
git merge dev
git push origin test

# 测试环境验证后发布生产
git checkout release  
git merge test
git push origin release

# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

### 3. 热修复
```bash
# 从release创建hotfix分支
git checkout release
git checkout -b hotfix/critical-fix

# 修复后直接合并到release
git checkout release
git merge hotfix/critical-fix
git push origin release
```

## ⚡ CI/CD特性

### ✅ 自动化构建
- 多架构支持 (linux/amd64, linux/arm64)
- 构建缓存优化
- 并行构建提升速度

### 🔒 安全扫描
- Trivy漏洞扫描
- 安全报告自动上传到GitHub Security

### 📝 自动化发布
- 自动生成changelog
- GitHub Release创建
- 预发布版本检测

### 🔔 通知系统
- 构建状态通知
- 部署完成提醒
- 失败告警

## 🎯 最佳实践

1. **分支保护**：为`master`和`release`分支设置保护规则
2. **代码审查**：所有合并请求需要代码审查
3. **测试覆盖**：确保充足的测试覆盖率
4. **语义化版本**：遵循语义化版本规范
5. **提交规范**：使用约定式提交格式

## 📚 相关文档

- [Docker构建脚本文档](../scripts/README-Docker.md)
- [部署指南](../deploy/README.md)
- [项目结构说明](../PROJECT_STRUCTURE.md)