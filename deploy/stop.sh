#!/bin/bash

# =================================
# 在线时间工具 - 服务停止脚本
# =================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "在线时间工具 - 服务停止脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -v, --verbose    详细输出"
    echo "  -f, --force      强制停止 (docker-compose down)"
    echo "  --remove-volumes 停止时删除数据卷"
    echo "  --remove-images  停止时删除镜像"
    echo "  --cleanup        清理孤儿容器和未使用的网络"
    echo
    echo "示例:"
    echo "  $0               # 优雅停止服务"
    echo "  $0 --force       # 强制停止服务"
    echo "  $0 --cleanup     # 停止服务并清理"
}

# 检查Docker服务
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker服务未运行"
        exit 1
    fi
}

# 检查运行中的服务
check_running_services() {
    log "检查运行中的服务..."
    
    local ha_running=false
    local basic_running=false
    local services_found=false
    
    # 检查高可用模式
    if docker-compose -f "docker-compose.ha.yml" ps -q 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}发现高可用模式服务:${NC}"
        docker-compose -f "docker-compose.ha.yml" ps
        ha_running=true
        services_found=true
    fi
    
    # 检查基础/完整模式
    if docker-compose -f "docker-compose.prod.yml" ps -q 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}发现基础/完整模式服务:${NC}"
        docker-compose -f "docker-compose.prod.yml" ps
        basic_running=true
        services_found=true
    fi
    
    if [[ "$services_found" == "false" ]]; then
        warn "没有检测到运行中的服务"
        exit 0
    fi
    
    echo "ha_running=$ha_running basic_running=$basic_running"
}

# 优雅停止服务
graceful_stop() {
    local verbose="$1"
    local compose_args=""
    
    if [[ "$verbose" == "true" ]]; then
        compose_args="--verbose"
    fi
    
    log "开始优雅停止服务..."
    
    # 检查运行中的服务
    local result
    result=$(check_running_services)
    local ha_running=$(echo "$result" | grep "ha_running=" | cut -d'=' -f2)
    local basic_running=$(echo "$result" | grep "basic_running=" | cut -d'=' -f2)
    
    # 停止高可用模式服务
    if [[ "$ha_running" == "true" ]]; then
        log "停止高可用模式服务..."
        if docker-compose -f "docker-compose.ha.yml" stop $compose_args; then
            success "高可用模式服务已停止"
        else
            error "高可用模式服务停止失败"
        fi
    fi
    
    # 停止基础/完整模式服务
    if [[ "$basic_running" == "true" ]]; then
        log "停止基础/完整模式服务..."
        if docker-compose -f "docker-compose.prod.yml" stop $compose_args; then
            success "基础/完整模式服务已停止"
        else
            error "基础/完整模式服务停止失败"
        fi
    fi
}

# 强制停止服务
force_stop() {
    local verbose="$1"
    local remove_volumes="$2"
    local remove_images="$3"
    
    local compose_args=""
    
    if [[ "$verbose" == "true" ]]; then
        compose_args="--verbose"
    fi
    
    if [[ "$remove_volumes" == "true" ]]; then
        compose_args="$compose_args --volumes"
    fi
    
    if [[ "$remove_images" == "true" ]]; then
        compose_args="$compose_args --rmi all"
    fi
    
    log "开始强制停止服务..."
    
    # 强制停止高可用模式服务
    if docker-compose -f "docker-compose.ha.yml" ps -q 2>/dev/null | grep -q .; then
        log "强制停止高可用模式服务..."
        if docker-compose -f "docker-compose.ha.yml" down $compose_args; then
            success "高可用模式服务已强制停止"
        else
            warn "高可用模式服务强制停止时出现问题"
        fi
    fi
    
    # 强制停止基础/完整模式服务
    if docker-compose -f "docker-compose.prod.yml" ps -q 2>/dev/null | grep -q .; then
        log "强制停止基础/完整模式服务..."
        if docker-compose -f "docker-compose.prod.yml" down $compose_args; then
            success "基础/完整模式服务已强制停止"
        else
            warn "基础/完整模式服务强制停止时出现问题"
        fi
    fi
}

# 清理资源
cleanup_resources() {
    log "清理Docker资源..."
    
    # 清理孤儿容器
    log "清理孤儿容器..."
    if docker container prune -f; then
        success "孤儿容器清理完成"
    fi
    
    # 清理未使用的网络
    log "清理未使用的网络..."
    if docker network prune -f; then
        success "未使用网络清理完成"
    fi
    
    # 清理未使用的卷（谨慎操作）
    read -p "是否清理未使用的数据卷? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "清理未使用的数据卷..."
        docker volume prune -f
        success "未使用数据卷清理完成"
    fi
}

# 显示停止后状态
show_final_status() {
    log "检查停止后状态..."
    
    echo -e "${GREEN}容器状态:${NC}"
    if docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(online-time|nginx|redis|prometheus|grafana)" || true; then
        echo "相关容器已列出"
    else
        echo "没有发现相关容器在运行"
    fi
    
    echo
    echo -e "${GREEN}网络状态:${NC}"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -E "(deploy|online-time)" || echo "没有发现相关网络"
    
    echo
    success "========== 服务停止完成 =========="
    echo -e "所有在线时间工具相关服务已停止"
    echo
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  启动服务: ./start.sh [模式]"
    echo "  重启服务: ./restart.sh [模式]"
    echo "  更新镜像: ./pull.sh"
    echo
}

# 主函数
main() {
    local verbose="false"
    local force="false"
    local remove_volumes="false"
    local remove_images="false"
    local cleanup="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            --remove-volumes)
                remove_volumes="true"
                shift
                ;;
            --remove-images)
                remove_images="true"
                shift
                ;;
            --cleanup)
                cleanup="true"
                shift
                ;;
            *)
                error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log "=== 在线时间工具 - 服务停止 ==="
    
    # 检查Docker
    check_docker
    
    # 确认操作
    if [[ "$force" == "true" ]] || [[ "$remove_volumes" == "true" ]] || [[ "$remove_images" == "true" ]]; then
        warn "您选择了强制停止或删除选项"
        if [[ "$remove_volumes" == "true" ]]; then
            warn "注意: --remove-volumes 将删除数据卷，数据将丢失!"
        fi
        if [[ "$remove_images" == "true" ]]; then
            warn "注意: --remove-images 将删除镜像，需要重新拉取!"
        fi
        echo
        read -p "确认要继续吗? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "操作已取消"
            exit 0
        fi
    fi
    
    # 执行停止操作
    if [[ "$force" == "true" ]]; then
        force_stop "$verbose" "$remove_volumes" "$remove_images"
    else
        graceful_stop "$verbose"
    fi
    
    # 清理资源
    if [[ "$cleanup" == "true" ]]; then
        cleanup_resources
    fi
    
    # 显示最终状态
    show_final_status
    
    success "停止脚本执行完成"
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi