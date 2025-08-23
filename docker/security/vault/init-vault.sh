#!/bin/bash

# Vault初始化和配置脚本
# 用于设置Vault并存储应用程序密钥

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vault配置
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN_FILE="./security/vault/.vault-token"
VAULT_KEYS_FILE="./security/vault/.vault-keys"

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

# 等待Vault启动
wait_for_vault() {
    log_info "Waiting for Vault to start..."
    
    for i in {1..30}; do
        if curl -s "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
            log_success "Vault is running"
            return 0
        fi
        sleep 2
    done
    
    log_error "Vault failed to start"
    return 1
}

# 初始化Vault
init_vault() {
    log_info "Initializing Vault..."
    
    # 检查是否已初始化
    if vault operator init -status 2>/dev/null; then
        log_info "Vault already initialized"
        return 0
    fi
    
    # 初始化Vault
    vault operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -format=json > "${VAULT_KEYS_FILE}"
    
    # 提取root token
    ROOT_TOKEN=$(jq -r '.root_token' "${VAULT_KEYS_FILE}")
    echo "${ROOT_TOKEN}" > "${VAULT_TOKEN_FILE}"
    
    # 设置权限
    chmod 600 "${VAULT_KEYS_FILE}" "${VAULT_TOKEN_FILE}"
    
    log_success "Vault initialized successfully"
    log_warning "IMPORTANT: Backup ${VAULT_KEYS_FILE} and ${VAULT_TOKEN_FILE} securely!"
}

# 解封Vault
unseal_vault() {
    log_info "Unsealing Vault..."
    
    # 检查封印状态
    if ! vault status 2>/dev/null | grep -q "Sealed.*true"; then
        log_info "Vault already unsealed"
        return 0
    fi
    
    # 读取解封密钥
    if [ ! -f "${VAULT_KEYS_FILE}" ]; then
        log_error "Unseal keys not found"
        return 1
    fi
    
    # 使用前3个密钥解封
    for i in 0 1 2; do
        KEY=$(jq -r ".unseal_keys_b64[$i]" "${VAULT_KEYS_FILE}")
        vault operator unseal "${KEY}" > /dev/null
    done
    
    log_success "Vault unsealed successfully"
}

# 登录Vault
login_vault() {
    log_info "Logging into Vault..."
    
    if [ ! -f "${VAULT_TOKEN_FILE}" ]; then
        log_error "Root token not found"
        return 1
    fi
    
    export VAULT_TOKEN=$(cat "${VAULT_TOKEN_FILE}")
    vault login "${VAULT_TOKEN}" > /dev/null
    
    log_success "Logged into Vault"
}

# 配置密钥引擎
setup_secrets_engine() {
    log_info "Setting up secrets engine..."
    
    # 启用KV v2密钥引擎
    vault secrets enable -path=online-time kv-v2 2>/dev/null || \
        log_info "Secrets engine already enabled"
    
    # 配置密钥引擎
    vault kv metadata put online-time/config \
        max_versions=10 \
        cas_required=false \
        delete_version_after="0s"
    
    log_success "Secrets engine configured"
}

# 存储应用程序密钥
store_app_secrets() {
    log_info "Storing application secrets..."
    
    # 存储数据库配置（示例）
    vault kv put online-time/database \
        username="app_user" \
        password="$(openssl rand -base64 32)" \
        host="localhost" \
        port="5432" \
        database="online_time"
    
    # 存储API密钥
    vault kv put online-time/api \
        jwt_secret="$(openssl rand -base64 64)" \
        api_key="$(uuidgen)" \
        encryption_key="$(openssl rand -hex 32)"
    
    # 存储SSL配置
    vault kv put online-time/ssl \
        cert_path="/etc/nginx/ssl/certs/cert.pem" \
        key_path="/etc/nginx/ssl/private/key.pem" \
        dhparam_path="/etc/nginx/ssl/dhparam/dhparam.pem"
    
    # 存储监控配置
    vault kv put online-time/monitoring \
        prometheus_token="$(openssl rand -base64 32)" \
        grafana_admin_password="$(openssl rand -base64 16)" \
        alertmanager_webhook="https://hooks.slack.com/services/XXX/YYY/ZZZ"
    
    log_success "Application secrets stored"
}

