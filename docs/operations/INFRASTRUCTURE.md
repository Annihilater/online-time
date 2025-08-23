# 基础设施配置文档（已简化）

## 概述

此文档为历史参考。项目已简化为静态前端应用，原有的复杂监控和基础设施配置已移除。

**重要说明**: 项目现在使用简化的架构，不再需要复杂的监控栈、高可用部署和运维脚本。

## 当前架构

### 技术栈
- **前端**: React 19 + TypeScript + Vite
- **样式**: Tailwind CSS + DaisyUI
- **状态管理**: Zustand
- **部署**: 静态文件 + Nginx Docker容器

### 部署模式
```bash
# 开发环境
npm run dev

# 生产构建
npm run build

# Docker部署
docker build -t online-time:latest .
docker run -d --name online-time-app -p 80:80 online-time:latest
```

## 监控和运维（已简化）

### 健康检查
```bash
# 检查服务状态
curl -f http://localhost/ || echo "Service down"

# 检查容器状态
docker ps | grep online-time

# 查看容器日志
docker logs online-time-app --tail 50
```

### 基础监控
- **HTTP状态检查**: 访问主页返回200状态码
- **容器健康状态**: Docker原生健康检查
- **访问日志**: Nginx访问日志

### 资源监控
```bash
# 检查容器资源使用
docker stats online-time-app --no-stream

# 检查系统资源
df -h
free -m
```

## 维护任务

### 日常维护
- 检查容器运行状态
- 查看访问日志
- 验证应用功能正常

### 定期维护
- 更新基础镜像（Node.js, Nginx）
- 更新npm依赖
- 检查安全漏洞（npm audit）

### 备份（简化）
```bash
# 备份镜像
docker save online-time:latest > online-time-backup.tar

# 恢复镜像
docker load < online-time-backup.tar
```

## 故障排除

### 常见问题
1. **容器无法启动**
   ```bash
   docker logs online-time-app
   docker inspect online-time-app
   ```

2. **服务不可访问**
   ```bash
   curl -I http://localhost/
   netstat -tlnp | grep :80
   ```

3. **资源不足**
   ```bash
   docker stats
   df -h
   ```

## 历史配置（已移除）

以下组件和配置已从项目中移除：
- ~~Prometheus监控栈~~
- ~~Grafana仪表板~~
- ~~AlertManager告警~~
- ~~HAProxy负载均衡~~
- ~~Redis缓存~~
- ~~复杂的运维脚本~~
- ~~多环境配置管理~~

**总结**: 项目已简化为静态前端应用，不再需要复杂的基础设施配置。现在的部署方式更加简单高效，使用npm + Docker即可实现稳定运行。