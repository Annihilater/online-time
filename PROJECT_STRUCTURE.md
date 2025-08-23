# 📁 项目目录结构说明

## 🎯 整理后的清晰结构

```
online-time/
├── 📄 项目核心文件
│   ├── README.md                 # 项目主文档
│   ├── CLAUDE.md                 # Claude配置
│   ├── package.json              # 项目依赖
│   ├── tsconfig.json             # TypeScript配置
│   └── vite.config.ts            # Vite构建配置
│
├── 📂 src/                       # 源代码 (不变)
│   ├── components/
│   ├── pages/
│   ├── shared/
│   └── ...
│
├── 📂 docker/                    # 🐳 Docker部署配置
│   ├── base/                     # 基础部署
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── nginx.conf
│   │   ├── config/               # 服务配置
│   │   ├── data/                 # 数据存储
│   │   └── logs/                 # 日志目录
│   ├── performance/              # 性能优化版
│   │   ├── docker-compose.yml
│   │   ├── redis-config/
│   │   └── monitoring/
│   ├── security/                 # 安全强化版
│   │   ├── docker-compose.yml
│   │   ├── waf/
│   │   └── ssl/
│   └── monitoring/               # 监控配置
│       ├── prometheus.yml
│       ├── grafana/
│       └── alerts/
│
├── 📂 scripts/                   # 🛠️ 自动化脚本
│   ├── deploy.sh                 # 主部署脚本
│   ├── setup/                    # 环境设置
│   ├── maintenance/              # 运维脚本
│   └── testing/                  # 测试脚本
│
├── 📂 docs/                      # 📚 项目文档
│   ├── deployment/               # 部署相关文档
│   │   ├── DEPLOYMENT_GUIDE.md
│   │   └── DOCKER_DEPLOYMENT.md
│   ├── development/              # 开发文档
│   │   └── README_QUICK_START.md
│   ├── operations/               # 运维文档
│   │   └── INFRASTRUCTURE.md
│   └── PROJECT_SUMMARY.md        # 项目总结
│
└── 📂 .config/                   # ⚙️ 开发配置
    ├── .claude/                  # Claude配置
    ├── environments/             # 环境配置
    └── tools/                    # 构建工具
        ├── Makefile
        ├── Makefile.infrastructure
        └── Makefile.security
```

## 🚀 快速使用指南

### 基础部署
```bash
# 基础Docker部署
docker-compose -f docker/base/docker-compose.yml up -d

# 使用部署脚本
./scripts/deploy.sh
```

### 性能优化版
```bash
# 启动性能优化版本
docker-compose -f docker/performance/docker-compose.simple.yml up -d
```

### 安全强化版
```bash
# 启动安全版本
docker-compose -f docker/security/docker-compose.secure.yml up -d
```

### 完整监控版
```bash
# 启动监控栈
docker-compose -f docker/monitoring/docker-compose.monitoring.yml up -d
```

## 📝 主要改进

✅ **根目录清爽**: 只保留核心项目文件  
✅ **分类清晰**: Docker、文档、脚本各自独立  
✅ **易于维护**: 相关文件集中管理  
✅ **便于扩展**: 新功能有明确的放置位置  

## 🔍 查找文件

- **部署问题** → `docs/deployment/`
- **Docker配置** → `docker/*/`  
- **开发指南** → `docs/development/`
- **运维工具** → `scripts/`
- **项目配置** → `.config/`

这样的结构让项目更专业、更易管理！