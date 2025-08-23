#!/bin/bash

# SSL/TLS证书生成脚本
# 用于生成自签名证书（开发/测试）或准备Let's Encrypt证书（生产）

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SSL_DIR="./security/ssl"
DOMAIN="${1:-localhost}"
ENVIRONMENT="${2:-dev}"

# 创建SSL目录
mkdir -p "${SSL_DIR}/certs" "${SSL_DIR}/private" "${SSL_DIR}/dhparam"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 生成自签名证书（开发环境）
generate_self_signed() {
    log_info "Generating self-signed certificate for ${DOMAIN}..."
    
    # 生成私钥
    openssl genrsa -out "${SSL_DIR}/private/${DOMAIN}.key" 4096
    
    # 生成证书签名请求
    openssl req -new \
        -key "${SSL_DIR}/private/${DOMAIN}.key" \
        -out "${SSL_DIR}/certs/${DOMAIN}.csr" \
        -subj "/C=US/ST=State/L=City/O=OnlineTime/OU=IT/CN=${DOMAIN}"
    
    # 生成自签名证书（有效期1年）
    openssl x509 -req \
        -days 365 \
        -in "${SSL_DIR}/certs/${DOMAIN}.csr" \
        -signkey "${SSL_DIR}/private/${DOMAIN}.key" \
        -out "${SSL_DIR}/certs/${DOMAIN}.crt"
    
    # 生成完整证书链
    cat "${SSL_DIR}/certs/${DOMAIN}.crt" > "${SSL_DIR}/certs/${DOMAIN}.pem"
    
    # 设置权限
    chmod 400 "${SSL_DIR}/private/${DOMAIN}.key"
    chmod 444 "${SSL_DIR}/certs/${DOMAIN}.crt"
    chmod 444 "${SSL_DIR}/certs/${DOMAIN}.pem"
    
    log_success "Self-signed certificate generated successfully"
}

# 生成DH参数（提高安全性）
generate_dhparam() {
    log_info "Generating DH parameters (this may take a while)..."
    
    if [ ! -f "${SSL_DIR}/dhparam/dhparam.pem" ]; then
        openssl dhparam -out "${SSL_DIR}/dhparam/dhparam.pem" 2048
        chmod 444 "${SSL_DIR}/dhparam/dhparam.pem"
        log_success "DH parameters generated"
    else
        log_info "DH parameters already exist"
    fi
}

# 准备Let's Encrypt证书（生产环境）
prepare_letsencrypt() {
    log_info "Preparing for Let's Encrypt certificate..."
    
    # 创建ACME挑战目录
    mkdir -p "${SSL_DIR}/acme-challenge"
    
    # 生成certbot配置
    cat > "${SSL_DIR}/certbot.ini" << EOF
# Certbot配置文件
rsa-key-size = 4096
email = admin@${DOMAIN}
agree-tos = true
non-interactive = true
webroot-path = /usr/share/nginx/html

# 安全选项
must-staple = true
redirect = true
staple-ocsp = true
hsts = true
uir = true

# 更新选项
keep-until-expiring = true
expand = true
EOF
    
    # 生成certbot脚本
    cat > "${SSL_DIR}/get-letsencrypt.sh" << 'SCRIPT'
#!/bin/bash

# Let's Encrypt证书获取脚本
DOMAIN="$1"
EMAIL="$2"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: $0 <domain> <email>"
    exit 1
fi

# 使用certbot获取证书
docker run --rm \
    -v ./security/ssl/certs:/etc/letsencrypt \
    -v ./security/ssl/acme-challenge:/usr/share/nginx/html/.well-known/acme-challenge \
    certbot/certbot:latest \
    certonly \
    --webroot \
    --webroot-path=/usr/share/nginx/html \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN"

echo "Certificate obtained for $DOMAIN"
SCRIPT
    
    chmod +x "${SSL_DIR}/get-letsencrypt.sh"
    
    log_success "Let's Encrypt preparation complete"
    log_info "To obtain certificate, run: ${SSL_DIR}/get-letsencrypt.sh ${DOMAIN} admin@${DOMAIN}"
}

