# Docker 部署指南

在线闹钟项目的Docker化部署指南，支持快速部署、扩展和监控。

## 快速开始

### 方法1：使用自动化部署脚本（推荐）

```bash
# 一键部署
./deploy.sh

# 自定义端口部署
./deploy.sh -p 8080

# 使用Docker Compose部署
./deploy.sh -c

# 启用监控服务部署
./deploy.sh -c --profile monitoring
```

### 方法2：使用Makefile命令

```bash
# 一键Docker部署
make docker-deploy

# 使用Docker Compose
make compose-up

# 启用监控的生产部署
make compose-prod
```

### 方法3：手动Docker命令

```bash
# 构建镜像
docker build -t online-time:latest .

# 运行容器
docker run -d --name online-time-app -p 80:80 online-time:latest
```

## 部署配置文件说明

### 1. Dockerfile
- **多阶段构建**：优化镜像大小，减少安全风险
- **基础镜像**：Node.js 18 Alpine（构建） + Nginx Alpine（运行）
- **非root用户**：提高安全性
- **健康检查**：自动监控应用状态

### 2. docker-compose.yml
- **服务编排**：应用服务 + 可选的负载均衡和监控
- **健康检查**：内置健康监控
- **日志管理**：自动日志轮转
- **网络隔离**：独立的Docker网络

### 3. nginx.conf
- **性能优化**：Gzip压缩、缓存策略
- **安全头**：XSS防护、CSRF防护
- **SPA支持**：React Router友好配置

### 4. deploy.sh
- **自动化部署**：支持多种部署模式
- **健康检查**：部署后自动验证
- **错误处理**：完善的错误处理和回滚

## 部署模式

### 单容器模式（默认）
适合小型项目和开发环境：

```bash
./deploy.sh -s
# 或
make docker-deploy
```

### Docker Compose模式
适合生产环境和需要扩展的场景：

```bash
./deploy.sh -c
# 或
make compose-up
```

### 负载均衡模式
支持多实例负载均衡：

```bash
./deploy.sh -c --profile lb
```

### 监控模式
包含Prometheus监控：

```bash
./deploy.sh -c --profile monitoring
# 或
make compose-prod
```

## 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NODE_ENV` | `production` | 运行环境 |
| `PORT` | `80` | 应用端口 |
| `NGINX_WORKER_PROCESSES` | `auto` | Nginx工作进程数 |

## 健康检查

应用提供多个健康检查端点：

- **HTTP健康检查**：`http://localhost/health`
- **Docker健康检查**：自动每30秒检查一次
- **手动检查**：`make docker-health`

## 日志管理

### 查看日志
```bash
# 查看应用日志
docker logs -f online-time-app

# 使用Makefile
make docker-logs

# Docker Compose日志
docker-compose logs -f
```

### 日志配置
- **自动轮转**：最大10MB，保留3个文件
- **JSON格式**：便于日志聚合工具处理
- **访问日志**：Nginx访问日志记录

## 性能优化

### 镜像优化
- **多阶段构建**：最终镜像只包含运行时依赖
- **Alpine基础镜像**：减小镜像体积
- **构建缓存**：优化Docker层缓存

### 运行时优化
- **Gzip压缩**：减少传输数据
- **静态资源缓存**：1年缓存期
- **连接优化**：Keep-alive和连接池

## 监控和告警

### Prometheus监控（可选）
启用监控服务后可以访问：
- **Prometheus**：http://localhost:9090
- **健康指标**：自动收集应用健康状态

### 监控指标
- **应用可用性**：健康检查状态
- **响应时间**：请求处理时间
- **错误率**：4xx/5xx错误统计

## 故障排除

### 常见问题

**1. 端口冲突**
```bash
# 检查端口占用
lsof -i :80

# 使用其他端口
./deploy.sh -p 8080
```

**2. 权限问题**
```bash
# 确保脚本可执行
chmod +x deploy.sh

# 检查Docker权限
docker ps
```

**3. 健康检查失败**
```bash
# 检查应用状态
make docker-health

# 查看详细日志
make docker-logs
```

**4. 构建失败**
```bash
# 清理Docker缓存
docker system prune -f

# 重新构建
make docker-clean
make docker-build
```

### 调试命令

```bash
# 进入容器调试
docker exec -it online-time-app sh

# 检查容器资源使用
docker stats online-time-app

# 检查网络连接
docker network ls
docker network inspect online-time-network
```

## 生产部署建议

### 安全建议
1. **使用HTTPS**：配置SSL证书
2. **防火墙配置**：只开放必要端口
3. **定期更新**：保持基础镜像更新
4. **密钥管理**：使用Docker secrets

### 性能建议
1. **资源限制**：设置CPU和内存限制
2. **水平扩展**：使用多个容器实例
3. **负载均衡**：配置反向代理
4. **CDN加速**：静态资源使用CDN

### 备份建议
1. **数据备份**：定期备份重要数据
2. **镜像备份**：推送到镜像仓库
3. **配置备份**：版本控制所有配置

## 清理和卸载

```bash
# 停止并删除容器
make docker-stop

# 完全清理
make docker-clean

# Docker Compose清理
make compose-down
docker-compose down --volumes --remove-orphans
```

## 技术支持

如果遇到部署问题，请检查：

1. **Docker版本**：确保Docker >= 20.10
2. **系统资源**：至少1GB可用内存
3. **网络连接**：确保可以访问Docker Hub
4. **权限设置**：确保有Docker执行权限

更多详细信息，请查看项目中的其他文档文件。