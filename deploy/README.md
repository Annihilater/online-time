# 在线时间工具 - 独立部署文档

> 🎯 **一键部署**，支持三种部署模式，生产就绪的Docker化在线时间工具集

## 📋 目录结构

```
deploy/
├── docker-compose.prod.yml    # 生产环境Docker Compose配置
├── docker-compose.ha.yml      # 高可用模式配置
├── .env.example              # 环境变量模板
├── .env.prod                 # 生产环境变量配置
├── deploy.sh                 # 🚀 一键部署脚本
├── stop.sh                   # 🔴 服务停止脚本
├── update.sh                 # 🔄 服务更新脚本
├── backup.sh                 # 💾 数据备份脚本
├── config/                   # 配置文件目录
│   ├── nginx.conf           # Nginx基础配置
│   ├── nginx-ha.conf        # Nginx高可用配置
│   ├── haproxy.cfg          # HAProxy负载均衡配置
│   ├── prometheus.yml       # 监控配置
├── data/                     # 数据持久化目录
├── logs/                     # 日志目录
└── README.md                 # 本文档
```

## 🚀 快速开始

### 1. 环境要求

**最低系统要求:**

- **操作系统:** Linux (Ubuntu 18.04+, CentOS 7+) 或 macOS
- **内存:** 1GB RAM (基础模式) / 2GB RAM (完整模式) / 4GB RAM (高可用模式)
- **存储:** 5GB 可用空间
- **网络:** 稳定的互联网连接

**必需软件:**

```bash
# Docker (20.10+)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose (1.29+)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 其他工具
sudo apt-get update && sudo apt-get install -y curl wget
```

### 2. 一键部署

```bash
# 1. 下载部署包
git clone https://github.com/your-org/online-time.git
cd online-time/deploy

# 2. 配置环境变量 (可选)
cp .env.example .env.prod
vim .env.prod  # 根据需要修改配置

# 3. 一键部署
./deploy.sh                # 基础模式
./deploy.sh full          # 完整模式 (包含Redis)
./deploy.sh ha            # 高可用模式 (包含负载均衡和监控)
```

**部署成功后访问:**

- 🌐 **主应用:** <http://localhost>
- 🩺 **健康检查:** <http://localhost/health>
- 📊 **监控面板:** <http://localhost:3001> (仅HA模式)

## 🎛️ 部署模式详解

### 基础模式 (basic)

**适用场景:** 个人使用、开发测试、小型团队

- ✅ Web应用容器
- ✅ Nginx反向代理
- ✅ 基本健康检查
- ✅ HTTP访问

```bash
./deploy.sh basic
```

### 完整模式 (full)

**适用场景:** 生产环境、中型团队

- ✅ 基础模式所有功能
- ✅ Redis缓存和会话存储
- ✅ 性能优化配置

```bash
./deploy.sh full
```

### 高可用模式 (ha)

**适用场景:** 企业级部署、高并发场景

- ✅ 完整模式所有功能
- ✅ 3个应用实例
- ✅ HAProxy负载均衡
- ✅ Redis主从复制
- ✅ Prometheus + Grafana监控
- ✅ 零宕机时间更新

```bash
./deploy.sh ha
```

## ⚙️ 配置详解

### 环境变量配置 (.env.prod)

```bash
# =================================
# 基础配置
# =================================
DEPLOY_MODE=basic              # 部署模式: basic | full | ha
DOCKER_IMAGE=ziji/online-time:latest  # Docker镜像
HTTP_PORT=80                   # HTTP端口
DOMAIN=your-domain.com         # 域名

# =================================
# Redis配置 (full/ha模式)
# =================================
REDIS_HOST=redis              # Redis主机
REDIS_PORT=6379               # Redis端口

# =================================
# 监控配置 (ha模式)
# =================================
PROMETHEUS_PORT=9090          # Prometheus端口
GRAFANA_PORT=3001             # Grafana端口
GRAFANA_PASSWORD=admin123     # Grafana密码

# =================================
# 性能配置
# =================================
WORKER_PROCESSES=auto         # Nginx工作进程数
APP_REPLICAS=3                # 应用实例数 (ha模式)
```

### 反向代理配置

如需要HTTPS支持，建议使用外部反向代理(如Nginx、Apache、Cloudflare等):

```bash
# 示例：使用系统Nginx配置HTTPS
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔧 运维操作

### 服务管理

```bash
# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看服务日志
docker-compose -f docker-compose.prod.yml logs -f

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 停止服务
./stop.sh

# 停止并清理
./stop.sh --clean

# 停止并删除数据 (危险!)
./stop.sh --volumes
```

### 服务更新

```bash
# 标准更新
./update.sh

# 更新到指定版本
./update.sh -t v1.2.0

# 更新前备份
./update.sh --backup

# 零宕机时间更新 (仅HA模式)
./update.sh --no-downtime

# 回滚到上一版本
./update.sh --rollback
```

### 数据备份

```bash
# 完整备份
./backup.sh

# 仅备份数据
./backup.sh -t data

# 压缩备份
./backup.sh --compress

# 列出所有备份
./backup.sh --list

# 从备份恢复
./backup.sh --restore backup-20231201-120000.tar.gz

# 清理旧备份
./backup.sh --clean
```

### 监控和诊断

```bash
# 健康检查
curl http://localhost/health

# 容器资源使用情况
docker stats

# 系统资源监控
htop

# 网络连接状态
netstat -tulnp | grep :80

# 磁盘空间检查
df -h
```

## 🔒 安全最佳实践

### 1. 防火墙配置

```bash
# UFW防火墙 (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw --force enable

# iptables防火墙
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
```

### 2. 系统安全加固

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban

# 禁用root登录
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 设置自动安全更新
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 3. Docker安全

```bash
# 非root用户运行Docker
sudo usermod -aG docker $USER
newgrp docker

# 启用Docker内容信任
export DOCKER_CONTENT_TRUST=1

# 定期清理无用镜像
docker system prune -f --volumes
```

## 📊 性能优化

### 1. 系统级优化

```bash
# 调整文件描述符限制
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# 优化内核参数
cat >> /etc/sysctl.conf << EOF
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fin_timeout = 30
EOF

sysctl -p
```

### 2. 应用级优化

**Nginx优化:**

```nginx
worker_processes auto;
worker_connections 4096;
keepalive_timeout 65;
gzip on;
```

**Redis优化:**

```bash
# Redis内存优化
maxmemory 256mb
maxmemory-policy allkeys-lru
```

### 3. Docker优化

```bash
# 限制容器资源
docker run --memory=512m --cpus=1.0 your-app

# 使用多阶段构建优化镜像大小
# 在Dockerfile中实现
```

## 🐛 故障排除

### 常见问题

**1. 端口被占用**

```bash
# 查找占用端口的进程
sudo netstat -tulnp | grep :80
sudo lsof -i :80

# 停止占用进程
sudo kill -9 <PID>
```

**2. 容器无法启动**

```bash
# 查看容器日志
docker logs <container-name>

# 检查Docker服务状态
sudo systemctl status docker

# 重启Docker服务
sudo systemctl restart docker
```

**3. 内存不足**

```bash
# 查看内存使用
free -h
docker stats

# 清理系统缓存
sudo sync
sudo echo 3 > /proc/sys/vm/drop_caches
```

**4. 网络连接问题**

```bash
# 检查端口占用
ss -tlnp | grep :80

# 测试HTTP连接
curl -I http://localhost
```

### 日志分析

```bash
# 应用日志
tail -f logs/app.log

# Nginx日志
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log

# 系统日志
sudo journalctl -u docker -f
sudo tail -f /var/log/syslog
```

## 📈 监控和告警

### Grafana仪表板 (HA模式)

访问 <http://localhost:3001>

- 用户名: admin
- 密码: 见 `GRAFANA_PASSWORD` 配置

**预置仪表板:**

- 📊 应用性能监控
- 🖥️ 系统资源监控
- 🌐 网络流量分析
- 🔍 错误日志追踪

### 告警配置

**邮件告警 (可选):**

```yaml
# config/alertmanager.yml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email-notifications'

receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@example.com'
    from: 'alerts@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'your-email@gmail.com'
    auth_password: 'your-app-password'
```

## 🔄 持续集成/部署

### GitHub Actions集成

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.4
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          cd /opt/online-time/deploy
          git pull origin main
          ./update.sh --backup
```

### 自动部署脚本

```bash
#!/bin/bash
# auto-deploy.sh - 自动拉取最新代码并部署

cd /opt/online-time/deploy

# 拉取最新代码
git pull origin main

# 检查是否有更新
if git diff HEAD@{1} --quiet; then
    echo "没有更新，跳过部署"
    exit 0
fi

# 自动部署
./update.sh --backup --force

# 发送通知 (可选)
curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"在线时间工具已成功更新部署"}' \
    YOUR_SLACK_WEBHOOK_URL
```

## 📞 技术支持

- 🐛 **问题反馈:** [GitHub Issues](https://github.com/your-org/online-time/issues)
- 📧 **邮件支持:** <support@example.com>
- 💬 **在线聊天:** [Slack](https://your-team.slack.com)
- 📖 **更多文档:** [Wiki](https://github.com/your-org/online-time/wiki)

## 📝 更新日志

### v1.0.0 (2023-12-01)

- ✅ 初始版本发布
- ✅ 支持三种部署模式
- ✅ 完整的运维脚本
- ✅ 生产级安全配置

---

**🎉 部署完成后，您就拥有了一个功能完整、高可用的在线时间工具集！**

如有任何问题，请参考故障排除章节或联系技术支持。
