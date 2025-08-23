# Varnish Cache Configuration 
vcl 4.1;

import std;
import directors;

# 定义后端服务器
backend default {
    .host = "app";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 2s;
    .max_connections = 100;
    
    # 健康检查
    .probe = {
        .url = "/health";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

# 初始化
sub vcl_init {
    # 创建负载均衡器
    new lb = directors.round_robin();
    lb.add_backend(default);
}

# 接收请求
sub vcl_recv {
    # 设置后端
    set req.backend_hint = lb.backend();
    
    # 规范化URL
    set req.url = std.querysort(req.url);
    
    # 移除Google Analytics参数
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }
    
    # 移除多余的cookies
    if (req.http.Cookie) {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie, ";(SESS[a-z0-9]+|SSESS[a-z0-9]+|NO_CACHE)=", "; \1=");
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
        
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }
    
    # 处理健康检查
    if (req.url == "/health") {
        return (pass);
    }
    
    # 处理静态资源
    if (req.url ~ "\.(jpg|jpeg|png|gif|ico|svg|webp|avif|css|js|woff|woff2|ttf|eot|otf)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }
    
    # 处理API请求
    if (req.url ~ "^/api/") {
        # API请求不缓存
        return (pass);
    }
    
    # 处理POST请求
    if (req.method == "POST") {
        return (pass);
    }
    
    # 处理认证请求
    if (req.http.Authorization) {
        return (pass);
    }
    
    # 默认缓存HTML页面
    if (req.url ~ "\.html?$" || req.url == "/") {
        unset req.http.Cookie;
        return (hash);
    }
    
    # 其他请求
    return (hash);
}

# 后端响应
sub vcl_backend_response {
    # 设置默认TTL
    if (!beresp.http.Cache-Control) {
        set beresp.ttl = 1h;
    }
    
    # 静态资源长缓存
    if (bereq.url ~ "\.(jpg|jpeg|png|gif|ico|svg|webp|avif)(\?.*)?$") {
        set beresp.ttl = 7d;
        set beresp.grace = 24h;
        set beresp.http.Cache-Control = "public, max-age=604800";
    }
    
    # CSS和JS文件缓存
    if (bereq.url ~ "\.(css|js)(\?.*)?$") {
        set beresp.ttl = 1d;
        set beresp.grace = 12h;
        set beresp.http.Cache-Control = "public, max-age=86400";
    }
    
    # 字体文件缓存
    if (bereq.url ~ "\.(woff|woff2|ttf|eot|otf)(\?.*)?$") {
        set beresp.ttl = 30d;
        set beresp.grace = 24h;
        set beresp.http.Cache-Control = "public, max-age=2592000";
    }
    
    # HTML页面短缓存
    if (bereq.url ~ "\.html?$" || bereq.url == "/") {
        set beresp.ttl = 5m;
        set beresp.grace = 1h;
        set beresp.http.Cache-Control = "public, max-age=300";
    }
    
    # 启用ESI处理
    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;
        set beresp.do_esi = true;
    }
    
    # 错误页面不缓存
    if (beresp.status >= 400 && beresp.status < 600) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }
    
    # 设置grace期
    set beresp.grace = 6h;
    
    return (deliver);
}

# 缓存命中
sub vcl_hit {
    # 处理清除请求
    if (req.method == "PURGE") {
        return (synth(200, "Purged"));
    }
    
    # 返回缓存内容
    return (deliver);
}

# 缓存未命中
sub vcl_miss {
    # 处理清除请求
    if (req.method == "PURGE") {
        return (synth(404, "Not in cache"));
    }
    
    return (fetch);
}

# 发送响应
sub vcl_deliver {
    # 添加调试头（生产环境请删除）
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
    
    # 添加缓存年龄
    set resp.http.X-Cache-Age = obj.ttl;
    
    # 移除不需要的头
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
    unset resp.http.Via;
    unset resp.http.X-Varnish;
    
    # 添加安全头
    set resp.http.X-Frame-Options = "SAMEORIGIN";
    set resp.http.X-Content-Type-Options = "nosniff";
    set resp.http.X-XSS-Protection = "1; mode=block";
    set resp.http.Referrer-Policy = "strict-origin-when-cross-origin";
    
    return (deliver);
}

# 错误处理
sub vcl_backend_error {
    # 生成错误页面
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    set beresp.http.Retry-After = "5";
    
    synthetic({"
<!DOCTYPE html>
<html>
<head>
    <title>Service Temporarily Unavailable</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #e74c3c; }
        p { color: #7f8c8d; }
    </style>
</head>
<body>
    <h1>Service Temporarily Unavailable</h1>
    <p>The server is temporarily unable to service your request. Please try again later.</p>
    <p>Error "} + beresp.status + " " + beresp.reason + {"</p>
</body>
</html>
"});
    
    return (deliver);
}

# 合成响应
sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    
    synthetic({"
<!DOCTYPE html>
<html>
<head>
    <title>Error "} + resp.status + {"</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #e74c3c; }
        p { color: #7f8c8d; }
    </style>
</head>
<body>
    <h1>Error "} + resp.status + " " + resp.reason + {"</h1>
    <p>"} + resp.reason + {"</p>
</body>
</html>
"});
    
    return (deliver);
}

# 清理
sub vcl_fini {
    return (ok);
}