#!/bin/bash

# =================================
# 快速跨平台构建脚本
# =================================

set -e

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 开始跨平台构建...${NC}"

# 构建并推送多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag klause/online-time:latest \
  --push \
  .

echo -e "${GREEN}✅ 构建完成！${NC}"

echo -e "${YELLOW}现在在生产服务器上运行：${NC}"
echo "docker pull klause/online-time:latest"
echo "./stop.sh && ./start.sh 1panel"