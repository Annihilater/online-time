# 在线闹钟网站 - 部署指南

## 🚀 快速部署

### 前置要求
- Node.js >= 18.0.0
- npm >= 9.0.0

### 本地构建
```bash
# 安装依赖
npm install

# 运行构建
npm run build

# 本地预览
npm run preview
```

## 📦 部署方式

### 1. 静态网站托管（推荐）

#### Vercel 部署
```bash
# 安装 Vercel CLI
npm install -g vercel

# 部署
vercel --prod
```

**配置文件** (`vercel.json`):
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "dist"
      }
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

#### Netlify 部署
```bash
# 构建设置
Build command: npm run build
Publish directory: dist
```

**配置文件** (`netlify.toml`):
```toml
[build]
  publish = "dist"
  command = "npm run build"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

#### GitHub Pages 部署
```bash
# 安装 gh-pages
npm install --save-dev gh-pages

# 添加部署脚本到 package.json
"scripts": {
  "deploy": "gh-pages -d dist"
}

# 部署
npm run build
npm run deploy
```

### 2. Docker 部署

**Dockerfile**:
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf**:
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # SPA路由支持
        location / {
            try_files $uri $uri/ /index.html;
        }

        # 静态资源缓存
        location /assets/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # 音效文件缓存
        location /sounds/ {
            expires 30d;
            add_header Cache-Control "public";
        }

        # 安全头部
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
    }
}
```

**构建和运行**:
```bash
# 构建镜像
docker build -t online-time .

# 运行容器
docker run -p 80:80 online-time
```

### 3. CDN 加速部署

#### 阿里云 OSS + CDN
```bash
# 安装阿里云 CLI
npm install -g @alicloud/cli

# 上传到 OSS
# 配置 CDN 域名
# 设置缓存策略
```

#### 腾讯云 COS + CDN
```bash
# 安装腾讯云 CLI
npm install -g qcloud-cli

# 上传到 COS
# 配置 CDN 加速
```

## ⚙️ 环境配置

### 环境变量 (可选)
```bash
# .env.production
VITE_APP_TITLE="在线闹钟"
VITE_API_BASE_URL=""
VITE_ANALYTICS_ID=""
```

### 构建优化配置

**package.json** 构建脚本:
```json
{
  "scripts": {
    "build": "tsc -b && vite build",
    "build:analyze": "npm run build && npx vite-bundle-analyzer dist",
    "preview": "vite preview --host",
    "deploy:vercel": "vercel --prod",
    "deploy:netlify": "netlify deploy --prod --dir=dist"
  }
}
```

## 🔧 性能优化

### 1. 资源优化
- **图片压缩**: 使用 WebP 格式
- **字体优化**: 子集化中文字体
- **代码分割**: 按页面分包加载

### 2. 缓存策略
```nginx
# HTML 文件 - 不缓存
location ~* \.html$ {
    expires -1;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

# JS/CSS 文件 - 长期缓存
location ~* \.(js|css)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 音效文件 - 中期缓存
location ~* \.(mp3|wav)$ {
    expires 30d;
    add_header Cache-Control "public";
}
```

### 3. GZIP 压缩
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/javascript
    application/xml
    application/rss+xml
    application/atom+xml
    image/svg+xml;
```

## 📊 监控配置

### 1. 性能监控
```javascript
// Google Analytics 4
window.gtag('config', 'GA_MEASUREMENT_ID', {
  page_title: document.title,
  page_location: window.location.href
});

// Web Vitals
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

getCLS(console.log);
getFID(console.log);
getFCP(console.log);
getLCP(console.log);
getTTFB(console.log);
```

### 2. 错误监控
```javascript
// Sentry 错误监控
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "YOUR_SENTRY_DSN",
  integrations: [new Sentry.BrowserTracing()],
  tracesSampleRate: 1.0,
});
```

## 🔒 安全配置

### HTTPS 配置
```nginx
# SSL 证书配置
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    return 301 https://$server_name$request_uri;
}
```

### 安全头部
```nginx
# 安全头部配置
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self';" always;
```

## 🚨 故障排除

### 常见问题

1. **页面刷新404错误**
   - 确保配置了SPA路由重定向规则
   - 检查 `try_files` 或重定向配置

2. **静态资源加载失败**
   - 检查资源路径配置
   - 确认base URL设置正确

3. **音效文件无法播放**
   - 检查音频文件格式支持
   - 确认MIME类型配置正确

4. **移动端适配问题**
   - 检查viewport meta标签
   - 验证响应式断点配置

### 调试工具
```bash
# 本地调试
npm run dev

# 构建分析
npm run build:analyze

# 预览构建结果
npm run preview
```

## 📈 优化建议

1. **首屏加载优化**
   - 使用骨架屏
   - 预加载关键资源
   - 代码分割优化

2. **用户体验提升**
   - PWA 支持
   - 离线缓存
   - 推送通知

3. **SEO 优化**
   - Meta 标签优化
   - 结构化数据
   - 站点地图

4. **国际化支持**
   - 多语言配置
   - 时区适配
   - 本地化内容

---

## 📞 技术支持

如遇到部署问题，请参考：
- **[项目配置文档](./CLAUDE.md)** - 完整开发环境配置
- **[快速启动指南](./README_QUICK_START.md)** - 本地运行说明
- [Vite 构建指南](https://vitejs.dev/guide/build.html) - 官方文档
- [React Router 部署](https://reactrouter.com/en/main/guides/deploying) - 路由部署

部署完成后，访问网站验证所有功能正常运行。