# 生成Nginx SSL配置
generate_nginx_ssl_config() {
    log_info "Generating Nginx SSL configuration..."
    
    cat > "${SSL_DIR}/nginx-ssl.conf" << EOF
# SSL/TLS配置
# 基于Mozilla SSL配置生成器 - 现代配置

# SSL证书
ssl_certificate /etc/nginx/ssl/certs/${DOMAIN}.pem;
ssl_certificate_key /etc/nginx/ssl/private/${DOMAIN}.key;

# SSL会话
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

# DH参数
ssl_dhparam /etc/nginx/ssl/dhparam/dhparam.pem;

# 现代SSL协议（仅TLS 1.2和1.3）
ssl_protocols TLSv1.2 TLSv1.3;

# 加密套件（现代配置）
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

# 优先使用服务器的加密套件
ssl_prefer_server_ciphers off;

# OCSP装订
ssl_stapling on;
ssl_stapling_verify on;

# 验证链
ssl_trusted_certificate /etc/nginx/ssl/certs/${DOMAIN}.pem;

# DNS解析器
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# HSTS（HTTP严格传输安全）
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# SSL早期数据（0-RTT）
ssl_early_data on;

# 代理SSL验证
proxy_ssl_verify on;
proxy_ssl_verify_depth 2;
proxy_ssl_session_reuse on;
EOF
    
    log_success "Nginx SSL configuration generated"
}

# 验证证书
verify_certificate() {
    log_info "Verifying certificate..."
    
    # 检查证书信息
    openssl x509 -in "${SSL_DIR}/certs/${DOMAIN}.crt" -text -noout | head -20
    
    # 验证证书链
    openssl verify -CAfile "${SSL_DIR}/certs/${DOMAIN}.crt" "${SSL_DIR}/certs/${DOMAIN}.crt"
    
    log_success "Certificate verification complete"
}

# 生成证书更新脚本
generate_renewal_script() {
    log_info "Generating certificate renewal script..."
    
    cat > "${SSL_DIR}/renew-cert.sh" << 'EOF'
#!/bin/bash

# 证书自动更新脚本
set -euo pipefail

# 日志文件
LOG_FILE="/var/log/cert-renewal.log"

# 记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查证书过期时间
check_expiry() {
    local cert_file="$1"
    local days_left=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2 | xargs -I {} date -d {} +%s | awk -v now=$(date +%s) '{print int(($1-now)/86400)}')
    echo "$days_left"
}

# 更新证书
renew_certificate() {
    log "Starting certificate renewal..."
    
    # 运行certbot更新
    certbot renew --quiet --no-self-upgrade
    
    # 重新加载Nginx
    nginx -s reload
    
    log "Certificate renewal complete"
}

# 主函数
main() {
    local cert_file="/etc/nginx/ssl/certs/fullchain.pem"
    
    if [ -f "$cert_file" ]; then
        local days_left=$(check_expiry "$cert_file")
        log "Certificate expires in $days_left days"
        
        # 如果少于30天则更新
        if [ "$days_left" -lt 30 ]; then
            log "Certificate expiring soon, renewing..."
            renew_certificate
        else
            log "Certificate still valid, skipping renewal"
        fi
    else
        log "Certificate not found, obtaining new certificate..."
        renew_certificate
    fi
}

main
EOF
    
    chmod +x "${SSL_DIR}/renew-cert.sh"
    
    # 创建cron任务配置
    cat > "${SSL_DIR}/cert-renewal.cron" << EOF
# 证书自动更新cron任务
# 每天凌晨2点检查并更新证书
0 2 * * * /security/ssl/renew-cert.sh >> /var/log/cert-renewal.log 2>&1
EOF
    
    log_success "Renewal script generated"
}

# 主函数
main() {
    log_info "SSL/TLS Certificate Generation"
    log_info "Domain: ${DOMAIN}"
    log_info "Environment: ${ENVIRONMENT}"
    echo ""
    
    if [ "${ENVIRONMENT}" = "production" ] || [ "${ENVIRONMENT}" = "prod" ]; then
        log_info "Production environment detected"
        prepare_letsencrypt
        generate_dhparam
    else
        log_info "Development environment detected"
        generate_self_signed
        generate_dhparam
        verify_certificate
    fi
    
    # 生成Nginx配置
    generate_nginx_ssl_config
    
    # 生成更新脚本
    generate_renewal_script
    
    log_success "SSL/TLS setup complete!"
    echo ""
    echo "Files generated:"
    echo "  - Certificate: ${SSL_DIR}/certs/${DOMAIN}.crt"
    echo "  - Private Key: ${SSL_DIR}/private/${DOMAIN}.key"
    echo "  - DH Parameters: ${SSL_DIR}/dhparam/dhparam.pem"
    echo "  - Nginx Config: ${SSL_DIR}/nginx-ssl.conf"
    echo ""
    
    if [ "${ENVIRONMENT}" != "production" ]; then
        log_warning "Self-signed certificate generated. Browser will show security warning."
        log_info "For production, use: $0 ${DOMAIN} production"
    fi
}

# 运行主函数
main