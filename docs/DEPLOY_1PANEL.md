# 1Panel 单容器部署指南

## 🚀 快速部署

### 方法一：使用Just命令（推荐）

```bash
# 一键部署到端口9653
just deploy

# 或使用完整命令
just deploy-1panel
```

### 方法二：使用Docker命令

```bash
# 构建镜像
docker build -t online-time:latest .

# 运行容器
docker run -d \
  --name online-time-app \
  -p 9653:9653 \
  --restart unless-stopped \
  online-time:latest
```

### 方法三：使用Docker Compose

```bash
# 使用简化配置文件
docker-compose -f docker-compose.simple.yml up -d
```

## 🔧 1Panel 反向代理配置

### 1. 创建网站
- 在1Panel中创建新网站
- 选择"反向代理"类型

### 2. 反向代理设置
```
代理地址: http://127.0.0.1:9653
```

### 3. 可选：SSL证书
- 在1Panel中为域名申请SSL证书
- 启用HTTPS访问

## 📊 部署信息

| 配置项 | 值 |
|--------|-----|
| **内部端口** | 9653 |
| **容器名称** | online-time-app |
| **镜像名称** | online-time:latest |
| **重启策略** | unless-stopped |
| **健康检查** | /health 端点 |
| **日志轮转** | 10MB × 3个文件 |

## 🔍 验证部署

### 检查容器状态
```bash
# 查看容器运行状态
docker ps | grep online-time

# 查看容器日志
docker logs online-time-app

# 健康检查
curl http://localhost:9653/health
```

### 验证功能
1. **基础访问**: `http://localhost:9653`
2. **健康检查**: `http://localhost:9653/health`
3. **静态资源**: 自动缓存优化
4. **SPA路由**: 支持前端路由

## 🛠️ 管理命令

```bash
# 查看部署状态
just docker-logs

# 重启服务
docker restart online-time-app

# 更新部署
just deploy  # 自动停止旧容器并部署新版本

# 停止服务
just docker-stop

# 清理资源
just docker-clean
```

## ⚡ 性能优化

### 已内置优化
- ✅ **Gzip压缩** - 减少传输大小
- ✅ **静态资源缓存** - 1年缓存期
- ✅ **音频文件缓存** - 7天缓存期  
- ✅ **HTML防缓存** - 确保更新及时
- ✅ **多阶段构建** - 最小化镜像大小
- ✅ **健康检查** - 自动故障恢复

### 1Panel优化建议
1. **启用CDN** - 加速静态资源访问
2. **配置缓存** - 在反向代理层添加缓存
3. **监控告警** - 设置服务监控

## 🔒 安全配置

### 已内置安全头
```
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: no-referrer-when-downgrade
Content-Security-Policy: default-src 'self' http: https: data: blob: 'unsafe-inline'
```

### 建议在1Panel中配置
- 启用防火墙只允许必要端口
- 定期更新容器镜像
- 配置访问日志和监控

## 🆘 故障排除

### 常见问题

#### 1. 端口占用
```bash
# 检查端口占用
lsof -i :9653

# 停止占用进程或更换端口
```

#### 2. 容器启动失败
```bash
# 查看详细日志
docker logs online-time-app

# 检查镜像是否构建成功
docker images | grep online-time
```

#### 3. 1Panel反向代理不通
- 确认容器在9653端口正常运行
- 检查1Panel反向代理配置
- 验证防火墙设置

#### 4. 静态资源404
- 检查构建是否成功：`ls -la dist/`
- 确认nginx配置正确加载

## 📈 监控指标

### 健康检查端点
- **URL**: `/health`
- **返回**: `healthy` (200状态码)
- **用途**: 1Panel监控、负载均衡器健康检查

### 容器资源使用
```bash
# 查看资源使用情况
docker stats online-time-app

# 查看详细信息
docker inspect online-time-app
```

---

## 🎯 完整部署流程

1. **准备环境**
   ```bash
   # 确保Docker已安装
   docker --version
   
   # 确保Just已安装（可选）
   just --version
   ```

2. **部署应用**
   ```bash
   # 克隆项目（如果需要）
   git clone <项目地址>
   cd online-time
   
   # 一键部署
   just deploy
   ```

3. **配置1Panel**
   - 创建反向代理网站
   - 代理地址：`http://127.0.0.1:9653`
   - 绑定域名和SSL证书

4. **验证部署**
   ```bash
   # 检查服务状态
   curl http://localhost:9653/health
   
   # 通过域名访问
   curl https://your-domain.com
   ```

**部署完成！🎉**