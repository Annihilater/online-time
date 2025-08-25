# Online Time - 生产级单容器部署
# 使用多阶段构建优化镜像大小
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制package文件并安装所有依赖（包含devDependencies用于构建）
COPY package*.json ./
RUN npm ci && npm cache clean --force

# 复制源代码
COPY . .

# 构建生产版本
RUN npm run build

# 生产阶段 - 使用nginx提供静态文件服务
FROM nginx:alpine

# 安装curl用于健康检查
RUN apk add --no-cache curl

# 复制构建产物到nginx目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 创建nginx日志目录
RUN mkdir -p /var/log/nginx

# 暴露9653端口用于1Panel反向代理
EXPOSE 9653

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:9653/health || exit 1

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]