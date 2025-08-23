# 多阶段构建 - 构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制package文件并安装依赖 (包含开发依赖用于构建)
COPY package*.json ./
RUN npm ci --silent

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段 - 基于nginx:alpine
FROM nginx:alpine AS production

# 安装curl用于健康检查
RUN apk add --no-cache curl

# 创建nginx用户和组（如果不存在）
RUN addgroup -g 101 -S nginx || true
RUN adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx || true

# 复制自定义nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 从构建阶段复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 设置正确的权限
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# 切换到nginx用户（但不影响nginx运行）
# USER nginx

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]