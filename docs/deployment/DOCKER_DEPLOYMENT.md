# Docker 部署指南

在线闹钟项目的简化Docker部署指南。项目已简化为静态前端应用，Docker配置已经过优化。

## 快速开始

### 使用npm构建 + Docker部署（推荐）

```bash
# 构建生产版本
npm run build

# 构建Docker镜像
docker build -t online-time:latest .

# 运行容器
docker run -d --name online-time-app -p 80:80 online-time:latest
```

### 使用Docker一键构建

```bash
# 直接从源码构建并运行
docker build -t online-time:latest . && docker run -d --name online-time-app -p 80:80 online-time:latest
```

## 部署配置文件说明

### 1. Dockerfile
项目使用简化的多阶段构建：
- **构建阶段**：Node.js 18 Alpine，运行npm install和npm run build
- **运行阶段**：Nginx Alpine，只包含构建后的静态文件
- **非root用户**：提高安全性
- **健康检查**：HTTP健康检查端点

## 部署模式

### 单容器模式（推荐）
静态前端应用的最佳部署方式：

```bash
# 构建并运行
docker build -t online-time:latest .
docker run -d --name online-time-app -p 80:80 online-time:latest
```

### 多端口部署
同时在多个端口提供服务：

```bash
# 在8080端口运行
docker run -d --name online-time-8080 -p 8080:80 online-time:latest

# 在3000端口运行
docker run -d --name online-time-3000 -p 3000:80 online-time:latest
```

## 环境变量配置

由于是静态前端应用，环境变量在构建时确定：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NODE_ENV` | `production` | 构建环境 |
| `PORT` | `80` | Nginx端口 |
| `VITE_APP_TITLE` | `Online Time` | 应用标题 |

## 健康检查

简化的健康检查机制：

- **HTTP检查**：访问 `http://localhost/` 返回200表示正常
- **Docker健康检查**：自动每30秒检查一次
- **手动检查**：`curl -f http://localhost/ || exit 1`

## 日志管理

### 查看日志
```bash
# 查看容器日志
docker logs -f online-time-app

# 查看Nginx访问日志
docker exec online-time-app tail -f /var/log/nginx/access.log

# 查看Nginx错误日志
docker exec online-time-app tail -f /var/log/nginx/error.log
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

## 监控

### 基础监控
静态前端应用的监控相对简单：
- **可用性检查**：HTTP状态码监控
- **访问日志**：Nginx访问日志分析
- **容器状态**：Docker容器健康状态

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
curl -f http://localhost/ || echo "Service down"

# 查看详细日志
docker logs online-time-app --tail 50
```

**4. 构建失败**
```bash
# 清理Docker缓存
docker system prune -f

# 重新构建
docker rmi online-time:latest
docker build -t online-time:latest .
```

### 调试命令

```bash
# 进入容器调试
docker exec -it online-time-app sh

# 检查容器资源使用
docker stats online-time-app

# 检查Nginx配置
docker exec online-time-app nginx -t

# 检查静态文件
docker exec online-time-app ls -la /usr/share/nginx/html/
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
docker stop online-time-app
docker rm online-time-app

# 删除镜像
docker rmi online-time:latest

# 清理未使用的资源
docker system prune -f
```

## 技术支持

如果遇到部署问题，请检查：

1. **Docker版本**：确保Docker >= 20.10
2. **系统资源**：至少1GB可用内存
3. **网络连接**：确保可以访问Docker Hub
4. **权限设置**：确保有Docker执行权限

更多详细信息，请查看项目中的其他文档文件。