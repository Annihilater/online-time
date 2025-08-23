#!/bin/bash

# =================================
# 在线时间工具 - 数据备份脚本
# =================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 配置文件
CONFIG_FILE=".env.prod"
LOG_FILE="logs/backup.log"
BACKUP_DIR="data/backups"

# 函数：打印彩色消息
print_msg() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] $message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

print_success() { print_msg "$GREEN" "✅ $1"; }
print_error() { print_msg "$RED" "❌ $1"; }
print_warning() { print_msg "$YELLOW" "⚠️  $1"; }
print_info() { print_msg "$BLUE" "ℹ️  $1"; }
print_step() { print_msg "$PURPLE" "🔄 $1"; }

# 函数：显示帮助信息
show_help() {
    cat << EOF
在线时间工具 - 数据备份脚本

用法: $0 [选项]

选项:
  -h, --help           显示帮助信息
  -c, --config FILE    指定配置文件 (默认: .env.prod)
  -t, --type TYPE      备份类型: full(完整) | data(仅数据) | config(仅配置)
  -n, --name NAME      备份名称前缀
  --compress          压缩备份文件
  --encrypt           加密备份文件
  --remote            上传到远程存储
  --restore FILE      从备份文件恢复
  --list              列出所有备份
  --clean             清理旧备份

示例:
  $0                   # 完整备份
  $0 -t data          # 仅备份数据
  $0 --compress       # 压缩备份
  $0 --list           # 列出备份
  $0 --restore backup-20231201-120000.tar.gz

EOF
}

# 函数：解析命令行参数
parse_args() {
    BACKUP_TYPE="full"
    BACKUP_NAME=""
    COMPRESS=false
    ENCRYPT=false
    REMOTE=false
    RESTORE_FILE=""
    LIST=false
    CLEAN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--type)
                BACKUP_TYPE="$2"
                shift 2
                ;;
            -n|--name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            --compress)
                COMPRESS=true
                shift
                ;;
            --encrypt)
                ENCRYPT=true
                shift
                ;;
            --remote)
                REMOTE=true
                shift
                ;;
            --restore)
                RESTORE_FILE="$2"
                shift 2
                ;;
            --list)
                LIST=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 函数：加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        set -a
        source "$CONFIG_FILE"
        set +a
        print_success "配置文件加载成功: $CONFIG_FILE"
    else
        print_warning "配置文件不存在: $CONFIG_FILE"
    fi
    
    # 创建必要目录
    mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR"
}

# 函数：生成备份名称
generate_backup_name() {
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local prefix="${BACKUP_NAME:-backup}"
    
    BACKUP_NAME="${prefix}-${timestamp}"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    print_info "备份名称: $BACKUP_NAME"
}

