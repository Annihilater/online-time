# 在线时间工具 - 运维监控指南

## 概述

本文档详细介绍了在线时间工具的完整监控和运维方案，包括系统监控、日志管理、告警配置和故障处理等。

## 监控架构

### 核心组件

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   应用服务层    │    │   监控数据层    │    │   可视化层      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Nginx         │───▶│ • Prometheus    │───▶│ • Grafana       │
│ • HAProxy       │    │ • Loki          │    │ • AlertManager  │
│ • App Instances │    │ • Node Exporter │    │ • 邮件/Slack    │
│ • Redis Cluster │    │ • cAdvisor      │    │ • 自定义仪表板  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 数据流

1. **指标收集**: Exporters → Prometheus
2. **日志收集**: Promtail → Loki
3. **告警处理**: Prometheus → AlertManager → 通知渠道
4. **数据可视化**: Grafana ← Prometheus/Loki

## 快速开始

### 1. 启动监控服务

```bash
# 启动完整监控栈
cd /path/to/deploy
./deploy.sh --monitoring

# 或仅启动基础监控
./deploy.sh --basic-monitoring
```

### 2. 访问监控面板

| 服务 | 默认地址 | 用户名 | 密码 |
|------|----------|--------|------|
| Grafana | http://localhost:3001 | admin | admin123 |
| Prometheus | http://localhost:9090 | - | - |
| AlertManager | http://localhost:9093 | - | - |
| HAProxy Stats | http://localhost:8404/stats | - | - |

### 3. 运行健康检查

```bash
# 快速健康检查
./scripts/health-check.sh

# 详细诊断
./scripts/diagnose.sh

# 实时监控
./scripts/monitor.sh realtime
```

## 监控指标说明

### 应用层指标

#### HTTP 请求指标
- **http_requests_total**: HTTP请求总数
- **http_request_duration_seconds**: 请求响应时间
- **http_requests_active**: 当前活跃请求数

#### 业务指标
- **active_users_total**: 当前活跃用户数
- **page_views_total**: 页面访问总数
- **feature_usage**: 功能使用统计

#### 服务健康指标
- **up**: 服务可用性 (1=可用, 0=不可用)
- **service_info**: 服务版本和元信息

### 系统层指标

#### CPU 指标
- **node_cpu_seconds_total**: CPU使用时间
- **node_load1/5/15**: 系统负载均值

#### 内存指标
- **node_memory_MemTotal_bytes**: 总内存
- **node_memory_MemAvailable_bytes**: 可用内存
- **node_memory_Cached_bytes**: 缓存内存

#### 磁盘指标
- **node_filesystem_size_bytes**: 文件系统大小
- **node_filesystem_avail_bytes**: 可用磁盘空间
- **node_disk_io_time_seconds_total**: 磁盘IO时间

#### 网络指标
- **node_network_receive_bytes_total**: 网络接收字节数
- **node_network_transmit_bytes_total**: 网络发送字节数

### 容器层指标

#### 容器资源
- **container_cpu_usage_seconds_total**: 容器CPU使用
- **container_memory_usage_bytes**: 容器内存使用
- **container_network_receive_bytes_total**: 容器网络接收

#### Docker指标
- **engine_daemon_network_actions_seconds**: Docker网络操作耗时
- **engine_daemon_container_actions_seconds**: 容器操作耗时

## 告警规则配置

### 告警级别

- **Critical**: 服务完全不可用，需要立即处理
- **Warning**: 性能下降或资源使用过高
- **Info**: 需要注意的状态变化

### 关键告警

#### 1. 服务可用性告警

```yaml
# 应用实例宕机
- alert: AppDown
  expr: up{job="online-time-app"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "应用实例 {{ $labels.instance }} 不可用"
```

#### 2. 性能告警

```yaml
# 响应时间过长
- alert: AppHighLatency
  expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
  for: 3m
  labels:
    severity: warning
  annotations:
    summary: "应用响应时间过长"
```

#### 3. 资源告警

```yaml
# CPU使用率过高
- alert: HighCPUUsage
  expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "CPU使用率过高: {{ $value }}%"
```

### 告警通知配置

#### 邮件通知

```yaml
# config/monitoring/alertmanager/alertmanager.yml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'ops@yourcompany.com'
        subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          告警: {{ .Annotations.summary }}
          详情: {{ .Annotations.description }}
          时间: {{ .StartsAt }}
          {{ end }}
```

#### Slack通知

```yaml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        title: 'Online Time Tool Alert'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Status:* {{ .Status }}
          *Instance:* {{ .Labels.instance }}
          {{ end }}
```

## 日志管理

### 日志架构

```
Application Logs ──┐
                  ├──▶ Promtail ──▶ Loki ──▶ Grafana
System Logs ──────┘
```

### 日志级别

- **ERROR**: 错误信息，需要关注
- **WARN**: 警告信息，可能需要处理
- **INFO**: 一般信息，用于追踪
- **DEBUG**: 调试信息，开发时使用

### 日志查询语法

#### 基本查询

```bash
# 查询特定服务的日志
{job="online-time-app"}

# 查询错误级别日志
{job="online-time-app"} |= "ERROR"

# 时间范围查询
{job="online-time-app"} [5m]
```

#### 高级查询

```bash
# 正则表达式过滤
{job="online-time-app"} |~ "ERROR|CRITICAL"

# JSON字段过滤
{job="online-time-app"} | json | level="error"

# 聚合查询
sum(rate({job="online-time-app"}[5m])) by (level)
```

### 日志轮转配置

```bash
# 日志轮转配置在 config/logrotate.conf
${DEPLOY_DIR}/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

## 仪表板配置

### 预配置仪表板

1. **应用概览仪表板** (`config/grafana/dashboards/app-overview.json`)
   - 服务状态和可用性
   - 请求速率和响应时间
   - 错误率和状态码分布

2. **系统资源仪表板** (`config/grafana/dashboards/system-resources.json`)
   - CPU、内存、磁盘使用率
   - 网络流量和连接数
   - 系统负载和进程信息

3. **容器监控仪表板**
   - 容器资源使用
   - Docker系统信息
   - 容器健康状态

### 自定义仪表板

#### 创建新仪表板

1. 登录Grafana (http://localhost:3001)
2. 点击 "+" → "Dashboard"
3. 添加Panel并配置查询
4. 保存仪表板

#### 导入仪表板

```bash
# 将仪表板JSON文件放到
config/grafana/dashboards/

# 重启Grafana服务
docker restart online-time-grafana
```

## 运维脚本使用

### 健康检查脚本

```bash
# 完整健康检查
./scripts/health-check.sh

# 检查特定组件
./scripts/health-check.sh --containers
./scripts/health-check.sh --services
./scripts/health-check.sh --resources
```

**健康检查内容:**
- Docker容器状态
- 应用服务可用性
- 系统资源使用
- 网络连通性
- 日志错误检查

### 性能监控脚本

```bash
# 生成性能报告
./scripts/monitor.sh report

# 实时监控
./scripts/monitor.sh realtime

# 性能基准测试
./scripts/monitor.sh benchmark
```

**监控内容:**
- 系统性能指标
- 容器资源使用
- 应用性能分析
- 网络性能监控
- 数据库性能监控

### 故障诊断脚本

```bash
# 完整诊断
./scripts/diagnose.sh

# 快速诊断
./scripts/diagnose.sh quick

# 特定组件诊断
./scripts/diagnose.sh docker
./scripts/diagnose.sh network
./scripts/diagnose.sh logs
```

**诊断内容:**
- 系统基础信息收集
- Docker环境诊断
- 应用服务诊断
- 网络连通性诊断
- 日志分析诊断
- 性能瓶颈诊断

### 定时任务管理

```bash
# 设置定时任务
./scripts/setup-cron.sh setup

# 查看定时任务状态
./scripts/setup-cron.sh status

# 卸载定时任务
./scripts/setup-cron.sh uninstall
```

**定时任务包括:**
- 每5分钟健康检查
- 每15分钟性能监控
- 每天备份和清理
- 每周系统维护
- 每月报告生成

## 故障排除指南

### 常见问题

#### 1. 服务无法访问

**症状**: 浏览器无法打开应用页面

**排查步骤**:
```bash
# 1. 检查容器状态
docker ps

