#!/bin/bash

# =================================
# 在线时间工具 - 服务更新脚本
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
LOG_FILE="logs/update.log"
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
在线时间工具 - 服务更新脚本

用法: $0 [选项]

选项:
  -h, --help           显示帮助信息
  -c, --config FILE    指定配置文件 (默认: .env.prod)
  -t, --tag TAG        指定镜像标签 (默认: latest)
  --backup            更新前创建备份
  --rollback          回滚到上一个版本
  --force             强制更新 (跳过确认)
  --dry-run           只检查不执行
  --no-downtime       零宕机时间更新 (仅HA模式)

示例:
  $0                   # 标准更新
  $0 --backup         # 更新前备份
  $0 -t v1.2.0        # 更新到指定版本
  $0 --rollback       # 回滚操作

EOF
}

# 函数：解析命令行参数
parse_args() {
    IMAGE_TAG="latest"
    BACKUP=false
    ROLLBACK=false
    FORCE=false
    DRY_RUN=false
    NO_DOWNTIME=false
    
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
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --backup)
                BACKUP=true
                shift
                ;;
            --rollback)
                ROLLBACK=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-downtime)
                NO_DOWNTIME=true
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
        print_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    # 创建必要目录
    mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR"
}

# 函数：确认更新操作
confirm_update() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    print_warning "即将更新到镜像版本: $IMAGE_TAG"
    read -p "确认继续更新? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "更新操作已取消"
        exit 0
    fi
}

# 函数：检查当前状态
check_current_status() {
    print_step "检查当前服务状态..."
    
    # 检查服务是否运行
    if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        print_warning "服务似乎没有运行，建议先部署"
        if [[ "$FORCE" != "true" ]]; then
            read -p "是否继续? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # 显示当前镜像信息
    print_info "当前镜像信息:"
    docker images --filter "reference=${DOCKER_IMAGE}" --format "table {{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" || true
}