# 函数：创建完整备份
create_full_backup() {
    print_step "创建完整备份..."
    
    mkdir -p "$BACKUP_PATH"
    
    # 备份数据目录
    if [[ -d "data" ]]; then
        print_info "备份数据目录..."
        cp -r data/* "$BACKUP_PATH/" 2>/dev/null || true
    fi
    
    # 备份配置文件
    print_info "备份配置文件..."
    cp "$CONFIG_FILE" "$BACKUP_PATH/config.env" 2>/dev/null || true
    cp docker-compose*.yml "$BACKUP_PATH/" 2>/dev/null || true
    cp -r config "$BACKUP_PATH/" 2>/dev/null || true
    
    # 备份容器信息
    print_info "备份容器信息..."
    docker-compose ps > "$BACKUP_PATH/containers.txt" 2>/dev/null || true
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}" > "$BACKUP_PATH/images.txt" 2>/dev/null || true
    docker volume ls > "$BACKUP_PATH/volumes.txt" 2>/dev/null || true
    
    # 创建备份元数据
    cat > "$BACKUP_PATH/metadata.json" << EOF
{
  "backup_name": "$BACKUP_NAME",
  "backup_type": "full",
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "docker_version": "$(docker --version 2>/dev/null || echo 'N/A')",
  "compose_version": "$(docker-compose --version 2>/dev/null || echo 'N/A')",
  "config_file": "$CONFIG_FILE"
}
EOF
    
    print_success "完整备份创建完成"
}

# 函数：创建数据备份
create_data_backup() {
    print_step "创建数据备份..."
    
    mkdir -p "$BACKUP_PATH"
    
    # 备份Redis数据
    if docker-compose ps | grep -q redis; then
        print_info "备份Redis数据..."
        docker-compose exec -T redis redis-cli BGSAVE || true
        sleep 2
        docker cp online-time-redis:/data/dump.rdb "$BACKUP_PATH/redis-dump.rdb" 2>/dev/null || true
    fi
    
    # 备份应用数据
    if [[ -d "data" ]]; then
        print_info "备份应用数据..."
        rsync -av data/ "$BACKUP_PATH/data/" --exclude="backups" 2>/dev/null || cp -r data/* "$BACKUP_PATH/" 2>/dev/null || true
    fi
    
    # 备份日志文件
    if [[ -d "logs" ]]; then
        print_info "备份日志文件..."
        find logs -name "*.log" -mtime -7 -exec cp {} "$BACKUP_PATH/" \; 2>/dev/null || true
    fi
    
    print_success "数据备份创建完成"
}

# 函数：创建配置备份
create_config_backup() {
    print_step "创建配置备份..."
    
    mkdir -p "$BACKUP_PATH"
    
    # 备份所有配置文件
    local config_files=("$CONFIG_FILE" "docker-compose*.yml")
    
    for pattern in "${config_files[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                cp "$file" "$BACKUP_PATH/"
                print_info "备份配置文件: $file"
            fi
        done
    done
    
    # 备份nginx配置
    if [[ -d "config" ]]; then
        cp -r config "$BACKUP_PATH/"
        print_info "备份nginx配置目录"
    fi
    
    print_success "配置备份创建完成"
}

# 函数：压缩备份
compress_backup() {
    if [[ "$COMPRESS" == "true" ]]; then
        print_step "压缩备份文件..."
        
        local compressed_file="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
        
        cd "$BACKUP_DIR"
        tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
        
        if [[ $? -eq 0 ]]; then
            rm -rf "$BACKUP_NAME"
            BACKUP_PATH="$compressed_file"
            print_success "备份压缩完成: $BACKUP_NAME.tar.gz"
        else
            print_error "备份压缩失败"
            return 1
        fi
        
        cd "$SCRIPT_DIR"
    fi
}

# 函数：加密备份
encrypt_backup() {
    if [[ "$ENCRYPT" == "true" ]]; then
        print_step "加密备份文件..."
        
        if ! command -v gpg &> /dev/null; then
            print_error "GPG未安装，无法加密备份"
            return 1
        fi
        
        local backup_file="$BACKUP_PATH"
        local encrypted_file="${backup_file}.gpg"
        
        # 使用对称加密
        read -s -p "请输入加密密码: " password
        echo
        
        echo "$password" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$encrypted_file" "$backup_file"
        
        if [[ $? -eq 0 ]]; then
            rm -f "$backup_file"
            BACKUP_PATH="$encrypted_file"
            print_success "备份加密完成"
        else
            print_error "备份加密失败"
            return 1
        fi
    fi
}

# 函数：上传到远程存储
upload_remote() {
    if [[ "$REMOTE" == "true" ]]; then
        print_step "上传备份到远程存储..."
        
        # 这里可以根据需要配置不同的远程存储
        # 例如：AWS S3, Google Cloud Storage, FTP等
        
        print_warning "远程存储功能需要配置，当前跳过"
        print_info "请在脚本中配置您的远程存储设置"
        
        # 示例：上传到S3
        # if command -v aws &> /dev/null; then
        #     aws s3 cp "$BACKUP_PATH" "s3://your-backup-bucket/online-time/"
        #     print_success "备份上传到S3完成"
        # fi
    fi
}

# 函数：列出所有备份
list_backups() {
    if [[ "$LIST" == "true" ]]; then
        print_step "备份列表"
        
        echo "
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            📋 备份列表                                        ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"
        
        if [[ ! -d "$BACKUP_DIR" || -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
            print_info "没有找到备份文件"
            return 0
        fi
        
        # 显示备份文件
        printf "%-30s %-15s %-20s\n" "备份名称" "大小" "创建时间"
        echo "────────────────────────────────────────────────────────────────────"
        
        for backup in "$BACKUP_DIR"/*; do
            if [[ -e "$backup" ]]; then
                local name=$(basename "$backup")
                local size=$(du -sh "$backup" 2>/dev/null | cut -f1 || echo "N/A")
                local mtime=$(stat -c %y "$backup" 2>/dev/null | cut -d. -f1 || echo "N/A")
                
                printf "%-30s %-15s %-20s\n" "$name" "$size" "$mtime"
            fi
        done
        
        echo "
📍 备份目录: $BACKUP_DIR
💡 使用 --restore 选项可恢复备份
"
        return 0
    fi
}

# 函数：清理旧备份
clean_old_backups() {
    if [[ "$CLEAN" == "true" ]]; then
        print_step "清理旧备份..."
        
        local retention_days="${BACKUP_RETENTION_DAYS:-7}"
        
        print_info "清理 $retention_days 天前的备份文件..."
        
        find "$BACKUP_DIR" -type f -mtime +$retention_days -name "backup-*" -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type d -mtime +$retention_days -name "backup-*" -exec rm -rf {} + 2>/dev/null || true
        
        print_success "旧备份清理完成"
    fi
}

# 函数：从备份恢复
restore_from_backup() {
    if [[ -n "$RESTORE_FILE" ]]; then
        print_step "从备份恢复: $RESTORE_FILE"
        
        local restore_path="$BACKUP_DIR/$RESTORE_FILE"
        
        if [[ ! -f "$restore_path" ]]; then
            print_error "备份文件不存在: $restore_path"
            return 1
        fi
        
        print_warning "即将从备份恢复，这将覆盖当前数据"
        read -p "确认继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "恢复操作已取消"
            return 0
        fi
        
        # 先停止服务
        print_info "停止当前服务..."
        ./stop.sh || true
        
        # 创建临时恢复目录
        local temp_dir="/tmp/online-time-restore-$$"
        mkdir -p "$temp_dir"
        
        # 解压备份文件
        if [[ "$restore_path" == *.tar.gz ]]; then
            tar -xzf "$restore_path" -C "$temp_dir"
        elif [[ "$restore_path" == *.gpg ]]; then
            print_info "请输入解密密码:"
            gpg --decrypt "$restore_path" | tar -xz -C "$temp_dir"
        else
            cp -r "$restore_path"/* "$temp_dir/"
        fi
        
        # 恢复数据
        if [[ -d "$temp_dir" ]]; then
            print_info "恢复数据文件..."
            
            # 备份当前数据 (以防万一)
            if [[ -d "data" ]]; then
                mv data "data.backup.$(date +%s)" || true
            fi
            
            # 恢复数据
            mkdir -p data
            cp -r "$temp_dir"/* data/ 2>/dev/null || true
            
            # 恢复配置文件
            if [[ -f "$temp_dir/config.env" ]]; then
                cp "$temp_dir/config.env" "$CONFIG_FILE"
                print_info "配置文件已恢复"
            fi
            
            print_success "数据恢复完成"
        fi
        
        # 清理临时目录
        rm -rf "$temp_dir"
        
        # 重新启动服务
        print_info "重新启动服务..."
        ./deploy.sh --force
        
        print_success "恢复操作完成"
        return 0
    fi
}

# 主函数
main() {
    print_step "在线时间工具 - 数据备份"
    
    parse_args "$@"
    load_config
    
    # 特殊操作
    if list_backups; then return 0; fi
    if restore_from_backup; then return 0; fi
    if clean_old_backups; then return 0; fi
    
    # 正常备份流程
    generate_backup_name
    
    case "$BACKUP_TYPE" in
        full)
            create_full_backup
            ;;
        data)
            create_data_backup
            ;;
        config)
            create_config_backup
            ;;
        *)
            print_error "未知备份类型: $BACKUP_TYPE"
            exit 1
            ;;
    esac
    
    compress_backup
    encrypt_backup
    upload_remote
    
    # 显示备份结果
    echo "
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            ✅ 备份创建成功！                                   ║
╚═══════════════════════════════════════════════════════════════════════════════╝

📋 备份详情:
   备份名称: $BACKUP_NAME
   备份类型: $BACKUP_TYPE
   备份位置: $BACKUP_PATH
   文件大小: $(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1 || echo 'N/A')

💡 使用方法:
   恢复备份: $0 --restore $(basename "$BACKUP_PATH")
   列出备份: $0 --list
   清理备份: $0 --clean
"
    
    print_success "🎉 备份操作完成！"
}

# 执行主函数
main "$@"