# 2. 检查Nginx日志
docker logs online-time-nginx

# 3. 检查应用健康
./scripts/health-check.sh

# 4. 检查端口监听
ss -tuln | grep 80
```

**解决方案**:
- 重启异常容器: `docker restart <container_name>`
- 检查配置文件语法
- 查看防火墙设置

#### 2. 高CPU使用率

**症状**: 系统响应缓慢，CPU使用率持续过高

**排查步骤**:
```bash
# 1. 查看CPU使用情况
top -c

# 2. 检查容器资源使用
docker stats

# 3. 分析性能瓶颈
./scripts/monitor.sh performance

# 4. 查看应用日志
docker logs online-time-app-1 | grep ERROR
```

**解决方案**:
- 增加应用实例数量
- 优化应用代码
- 升级服务器配置

#### 3. 内存不足

**症状**: 系统频繁使用交换空间，应用响应慢

**排查步骤**:
```bash
# 1. 检查内存使用
free -h

# 2. 查看进程内存使用
ps aux --sort=-%mem | head -10

# 3. 检查容器内存限制
docker inspect <container_name> | grep -i memory

# 4. 查看内存泄漏
./scripts/diagnose.sh performance
```

**解决方案**:
- 重启内存使用过高的容器
- 调整容器内存限制
- 优化应用内存使用
- 增加系统内存

#### 4. 磁盘空间不足

**症状**: 磁盘使用率超过90%，写入操作失败

**排查步骤**:
```bash
# 1. 检查磁盘使用
df -h

