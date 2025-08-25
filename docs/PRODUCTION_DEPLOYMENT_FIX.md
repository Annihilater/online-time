# 生产环境部署修复指南

## 🚨 问题症状
```
Error response from daemon: pull access denied for online-time, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
```

## 🔍 根本原因
- `online-time:latest` 是本地构建的镜像，在Docker Hub上不存在
- 生产环境尝试拉取不存在的镜像

## ⚡ 立即修复方案

### 方案A: 使用Docker Hub镜像（推荐）

#### 步骤1: 在本地推送镜像
```bash
# 在开发机器上执行
docker tag online-time:latest klause/online-time:latest
docker push klause/online-time:latest
```

#### 步骤2: 在生产服务器修改配置
```bash
# 在生产服务器上执行
cd /opt/apps/online-time

# 修改环境配置
sed -i 's/DOCKER_IMAGE=online-time:latest/DOCKER_IMAGE=klause\/online-time:latest/' .env.prod

# 验证修改
grep DOCKER_IMAGE .env.prod
```

#### 步骤3: 重新部署
```bash
./stop.sh
./start.sh 1panel
```

### 方案B: 在生产环境构建镜像

#### 步骤1: 确保有Dockerfile
```bash
# 检查Dockerfile是否存在
ls -la Dockerfile

# 如果不存在，需要从开发环境复制
```

#### 步骤2: 强制构建
```bash
# 强制重新构建
docker-compose -f docker-compose.prod.yml build --no-cache

# 然后启动
./start.sh 1panel
```

## 🔧 配置文件检查

### 检查 docker-compose.prod.yml
确保包含正确的build配置：
```yaml
services:
  online-time:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${DOCKER_IMAGE:-online-time:latest}
    # ... 其他配置
```

### 检查 .env.prod
确保镜像名称正确：
```bash
# 使用Docker Hub镜像
DOCKER_IMAGE=klause/online-time:latest

# 或使用本地构建
DOCKER_IMAGE=online-time:latest
```

## 🧪 验证修复

### 1. 检查镜像
```bash
# 查看可用镜像
docker images | grep online-time

# 应该看到类似输出：
# klause/online-time    latest    xxx    xxx    xx.xMB
```

### 2. 测试启动
```bash
./start.sh 1panel
```

### 3. 验证访问
```bash
# 健康检查
curl http://localhost:9653/health
# 应该返回: healthy

# 主页检查
curl -s http://localhost:9653/ | head -5
# 应该返回HTML内容
```

## 🚀 自动化部署脚本

创建一键部署脚本：
```bash
#!/bin/bash
# deploy-fix.sh

set -e

echo "🔧 修复生产环境部署..."

# 停止现有服务
./stop.sh || true

# 修改配置使用Docker Hub镜像
sed -i 's/DOCKER_IMAGE=online-time:latest/DOCKER_IMAGE=klause\/online-time:latest/' .env.prod

# 拉取最新镜像
docker pull klause/online-time:latest

# 启动服务
./start.sh 1panel

echo "✅ 部署修复完成！"
echo "📍 访问地址: http://localhost:9653"
```

## 📝 长期解决方案

### 1. CI/CD管道
建议设置CI/CD自动构建和推送镜像到Docker Hub

### 2. 版本管理
使用语义化版本标签：
```bash
docker tag online-time:latest klause/online-time:v1.0.0
docker push klause/online-time:v1.0.0
```

### 3. 多环境配置
- `.env.dev` - 开发环境
- `.env.prod` - 生产环境  
- `.env.staging` - 预发环境

## ⚠️ 注意事项

1. **镜像同步**: 确保本地修改后及时推送到Docker Hub
2. **版本控制**: 使用明确的版本标签而不是latest
3. **安全性**: 不要在镜像中包含敏感信息
4. **资源清理**: 定期清理旧的镜像和容器

---

## 📞 故障排除

如果仍有问题，按顺序检查：

1. **网络连接**: `docker pull alpine:latest`
2. **Docker Hub登录**: `docker login`
3. **镜像存在**: `docker pull klause/online-time:latest`
4. **配置文件**: `cat .env.prod | grep DOCKER_IMAGE`
5. **容器日志**: `docker logs online-time-app`

执行以上任一方案即可解决问题！🎉