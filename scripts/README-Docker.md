# Docker构建和部署脚本使用指南

本项目包含完整的Docker构建和部署工具链，支持开发、测试和生产环境的容器化部署。

## 🚀 快速开始

### 1. 基本构建和推送
```bash
# 构建并推送到Docker Hub (默认配置)
./scripts/build-and-push.sh

# 指定镜像名和版本
./scripts/build-and-push.sh -i username/online-time -v 1.0.0
```

### 2. 快速本地构建
```bash
# 快速本地构建 (单架构，用于开发测试)
./scripts/quick-build.sh

# 构建特定标签
./scripts/quick-build.sh v1.0.0
```

### 3. 开发环境
```bash
# 启动完整开发环境
./scripts/docker-manager.sh dev

# 或使用Docker Compose
docker-compose --profile dev up
```

## 📋 脚本详细说明

### build-and-push.sh - 生产构建脚本

**功能特性:**
- ✅ 多架构构建 (linux/amd64, linux/arm64)
- ✅ 自动版本管理 (语义化版本 + Git标签)
- ✅ 镜像验证和安全扫描
- ✅ 构建缓存优化
- ✅ 详细的构建日志

**使用示例:**
```bash
# 完整多架构构建并推送
./scripts/build-and-push.sh -i myuser/online-time -v 2.1.0

# 仅构建不推送
./scripts/build-and-push.sh --build-only

# 使用Git提交哈希作为标签
./scripts/build-and-push.sh --use-git-hash

# 构建后清理缓存
./scripts/build-and-push.sh --cleanup --verbose

# 预览模式 (显示将执行的命令)
./scripts/build-and-push.sh --dry-run
```

**参数说明:**
- `-i, --image`: Docker镜像名称
- `-v, --version`: 镜像版本标签
- `-p, --platforms`: 目标平台 (默认: linux/amd64,linux/arm64)
- `--build-only`: 仅构建，不推送
- `--cleanup`: 构建后清理缓存
- `--use-git-hash`: 使用Git提交哈希作为版本
- `--verbose`: 详细日志输出
- `--dry-run`: 预览模式

### quick-build.sh - 快速开发构建

**用途:** 本地开发快速构建，单架构，无注册表操作

```bash
./scripts/quick-build.sh [TAG]

# 示例
./scripts/quick-build.sh dev
./scripts/quick-build.sh $(git rev-parse --short HEAD)
```

### docker-manager.sh - 综合管理工具

**主要命令:**

```bash
# 构建
./scripts/docker-manager.sh build --prod
./scripts/docker-manager.sh build --dev --no-cache

# 运行
./scripts/docker-manager.sh run --prod --port 3000
./scripts/docker-manager.sh run --dev --detach

# 开发环境
./scripts/docker-manager.sh dev

# 测试
./scripts/docker-manager.sh test --coverage
./scripts/docker-manager.sh test --watch

# 推送
./scripts/docker-manager.sh push --tag v1.0.0 --latest

# 状态监控
./scripts/docker-manager.sh status
./scripts/docker-manager.sh logs
./scripts/docker-manager.sh health

# 清理
./scripts/docker-manager.sh clean --all
```

## 🔧 配置说明

### 环境变量配置
在 `scripts/docker-config.sh` 中配置：

```bash
# Docker注册表配置
export DOCKER_USERNAME="your-username"
export DEFAULT_IMAGE_NAME="online-time"

# 构建配置
export DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
export BUILD_MODE="production"

# 安全扫描
export ENABLE_SECURITY_SCAN="true"
export SCAN_SEVERITY="HIGH,CRITICAL"
```

### Docker Compose配置

项目包含多个Compose文件：

- `docker-compose.yml`: 主要服务配置
- `docker/docker-compose.dev.yml`: 开发环境
- `docker/docker-compose.monitoring.yml`: 监控服务
- `docker/docker-compose.ha.yml`: 高可用配置

## 📦 镜像结构

### 生产镜像 (docker/base/Dockerfile)
```
FROM node:18-alpine AS builder
# ... 构建阶段

FROM nginx:alpine AS production  
# ... 生产运行环境
```

**特点:**
- 多阶段构建优化
- 基于Alpine Linux (小体积)
- 非root用户运行
- 内置健康检查
- 安全配置

### 开发镜像 (docker/dev/Dockerfile)
```
FROM node:18-alpine AS development
# ... 开发环境配置
```

**特点:**
- 热重载支持
- 开发工具预装
- 调试端口暴露
- 卷挂载优化

## 🚀 部署流程

### 1. 本地开发
```bash
# 快速启动开发环境
./scripts/docker-manager.sh dev

# 访问 http://localhost:5173
```

### 2. 构建测试
```bash
# 构建生产镜像
./scripts/quick-build.sh prod

# 运行生产容器测试
docker run -p 3000:80 online-time:prod
```

### 3. 发布部署
```bash
# 构建并推送多架构镜像
./scripts/build-and-push.sh -i username/online-time -v 1.0.0

# 验证推送结果
docker pull username/online-time:1.0.0
```

## 🔍 监控和故障排除

### 查看容器状态
```bash
./scripts/docker-manager.sh status
./scripts/docker-manager.sh health
```

### 查看日志
```bash
./scripts/docker-manager.sh logs
docker-compose logs -f online-time
```

### 进入容器调试
```bash
./scripts/docker-manager.sh shell
docker exec -it online-time-app /bin/bash
```

### 清理和重置
```bash
# 清理所有容器和镜像
./scripts/docker-manager.sh clean --all

# 重新构建
./scripts/docker-manager.sh build --no-cache
```

## 🎯 最佳实践

### 开发阶段
- 使用 `docker-manager.sh dev` 启动开发环境
- 利用热重载提高开发效率
- 定期运行 `docker-manager.sh test` 执行测试

### 构建阶段  
- 使用 `build-and-push.sh` 进行生产构建
- 启用 `--cleanup` 保持系统清洁
- 使用语义化版本标签

### 部署阶段
- 多架构构建确保兼容性
- 启用安全扫描检查漏洞
- 使用健康检查确保服务可用性

## 🔒 安全注意事项

1. **注册表认证**: 确保已登录Docker Hub
2. **镜像扫描**: 启用Trivy安全扫描
3. **最小权限**: 容器以非root用户运行
4. **定期更新**: 及时更新基础镜像

## 📞 故障排除

### 常见问题

**Q: 构建失败，提示buildx不可用**
```bash
# 安装并启用buildx
docker buildx install
docker buildx create --use
```

**Q: 推送失败，权限被拒绝**
```bash
# 重新登录Docker Hub
docker logout
docker login
```

**Q: 开发环境启动失败**
```bash
# 检查端口占用
./scripts/docker-manager.sh status
./scripts/docker-manager.sh clean --containers
```

**Q: 镜像体积过大**
```bash
# 分析镜像层
docker history online-time:latest
# 使用dive工具分析
dive online-time:latest
```

---

## 📚 相关文档

- [Docker官方文档](https://docs.docker.com/)
- [Docker Buildx文档](https://docs.docker.com/buildx/)
- [多架构构建指南](https://docs.docker.com/desktop/multi-arch/)
- [Docker Compose文档](https://docs.docker.com/compose/)

更多帮助信息，运行 `./scripts/docker-manager.sh --help`