# 函数：创建备份
create_backup() {
    if [[ "$BACKUP" == "true" ]]; then
        print_step "创建更新前备份..."
        
        local backup_name="backup-$(date '+%Y%m%d-%H%M%S')"
        local backup_path="$BACKUP_DIR/$backup_name"
        
        mkdir -p "$backup_path"
        
        # 备份数据目录
        if [[ -d "data" ]]; then
            cp -r data/* "$backup_path/" 2>/dev/null || true
            print_success "数据备份完成: $backup_path"
        fi
        
        # 备份配置文件
        cp "$CONFIG_FILE" "$backup_path/config.env"
        
        # 备份当前镜像信息
        docker images --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" > "$backup_path/images.txt"
        
        # 记录备份信息
        echo "$backup_name" > "$BACKUP_DIR/latest_backup"
        
        print_success "备份创建完成: $backup_name"
    fi
}

# 函数：拉取新镜像
pull_new_image() {
    print_step "拉取新镜像..."
    
    local new_image="${DOCKER_IMAGE}:${IMAGE_TAG}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN - 将拉取镜像: $new_image"
        return 0
    fi
    
    # 拉取新镜像
    if docker pull "$new_image"; then
        print_success "新镜像拉取成功: $new_image"
        
        # 更新配置文件中的镜像标签
        if [[ "$IMAGE_TAG" != "latest" ]]; then
            sed -i.bak "s|^DOCKER_IMAGE=.*|DOCKER_IMAGE=$new_image|" "$CONFIG_FILE"
            print_info "配置文件已更新"
        fi
    else
        print_error "镜像拉取失败: $new_image"
        return 1
    fi
}

# 函数：零宕机时间更新 (仅HA模式)
zero_downtime_update() {
    if [[ "$NO_DOWNTIME" == "true" ]]; then
        print_step "执行零宕机时间更新..."
        
        if [[ ! -f "docker-compose.ha.yml" ]]; then
            print_error "零宕机时间更新需要HA模式配置"
            return 1
        fi
        
        # 逐个更新应用实例
        for instance in app-1 app-2 app-3; do
            print_info "更新实例: $instance"
            
            # 停止单个实例
            docker-compose -f docker-compose.ha.yml stop "$instance"
            
            # 移除容器
            docker-compose -f docker-compose.ha.yml rm -f "$instance"
            
            # 启动新版本
            docker-compose -f docker-compose.ha.yml --env-file "$CONFIG_FILE" up -d "$instance"
            
            # 等待实例就绪
            sleep 10
            
            # 健康检查
            local max_attempts=12
            local attempt=1
            while [[ $attempt -le $max_attempts ]]; do
                if docker exec "$instance" curl -sf "http://localhost:3000/health" &> /dev/null; then
                    print_success "实例 $instance 更新完成"
                    break
                fi
                print_info "等待实例就绪... ($attempt/$max_attempts)"
                sleep 5
                ((attempt++))
            done
            
            if [[ $attempt -gt $max_attempts ]]; then
                print_error "实例 $instance 更新失败"
                return 1
            fi
        done
        
        print_success "零宕机时间更新完成"
        return 0
    fi
}

# 函数：标准更新
standard_update() {
    print_step "执行标准更新..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN - 将执行标准更新"
        return 0
    fi
    
    # 确定compose文件
    local compose_file="docker-compose.prod.yml"
    if [[ -f "docker-compose.ha.yml" && "$NO_DOWNTIME" != "true" ]]; then
        compose_file="docker-compose.ha.yml"
    fi
    
    # 重启服务
    docker-compose -f "$compose_file" --env-file "$CONFIG_FILE" up -d --force-recreate
    
    print_success "服务更新完成"
}

# 函数：执行回滚
perform_rollback() {
    if [[ "$ROLLBACK" == "true" ]]; then
        print_step "执行回滚操作..."
        
        if [[ ! -f "$BACKUP_DIR/latest_backup" ]]; then
            print_error "没有找到备份信息"
            return 1
        fi
        
        local latest_backup=$(cat "$BACKUP_DIR/latest_backup")
        local backup_path="$BACKUP_DIR/$latest_backup"
        
        if [[ ! -d "$backup_path" ]]; then
            print_error "备份目录不存在: $backup_path"
            return 1
        fi
        
        print_warning "即将回滚到备份: $latest_backup"
        if [[ "$FORCE" != "true" ]]; then
            read -p "确认回滚? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "回滚操作已取消"
                return 0
            fi
        fi
        
        # 恢复配置文件
        if [[ -f "$backup_path/config.env" ]]; then
            cp "$backup_path/config.env" "$CONFIG_FILE"
            print_success "配置文件已恢复"
        fi
        
        # 恢复数据
        if [[ -d "$backup_path" && -d "data" ]]; then
            cp -r "$backup_path"/* data/ 2>/dev/null || true
            print_success "数据已恢复"
        fi
        
        # 重新部署
        ./deploy.sh --force
        
        print_success "回滚完成"
        return 0
    fi
}

# 函数：健康检查
health_check() {
    print_step "执行更新后健康检查..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN - 跳过健康检查"
        return 0
    fi
    
    local max_attempts=20
    local attempt=1
    local http_port="${HTTP_PORT:-80}"
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "健康检查 ($attempt/$max_attempts)..."
        
        if curl -sf "http://localhost:$http_port/health" &> /dev/null; then
            print_success "更新后健康检查通过"
            return 0
        fi
        
        sleep 5
        ((attempt++))
    done
    
    print_error "更新后健康检查失败"
    print_warning "建议检查服务状态或考虑回滚"
    return 1
}

# 函数：显示更新结果
show_update_result() {
    print_step "更新结果"
    
    echo "
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            🎉 更新完成！                                      ║
╚═══════════════════════════════════════════════════════════════════════════════╝

📋 更新详情:
   目标版本: $IMAGE_TAG
   配置文件: $CONFIG_FILE
   更新方式: $([ "$NO_DOWNTIME" == "true" ] && echo "零宕机时间" || echo "标准更新")

📊 当前状态:
"
    
    # 显示容器状态
    docker-compose -f docker-compose.prod.yml ps 2>/dev/null || docker-compose -f docker-compose.ha.yml ps 2>/dev/null || true
    
    echo "
🌐 服务访问:
   主应用: http://localhost:${HTTP_PORT:-80}
   健康检查: http://localhost:${HTTP_PORT:-80}/health

📝 后续操作:
   查看日志: docker-compose logs -f
   检查状态: docker-compose ps
   如有问题: ./update.sh --rollback
"
}

# 主函数
main() {
    print_step "在线时间工具 - 服务更新"
    
    parse_args "$@"
    load_config
    
    # 如果是回滚操作，直接执行回滚
    if [[ "$ROLLBACK" == "true" ]]; then
        perform_rollback
        return 0
    fi
    
    # 正常更新流程
    check_current_status
    confirm_update
    create_backup
    pull_new_image
    
    # 根据模式选择更新方式
    if zero_downtime_update; then
        # 零宕机时间更新成功
        :
    else
        # 执行标准更新
        standard_update
    fi
    
    health_check
    show_update_result
    
    print_success "🎉 更新全部完成！"
}

# 执行主函数
main "$@"