# 2. 查找大文件
du -sh /* | sort -hr | head -10

# 3. 检查日志文件大小
du -sh ./logs/*

# 4. 检查Docker占用
docker system df
```

**解决方案**:
```bash
# 清理Docker资源
docker system prune -af --volumes

# 清理日志文件
./scripts/maintenance.sh custom cleanup logs

# 压缩旧日志
./scripts/maintenance.sh custom compress

# 紧急空间清理
./scripts/maintenance.sh emergency
```

### 应急响应流程

#### 1. 服务完全不可用

```bash
# 立即执行
1. 运行快速诊断
./scripts/diagnose.sh quick

2. 检查所有关键服务
./scripts/health-check.sh

3. 查看最近的错误日志
docker logs --tail=100 online-time-nginx
docker logs --tail=100 online-time-haproxy

4. 尝试重启服务
./stop.sh && ./deploy.sh
```

#### 2. 性能严重下降

```bash
# 性能问题排查
1. 检查系统资源
./scripts/monitor.sh system

2. 分析性能瓶颈
./scripts/diagnose.sh performance

3. 查看实时监控
./scripts/monitor.sh realtime

4. 执行紧急维护
./scripts/maintenance.sh emergency
```

#### 3. 数据安全问题

```bash
# 数据保护措施
1. 立即备份
./backup.sh --emergency

2. 检查安全日志
./scripts/diagnose.sh security

3. 隔离可疑容器
docker stop <suspicious_container>

4. 通知安全团队
# 发送告警邮件或Slack消息
```

## 性能优化建议

### 应用层优化

1. **启用缓存**
   - Redis缓存热点数据
   - Nginx缓存静态资源
   - 浏览器缓存配置

2. **负载均衡优化**
   - 调整HAProxy权重
   - 配置健康检查间隔
   - 启用连接复用

3. **数据库优化**
   - Redis内存配置优化
   - 键过期策略调整
   - 连接池配置

### 系统层优化

1. **资源配置**
   ```yaml
   # docker-compose.yml
   services:
     app:
       deploy:
         resources:
           limits:
             cpus: '1.0'
             memory: 512M
           reservations:
             cpus: '0.5'
             memory: 256M
   ```

2. **内核参数调优**
   ```bash
   # /etc/sysctl.conf
   net.core.somaxconn = 1024
   net.ipv4.tcp_max_syn_backlog = 1024
   vm.max_map_count = 262144
   ```

3. **文件系统优化**
   - 使用SSD存储
   - 启用文件系统缓存
   - 定期磁盘清理

### 监控优化

1. **指标收集频率**
   - 关键指标: 15s间隔
   - 一般指标: 30s间隔
   - 详细指标: 1m间隔

2. **数据保留策略**
   - 原始数据: 7天
   - 聚合数据: 30天
   - 历史数据: 90天

3. **告警优化**
   - 设置合理的阈值
   - 避免告警风暴
   - 配置告警静默期

## 安全配置

### 访问控制

1. **Grafana安全**
   ```yaml
   environment:
     - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
     - GF_USERS_ALLOW_SIGN_UP=false
     - GF_AUTH_ANONYMOUS_ENABLED=false
   ```

2. **Prometheus安全**
   - 配置基础认证
   - 限制访问来源IP
   - 启用HTTPS

3. **网络安全**
   - 配置防火墙规则
   - 使用内部网络通信
   - 定期安全扫描

### 数据保护

1. **敏感信息处理**
   - 使用环境变量存储密码
   - 日志脱敏处理
   - 定期密码轮换

2. **网络加密**
   - 启用SSL/TLS
   - 证书自动续期
   - 强制HTTPS重定向

## 容量规划

### 资源需求估算

#### 基础部署 (单实例)
- CPU: 2核
- 内存: 4GB
- 磁盘: 50GB
- 网络: 100Mbps

#### 高可用部署 (多实例)
- CPU: 4核
- 内存: 8GB
- 磁盘: 100GB
- 网络: 1Gbps

#### 监控服务资源
- Prometheus: 1GB内存, 10GB磁盘/月
- Grafana: 512MB内存, 1GB磁盘
- Loki: 2GB内存, 20GB磁盘/月

### 扩容策略

#### 水平扩容
```bash
# 增加应用实例
docker-compose up -d --scale app=5

# 添加Redis从节点
# 修改docker-compose.yml添加redis-slave-2
```

#### 垂直扩容
```yaml
# 调整资源限制
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1024M
```

### 监控扩容指标

- CPU使用率持续超过70%
- 内存使用率超过85%
- 磁盘使用率超过80%
- 网络带宽使用率超过70%
- 响应时间P95超过500ms

## 维护计划

### 日常维护 (自动化)

- **每5分钟**: 健康检查
- **每15分钟**: 性能监控
- **每小时**: 系统清理
- **每天**: 日志轮转和备份
- **每周**: 深度清理和安全检查

### 定期维护 (手动)

- **每周**: 检查和应用安全更新
- **每月**: 容量规划评估
- **每季度**: 性能基准测试
- **每半年**: 灾难恢复演练
- **每年**: 架构评估和优化

### 维护检查清单

#### 日常检查
- [ ] 所有服务运行正常
- [ ] 系统资源使用率正常
- [ ] 无关键告警
- [ ] 备份任务成功执行
- [ ] 日志无异常错误

#### 周检查
- [ ] 系统和软件更新
- [ ] 磁盘空间清理
- [ ] 性能趋势分析
- [ ] 安全日志检查
- [ ] 监控配置优化

#### 月检查
- [ ] 容量使用趋势分析
- [ ] 性能基线重新评估
- [ ] 灾备策略验证
- [ ] 文档更新
- [ ] 团队培训和知识分享

## 联系和支持

### 紧急联系

- **运维团队**: ops@yourcompany.com
- **开发团队**: dev@yourcompany.com
- **安全团队**: security@yourcompany.com

### 文档和资源

- **项目文档**: `/path/to/deploy/README.md`
- **故障手册**: `/path/to/deploy/TROUBLESHOOTING.md`
- **API文档**: `http://localhost/api/docs`
- **监控面板**: `http://localhost:3001`

### 更新记录

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| 1.0 | 2024-01-01 | 初始版本发布 |
| 1.1 | 2024-02-01 | 添加Loki日志监控 |
| 1.2 | 2024-03-01 | 完善告警规则 |

---

**注意**: 本文档需要根据实际部署环境和需求进行调整。建议定期更新以保持与系统的同步。