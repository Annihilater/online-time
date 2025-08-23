#!/bin/bash

# =================================
# 在线时间工具 - 服务重启脚本
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
    echo "在线时间工具 - 服务重启脚本"
    echo
    echo "用法: $0 [模式] [选项]"
    echo
    echo "部署模式:"
    echo "  basic      基础模式 (默认) - 应用 + Nginx"
    echo "  full       完整模式 - 基础模式 + Redis"
    echo "  ha         高可用模式 - 多实例 + 负载均衡 + 监控"
    echo "  auto       自动检测当前模式并重启"
    echo
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -v, --verbose    详细输出"
    echo "  -f, --force      强制重启 (stop + start)"
    echo "  --pull           重启前拉取最新镜像"
    echo "  --logs           重启后显示日志"
    echo "  --quick          快速重启 (docker-compose restart)"
    echo
    echo "示例:"
    echo "  $0               # 自动检测当前模式并重启"
    echo "  $0 ha            # 重启为高可用模式"
    echo "  $0 --pull        # 拉取最新镜像并重启"
    echo "  $0 --quick       # 快速重启当前服务"
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

# 检测当前运行模式
detect_current_mode() {
    log "检测当前运行模式..."
    
    # 检查高可用模式
    if docker-compose -f "docker-compose.ha.yml" ps -q 2>/dev/null | grep -q .; then
        echo "ha"
        return 0
    fi
    
    # 检查基础/完整模式
    if docker-compose -f "docker-compose.prod.yml" ps -q 2>/dev/null | grep -q .; then
        # 检查是否有Redis服务来区分basic和full模式
        if docker-compose -f "docker-compose.prod.yml" ps redis 2>/dev/null | grep -q "Up"; then
            echo "full"
        else
            echo "basic"
        fi
        return 0
    fi
    
    # 没有检测到运行中的服务
    echo "none"
    return 1
}

# 快速重启服务
quick_restart() {
    local verbose="$1"
    local compose_args=""
    
    if [[ "$verbose" == "true" ]]; then
        compose_args="--verbose"
    fi
    
    log "执行快速重启..."
    
    local current_mode
    current_mode=$(detect_current_mode)
    
    if [[ "$current_mode" == "none" ]]; then
        warn "没有检测到运行中的服务，无法快速重启"
        echo "使用: $0 [模式] 来启动服务"
        exit 1
    fi
    
    local compose_file="docker-compose.prod.yml"
    if [[ "$current_mode" == "ha" ]]; then
        compose_file="docker-compose.ha.yml"
    fi
    
    log "快速重启 $current_mode 模式服务..."
    
    if docker-compose -f "$compose_file" restart $compose_args; then
        success "快速重启完成"
    else
        error "快速重启失败"
        exit 1
    fi
    
    # 等待服务就绪
    log "等待服务就绪..."
    sleep 5
    
    # 显示服务状态
    echo
    log "重启后服务状态:"
    docker-compose -f "$compose_file" ps
}

# 完整重启服务
full_restart() {
    local mode="$1"
    local verbose="$2"
    local force="$3"
    local pull="$4"
    local show_logs="$5"
    
    local stop_args=""
    local start_args=""
    
    if [[ "$verbose" == "true" ]]; then
        stop_args="--verbose"
        start_args="--verbose"
    fi
    
    if [[ "$force" == "true" ]]; then
        stop_args="$stop_args --force"
    fi
    
    if [[ "$show_logs" == "true" ]]; then
        start_args="$start_args --logs"
    fi
    
    log "执行完整重启 - 模式: $mode"
    
    # 如果是自动模式，检测当前模式
    if [[ "$mode" == "auto" ]]; then
        local current_mode
        current_mode=$(detect_current_mode)
        
        if [[ "$current_mode" == "none" ]]; then
            warn "没有检测到运行中的服务，使用基础模式启动"
            mode="basic"
        else
            log "检测到当前模式: $current_mode"
            mode="$current_mode"
        fi
    fi
    
    # 拉取最新镜像
    if [[ "$pull" == "true" ]]; then
        log "拉取最新镜像..."
        if ! "$SCRIPT_DIR/pull.sh"; then
            warn "镜像拉取失败，继续重启流程"
        else
            success "镜像拉取完成"
        fi
    fi
    
    # 停止服务
    log "停止当前服务..."
    if ! "$SCRIPT_DIR/stop.sh" $stop_args; then
        warn "停止服务时出现问题，继续启动流程"
    else
        success "服务停止完成"
    fi
    
    # 等待一下确保服务完全停止
    sleep 2
    
    # 启动服务
    log "启动服务 - 模式: $mode"
    if "$SCRIPT_DIR/start.sh" "$mode" $start_args; then
        success "服务重启完成"
    else
        error "服务启动失败"
        exit 1
    fi
}

# 显示重启完成信息
show_restart_info() {
    local mode="$1"
    
    success "========== 服务重启完成 =========="
    echo -e "当前模式: ${GREEN}$mode${NC}"
    echo
    echo -e "${YELLOW}访问地址:${NC}"
    echo -e "  主应用: ${GREEN}http://localhost${NC}"
    echo -e "  健康检查: ${GREEN}http://localhost/health${NC}"
    
    if [[ "$mode" == "ha" ]]; then
        echo -e "  Grafana监控: ${GREEN}http://localhost:3001${NC} (admin/admin123)"
        echo -e "  Prometheus: ${GREEN}http://localhost:9090${NC}"
        echo -e "  HAProxy统计: ${GREEN}http://localhost:8404/stats${NC}"
    fi
    
    echo
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  查看状态: ./start.sh --status"
    echo "  查看日志: docker-compose -f docker-compose.*.yml logs -f"
    echo "  停止服务: ./stop.sh"
    echo "  更新镜像: ./pull.sh"
    echo
}

# 主函数
main() {
    local mode="auto"
    local verbose="false"
    local force="false"
    local pull="false"
    local show_logs="false"
    local quick="false"
    
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
            --pull)
                pull="true"
                shift
                ;;
            --logs)
                show_logs="true"
                shift
                ;;
            --quick)
                quick="true"
                shift
                ;;
            basic|full|ha|auto)
                mode="$1"
                shift
                ;;
            *)
                error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log "=== 在线时间工具 - 服务重启 ==="
    
    # 检查Docker
    check_docker
    
    # 确认操作
    if [[ "$quick" == "false" ]]; then
        echo -e "重启模式: ${YELLOW}$mode${NC}"
        if [[ "$pull" == "true" ]]; then
            echo -e "镜像更新: ${GREEN}是${NC}"
        fi
        if [[ "$force" == "true" ]]; then
            echo -e "强制重启: ${YELLOW}是${NC}"
        fi
        echo
        read -p "确认要重启服务吗? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "操作已取消"
            exit 0
        fi
    fi
    
    # 执行重启
    if [[ "$quick" == "true" ]]; then
        quick_restart "$verbose"
        
        # 获取当前模式用于显示信息
        local current_mode
        current_mode=$(detect_current_mode)
        show_restart_info "$current_mode"
    else
        full_restart "$mode" "$verbose" "$force" "$pull" "$show_logs"
        show_restart_info "$mode"
    fi
    
    success "重启脚本执行完成"
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi