# ⚡ 快速部署指南

> 5分钟内完成在线时间工具的一键部署

## 🚀 超级快速开始

```bash
# 1. 克隆项目
git clone https://github.com/your-org/online-time.git
cd online-time/deploy

# 2. 一键部署 (基础模式)
./deploy.sh

# 3. 访问应用
open http://localhost
```

**就这么简单！** 🎉

## 📋 前置条件检查

运行部署前，请确保已安装：
- ✅ Docker (20.10+)
- ✅ Docker Compose (1.29+)
- ✅ curl, wget

**自动安装脚本 (Ubuntu/Debian):**
```bash
# 一键安装所有依赖
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt update && sudo apt install -y curl wget

# 重新登录或运行
newgrp docker
```

## 🎛️ 三种部署模式

### 🔰 基础模式 (推荐新手)
```bash
./deploy.sh basic
```
- Web应用 + Nginx
- 适合：个人使用、测试环境

### 🔄 完整模式 (推荐生产)
```bash
./deploy.sh full
```
- 基础功能 + Redis缓存
- 适合：小到中型生产环境

### 🏢 高可用模式 (企业级)
```bash
./deploy.sh ha
```
- 多实例 + 负载均衡 + 监控
- 适合：高并发、企业级部署

## ⚙️ 快速配置

**只需编辑一个文件：** `.env.prod`

```bash
# 复制配置模板
cp .env.example .env.prod

# 编辑配置 (可选)
vim .env.prod

# 重要配置项:
HTTP_PORT=80              # 访问端口
DOMAIN=your-domain.com    # 域名 (可选)
ENABLE_HTTPS=false        # 启用HTTPS (可选)
```

## 🔧 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
./stop.sh

# 更新服务
./update.sh

# 备份数据
./backup.sh
```

## 🌐 访问地址

部署成功后访问：
- **主应用:** http://localhost
- **健康检查:** http://localhost/health

高可用模式额外提供：
- **监控面板:** http://localhost:3001 (用户名: admin, 密码: admin123)
- **负载均衡统计:** http://localhost:8404/stats

## 🆘 遇到问题？

**端口被占用？**
```bash
# 修改端口
echo "HTTP_PORT=8080" >> .env.prod
./deploy.sh --force
```

**服务启动失败？**
```bash
# 查看详细日志
docker-compose logs

# 重新部署
./deploy.sh --force
```

**需要HTTPS？**
```bash
# 1. 准备SSL证书
mkdir -p config/ssl
# 将证书文件复制到 config/ssl/

# 2. 启用HTTPS
echo "ENABLE_HTTPS=true" >> .env.prod
./deploy.sh --force
```

## 📊 部署验证

```bash
# 健康检查
curl http://localhost/health

# 响应应该是：
# healthy
```

## 🎯 下一步

- 📖 阅读完整文档: [README.md](./README.md)
- 🔒 配置SSL证书
- 📊 设置监控告警
- 💾 配置定期备份

---

**🚀 享受您的在线时间工具吧！**