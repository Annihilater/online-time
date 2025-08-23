# 安全配置和部署指南

## 📋 目录

- [概述](#概述)
- [安全架构](#安全架构)
- [快速开始](#快速开始)
- [详细配置](#详细配置)
- [安全检查清单](#安全检查清单)
- [监控和审计](#监控和审计)
- [事件响应](#事件响应)

## 概述

本指南提供了Online Time应用的完整安全配置，包括：

- 🔒 容器安全强化
- 🛡️ Web应用防火墙(WAF)
- 🔐 SSL/TLS加密
- 🗝️ 密钥管理
- 📊 安全监控
- 🔍 漏洞扫描

## 安全架构

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                              │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS
         ┌───────────▼───────────┐
         │   WAF (ModSecurity)   │ ◄── DDoS防护
         │   OWASP CRS 3.3       │     速率限制
         └───────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   Nginx (Reverse)     │ ◄── 安全头部
         │   SSL/TLS终止         │     CSP策略
         └───────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   应用容器            │ ◄── 只读文件系统
         │   (非root用户)        │     资源限制
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼───┐      ┌────▼────┐     ┌────▼────┐
│ Vault │      │ Falco   │     │ Trivy   │
│密钥管理│      │运行时监控│     │漏洞扫描 │
└───────┘      └─────────┘     └─────────┘
```

## 快速开始

### 1. 基础安全部署

```bash
# 克隆项目
git clone https://github.com/your-repo/online-time.git
cd online-time

# 运行安全审计
./security/security-audit.sh

# 生成SSL证书（开发环境）
./security/ssl/generate-ssl.sh localhost dev

# 启动安全容器
docker-compose -f security/docker-compose.secure.yml up -d
```

### 2. 生产环境部署

```bash
# 设置环境变量
export DOMAIN=your-domain.com
export ENVIRONMENT=production

# 生成生产SSL证书
./security/ssl/generate-ssl.sh $DOMAIN production

# 初始化密钥管理
docker-compose -f security/docker-compose.secure.yml --profile secrets up -d vault
./security/vault/init-vault.sh

# 启动WAF和应用
docker-compose -f security/docker-compose.secure.yml up -d waf online-time-app

# 启动运行时安全监控
docker-compose -f security/docker-compose.secure.yml --profile runtime-security up -d
```

## 详细配置

### 容器安全

#### Dockerfile安全强化

- ✅ 使用特定版本的基础镜像
- ✅ 以非root用户运行
- ✅ 最小化攻击面（distroless）
- ✅ 多阶段构建
- ✅ 健康检查配置

#### 运行时安全

```yaml
# 安全约束
security_opt:
  - no-new-privileges:true
  - apparmor:docker-default
  - seccomp:unconfined

# 能力限制
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE

# 只读文件系统
read_only: true
```

### 网络安全

#### SSL/TLS配置

```nginx
# 现代加密配置
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:...;
ssl_prefer_server_ciphers off;

# HSTS
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
```

#### 安全头部

```nginx
# 防止点击劫持
add_header X-Frame-Options "DENY";

# 防止MIME嗅探
add_header X-Content-Type-Options "nosniff";

# XSS保护
add_header X-XSS-Protection "1; mode=block";

# CSP策略
add_header Content-Security-Policy "default-src 'self'; ...";
```

### WAF配置

ModSecurity with OWASP CRS提供：

- SQL注入防护
- XSS攻击防护
- 路径遍历防护
- 命令注入防护
- 恶意扫描器检测

偏执级别设置：

```bash
# 1 = 最低，4 = 最高
PARANOIA=2  # 推荐生产环境
```

### 密钥管理

使用HashiCorp Vault管理：

- API密钥
- JWT密钥
- 数据库凭证
- SSL证书路径
- 监控令牌

```bash
# 获取密钥
vault kv get online-time/api

# 更新密钥
vault kv put online-time/api jwt_secret="new-secret"
```

## 安全检查清单

### 部署前检查

- [ ] 运行安全审计脚本
- [ ] 扫描Docker镜像漏洞
- [ ] 检查依赖项安全性
- [ ] 验证SSL/TLS配置
- [ ] 测试WAF规则
- [ ] 配置密钥管理
- [ ] 设置监控告警

### 定期安全任务

- [ ] 每日：检查安全日志
- [ ] 每周：运行漏洞扫描
- [ ] 每月：更新依赖项
- [ ] 每月：审查访问日志
- [ ] 每季度：安全审计
- [ ] 每年：渗透测试

## 监控和审计

### 日志收集

```bash
# 查看WAF日志
docker logs online-time-waf

# 查看审计日志
tail -f ./logs/audit/audit.log

# 查看Falco告警
docker logs online-time-falco
```

### 安全指标

- 阻止的攻击次数
- 异常流量模式
- 失败的认证尝试
- 资源使用异常
- 配置变更

### Grafana仪表板

访问 <http://localhost:3000> 查看：

- 安全事件趋势
- WAF性能指标
- 容器安全状态
- SSL证书过期时间

## 事件响应

### 响应流程

1. **检测** - 通过监控系统发现异常
2. **分析** - 确定事件类型和严重性
3. **遏制** - 隔离受影响的系统
4. **根除** - 删除威胁源
5. **恢复** - 恢复正常运营
6. **总结** - 记录经验教训

### 常见安全事件处理

#### DDoS攻击

```bash
# 启用速率限制
docker exec online-time-waf modsecurity-ctl --enable-rule 1001

# 添加IP黑名单
echo "192.168.1.100" >> /etc/nginx/blacklist.conf
nginx -s reload
```

#### 容器入侵

```bash
# 停止可疑容器
docker stop online-time-app

# 保存容器状态用于分析
docker commit online-time-app compromised-container

# 从安全镜像重新部署
docker-compose -f security/docker-compose.secure.yml up -d
```

#### 数据泄露

```bash
# 轮换所有密钥
./security/vault/rotate-secrets.sh

# 撤销受影响的令牌
vault token revoke -mode=orphan <token>

# 审查访问日志
grep -E "sensitive|api|token" ./logs/access.log
```

## 合规性

### OWASP Top 10 (2021)

| 风险 | 缓解措施 | 状态 |
|------|---------|------|
| A01: 访问控制失效 | WAF规则, 速率限制 | ✅ |
| A02: 加密失败 | TLS 1.2+, 强加密套件 | ✅ |
| A03: 注入 | ModSecurity, 输入验证 | ✅ |
| A04: 不安全设计 | 安全架构审查 | ✅ |
| A05: 安全配置错误 | 安全基线, 自动化扫描 | ✅ |
| A06: 易受攻击组件 | Trivy扫描, 定期更新 | ✅ |
| A07: 认证失败 | N/A (静态应用) | - |
| A08: 软件完整性失败 | CSP, SRI | ✅ |
| A09: 日志失败 | 集中日志, 审计 | ✅ |
| A10: SSRF | N/A (无服务端请求) | - |

### CIS Docker基准

- ✅ 2.1 限制网络流量
- ✅ 2.2 设置日志级别
- ✅ 3.1 验证镜像签名
- ✅ 4.1 限制容器能力
- ✅ 5.1 启用AppArmor
- ✅ 5.2 验证SELinux
- ✅ 5.3 限制Linux内核能力
- ✅ 5.4 不使用特权容器
- ✅ 5.5 不挂载敏感主机目录
- ✅ 5.6 不运行SSH

## 安全工具

### 扫描工具

```bash
# Trivy - 容器漏洞扫描
trivy image online-time:secure

# Grype - 依赖扫描
grype dir:.

# Nuclei - 应用安全扫描
nuclei -u https://localhost -t security/
```

### 测试工具

```bash
# OWASP ZAP - 动态扫描
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://localhost

# SQLMap - SQL注入测试
sqlmap -u "https://localhost/api?id=1" --batch

# Nikto - Web服务器扫描
nikto -h https://localhost
```

## 性能影响

安全措施的性能开销：

- WAF: ~5-10ms延迟
- SSL/TLS: ~2-5ms握手
- 日志记录: <1ms
- 加密存储: ~1-2ms

优化建议：

- 使用TLS会话缓存
- 启用HTTP/2
- 配置CDN
- 优化WAF规则

## 故障排除

### 常见问题

#### 证书错误

```bash
# 检查证书有效性
openssl x509 -in cert.pem -text -noout

# 验证证书链
openssl verify -CAfile ca.pem cert.pem
```

#### WAF误报

```bash
# 查看阻止日志
tail -f /var/log/modsecurity/audit.log

# 临时禁用规则
SecRuleRemoveById 941100
```

#### 容器权限问题

```bash
# 检查用户ID
docker exec online-time-app id

# 修复权限
docker exec online-time-app chown -R nginx:nginx /usr/share/nginx/html
```

## 资源链接

### 官方文档

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Mozilla SSL Configuration](https://ssl-config.mozilla.org/)

### 安全工具

- [Trivy](https://github.com/aquasecurity/trivy)
- [ModSecurity](https://github.com/SpiderLabs/ModSecurity)
- [Vault](https://www.vaultproject.io/)
- [Falco](https://falco.org/)

### 学习资源

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Nginx Security Controls](https://www.nginx.com/blog/nginx-security-controls/)
- [Web Security Academy](https://portswigger.net/web-security)

## 联系方式

安全问题报告：<security@online-time.com>
紧急响应热线：+1-xxx-xxx-xxxx

---

**最后更新**: 2024-01-20
**版本**: 1.0.0
**作者**: Security Team
