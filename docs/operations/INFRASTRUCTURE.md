# 基础设施配置文档

## 概述

本项目的基础设施配置专注于生产级别的稳定性、可观测性和可维护性。配置包括完整的监控栈、高可用性部署、自动化运维脚本和多环境支持。

## 目录结构

```
├── monitoring/                    # 监控配置
│   ├── prometheus.yml            # Prometheus配置
│   ├── alertmanager.yml          # 告警管理配置
│   ├── loki-config.yml           # 日志聚合配置
│   ├── promtail-config.yml       # 日志收集配置
│   ├── alerts/                   # 告警规则
│   │   └── app-alerts.yml        # 应用告警规则
│   └── grafana/                  # Grafana配置
│       ├── provisioning/         # 数据源和仪表板配置
│       └── dashboards/           # 预定义仪表板
├── config/                       # 运行时配置
│   ├── haproxy.cfg              # HAProxy负载均衡配置
│   ├── redis.conf               # Redis配置
│   └── keepalived.conf          # VIP配置(可选)
├── environments/                 # 环境配置
│   ├── dev/.env                 # 开发环境
│   ├── test/.env                # 测试环境
│   ├── prod/.env                # 生产环境
│   └── docker-compose.override.yml
├── scripts/                      # 运维脚本
│   ├── health/health-check.sh   # 健康检查脚本
│   ├── backup/                  # 备份恢复脚本
│   │   ├── backup.sh
│   │   └── restore.sh
│   ├── monitoring/monitor.sh    # 系统监控脚本
│   └── deploy-infrastructure.sh # 自动化部署脚本
└── docker-compose files/        # Docker编排文件
    ├── docker-compose.yml       # 基础服务
    ├── docker-compose.monitoring.yml
    └── docker-compose.ha.yml
```

## 监控和告警

### 监控栈组件

- **Prometheus**: 指标收集和存储
- **Grafana**: 可视化仪表板
- **AlertManager**: 告警管理和通知
- **Loki**: 日志聚合
- **Promtail**: 日志收集
- **Node Exporter**: 系统指标
- **cAdvisor**: 容器指标

### 启动监控服务

```bash
# 启动完整监控栈
docker-compose -f docker-compose.monitoring.yml up -d

# 或使用Makefile
make -f Makefile.infrastructure monitoring-up
```

### 访问地址

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin123)
- AlertManager: http://localhost:9093

### 告警规则

配置的关键告警包括:
- 应用服务不可用
- HTTP响应时间过高 (>1s)
- 错误率过高 (>5%)
- CPU使用率过高 (>80%)
- 内存使用率过高 (>85%)
- 磁盘空间不足 (<20%)
- 容器重启频繁

## 高可用性部署

### 架构特点

- 多应用实例 + HAProxy负载均衡
- Redis缓存共享会话
- 健康检查和自动故障转移
- 资源限制和保留
- 优雅关闭和重启策略

### 启动高可用部署

```bash
# 启动高可用服务
docker-compose -f docker-compose.ha.yml up -d

# 或使用Makefile
make -f Makefile.infrastructure ha-up
```

### HAProxy统计页面

访问 http://localhost:8404/stats 查看负载均衡状态

## 环境配置管理

### 环境切换

```bash
# 设置开发环境
make -f Makefile.infrastructure ENV=dev env-setup

# 设置生产环境
make -f Makefile.infrastructure ENV=prod env-setup
```

### 配置差异

| 配置项 | 开发环境 | 生产环境 |
|--------|----------|----------|
| 日志级别 | debug | info |
| 资源限制 | 低 | 高 |
| 备份保留 | 7天 | 30天 |
| 缓存TTL | 1小时 | 2小时 |
| 安全头 | 基础 | 完整 |

## 运维脚本

### 健康检查

```bash
# 执行完整健康检查
./scripts/health/health-check.sh

# 或使用Makefile
make -f Makefile.infrastructure health-check
```

检查内容:
- HTTP服务可用性
- 容器运行状态
- 系统资源使用
- 磁盘空间
- 内存使用

### 系统监控

```bash
# 执行完整系统监控
./scripts/monitoring/monitor.sh

# 监控特定组件
./scripts/monitoring/monitor.sh system    # 系统资源
./scripts/monitoring/monitor.sh containers # 容器状态
./scripts/monitoring/monitor.sh http       # HTTP服务
./scripts/monitoring/monitor.sh logs       # 日志文件
```

### 备份管理