# 创建应用程序策略
create_app_policy() {
    log_info "Creating application policy..."
    
    cat > /tmp/app-policy.hcl << 'EOF'
# 应用程序只读策略
path "online-time/data/*" {
  capabilities = ["read", "list"]
}

# 健康检查
path "sys/health" {
  capabilities = ["read"]
}

# 续订token
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF
    
    # 创建策略
    vault policy write online-time-read /tmp/app-policy.hcl
    
    # 清理临时文件
    rm -f /tmp/app-policy.hcl
    
    log_success "Application policy created"
}

# 创建应用程序令牌
create_app_token() {
    log_info "Creating application token..."
    
    # 创建受限令牌
    APP_TOKEN=$(vault token create \
        -policy=online-time-read \
        -ttl=720h \
        -renewable \
        -format=json | jq -r '.auth.client_token')
    
    # 保存应用令牌
    echo "${APP_TOKEN}" > ./security/vault/.app-token
    chmod 600 ./security/vault/.app-token
    
    log_success "Application token created"
    log_info "Token saved to: ./security/vault/.app-token"
}

# 配置审计
setup_audit() {
    log_info "Setting up audit logging..."
    
    # 启用文件审计设备
    vault audit enable file \
        file_path=/vault/logs/audit.log \
        log_raw=false \
        hmac_accessor=true \
        mode=0600 \
        format=json 2>/dev/null || \
        log_info "Audit already enabled"
    
    log_success "Audit logging configured"
}

# 创建备份脚本
create_backup_script() {
    log_info "Creating backup script..."
    
    cat > ./security/vault/backup-vault.sh << 'EOF'
#!/bin/bash

# Vault备份脚本
set -euo pipefail

BACKUP_DIR="./security/vault/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/vault-backup-${TIMESTAMP}.tar.gz"

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

# 备份Vault数据
tar -czf "${BACKUP_FILE}" \
    ./security/vault/.vault-keys \
    ./security/vault/.vault-token \
    ./security/vault/.app-token \
    ./data/vault

echo "Backup created: ${BACKUP_FILE}"

# 保留最近10个备份
ls -t "${BACKUP_DIR}"/vault-backup-*.tar.gz | tail -n +11 | xargs -r rm

echo "Backup complete"
EOF
    
    chmod +x ./security/vault/backup-vault.sh
    
    log_success "Backup script created"
}

# 显示密钥信息
show_secrets_info() {
    log_info "Retrieving stored secrets..."
    
    echo ""
    echo "==================================="
    echo "Stored Secrets Overview"
    echo "==================================="
    
    # 列出所有密钥
    vault kv list online-time/
    
    # 显示示例：如何获取密钥
    echo ""
    echo "To retrieve a secret:"
    echo "  vault kv get online-time/database"
    echo "  vault kv get -format=json online-time/api | jq -r '.data.data.jwt_secret'"
    echo ""
    echo "==================================="
}

# 主函数
main() {
    log_info "Starting Vault setup..."
    
    # 等待Vault启动
    wait_for_vault
    
    # 初始化Vault
    init_vault
    
    # 解封Vault
    unseal_vault
    
    # 登录Vault
    login_vault
    
    # 配置密钥引擎
    setup_secrets_engine
    
    # 存储应用密钥
    store_app_secrets
    
    # 创建策略
    create_app_policy
    
    # 创建应用令牌
    create_app_token
    
    # 配置审计
    setup_audit
    
    # 创建备份脚本
    create_backup_script
    
    # 显示信息
    show_secrets_info
    
    log_success "Vault setup complete!"
    echo ""
    log_warning "Important files created:"
    echo "  - Unseal keys: ${VAULT_KEYS_FILE}"
    echo "  - Root token: ${VAULT_TOKEN_FILE}"
    echo "  - App token: ./security/vault/.app-token"
    echo ""
    log_error "SECURE THESE FILES IMMEDIATELY!"
}

# 运行主函数
main "$@"