```bash
# 执行完整备份
./scripts/backup/backup.sh full

# 分别备份
./scripts/backup/backup.sh config  # 配置文件
./scripts/backup/backup.sh data     # 数据文件

# 查看可用备份
./scripts/backup/restore.sh list

# 恢复配置
./scripts/backup/restore.sh config config_backup_20231201_120000.tar.gz
```

## 自动化部署

### 部署脚本

```bash
# 开发环境基础部署
./scripts/deploy-infrastructure.sh dev basic

# 生产环境完整部署
./scripts/deploy-infrastructure.sh prod full

# 仅部署监控服务
./scripts/deploy-infrastructure.sh prod monitoring
```

### 部署类型

- **basic**: 仅基础应用服务
- **monitoring**: 基础服务 + 监控栈
- **ha**: 高可用性部署
- **full**: 所有服务(基础 + 监控 + 高可用)

## 使用Makefile管理

### 常用命令

```bash
# 查看所有可用命令
make -f Makefile.infrastructure help

# 环境管理
make -f Makefile.infrastructure env-setup ENV=prod
make -f Makefile.infrastructure env-validate

# 服务管理
make -f Makefile.infrastructure monitoring-up
make -f Makefile.infrastructure ha-up
make -f Makefile.infrastructure status

# 运维任务
make -f Makefile.infrastructure health-check
make -f Makefile.infrastructure backup
make -f Makefile.infrastructure logs-cleanup
make -f Makefile.infrastructure maintenance

# 一键部署
make -f Makefile.infrastructure deploy-dev
make -f Makefile.infrastructure deploy-prod
```

## 性能优化配置

### Nginx优化
- Gzip压缩启用
- 静态文件缓存
- 连接池优化
- Worker进程自动调整

### Redis优化
- 内存策略: allkeys-lru
- 持久化: RDB + AOF
- 连接池配置
- 慢查询监控

### 容器优化
- 多阶段构建减少镜像大小
- 资源限制防止过度使用
- 健康检查确保服务可用性
- 优雅关闭处理

## 安全配置

### 网络安全
- 安全头设置
- CSP策略
- 端口限制
- 内部网络隔离

### 访问控制
- 非root用户运行
- 文件权限限制
- 密码复杂度要求
- 敏感数据环境变量化

### 更新默认密码

```bash
# 更新提醒
make -f Makefile.infrastructure update-passwords
```

必须更新的默认密码:
1. Redis密码
2. Grafana管理员密码
3. 告警通知webhook地址

## 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看服务日志
   docker-compose logs service_name
   
   # 检查端口占用
   netstat -tlnp | grep :端口号
   ```

2. **磁盘空间不足**
   ```bash
   # 清理Docker资源
   make -f Makefile.infrastructure system-cleanup
   
   # 清理旧日志
   make -f Makefile.infrastructure logs-cleanup
   ```

3. **监控数据丢失**
   ```bash
   # 检查数据卷
   docker volume ls | grep online-time
   
   # 从备份恢复
   ./scripts/backup/restore.sh monitoring prometheus backup_file.tar.gz
   ```

### 日志位置

- 应用日志: `logs/app.log`
- 健康检查日志: `logs/health-check.log`
- 监控日志: `logs/monitor.log`
- 备份日志: `logs/backup.log`
- 部署日志: `logs/deploy.log`

## 维护计划

### 定期任务

- **每日 2:00**: 全量备份
- **每小时**: 健康检查
- **每5分钟**: 系统监控
- **每周日 3:00**: 日志清理

### 月度维护

1. 检查并更新Docker镜像
2. 审核告警配置
3. 清理过期备份
4. 系统安全扫描
5. 性能数据分析

### 季度维护

1. 容量规划评估
2. 灾难恢复演练
3. 依赖组件更新
4. 安全策略评审
5. 文档更新

## 扩展指南

### 添加新的监控指标

1. 在 `monitoring/prometheus.yml` 中添加新的 scrape_configs
2. 在 `monitoring/alerts/` 中添加相应的告警规则
3. 在Grafana中创建相应的仪表板

### 添加新的环境

1. 在 `environments/` 下创建新环境目录
2. 复制现有 `.env` 文件并修改配置
3. 更新部署脚本支持新环境

### 集成外部服务

1. 在相应的 docker-compose 文件中添加服务定义
2. 更新监控配置以包含新服务
3. 添加相应的健康检查和备份逻辑

## 支持和联系

如有问题或建议，请查看:
- 项目日志文件
- Docker容器日志
- 监控仪表板告警
- 系统资源使用情况

通过完善的基础设施配置，确保Online Time应用在各种环境下都能稳定、高效地运行。