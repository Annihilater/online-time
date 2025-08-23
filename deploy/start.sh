#!/bin/bash

# =================================
# 在线时间工具 - 服务启动脚本
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
ENV_FILE="$SCRIPT_DIR/.env.prod"

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
    echo "在线时间工具 - 服务启动脚本"
    echo
    echo "用法: $0 [模式]"
    echo
    echo "部署模式:"
    echo "  basic      基础模式 (默认) - 应用 + Nginx"
    echo "  full       完整模式 - 基础模式 + Redis"
    echo "  ha         高可用模式 - 多实例 + 负载均衡 + 监控"
    echo
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -v, --verbose  详细输出"
    echo "  -d, --detach   后台运行(默认)"
    echo "  --logs         启动后显示日志"
    echo
    echo "示例:"
    echo "  $0              # 基础模式启动"
    echo "  $0 full         # 完整模式启动"
    echo "  $0 ha --logs    # 高可用模式启动并显示日志"
}

# 检查环境
check_environment() {
    log "检查运行环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker服务
    if ! docker info &> /dev/null; then
        error "Docker服务未运行，请启动Docker服务"
        exit 1
    fi
    
    success "环境检查通过"
}

# 加载环境配置
load_environment() {
    if [[ -f "$ENV_FILE" ]]; then
        log "加载环境配置: $ENV_FILE"
        set -a  # automatically export all variables
        source "$ENV_FILE"
        set +a
        success "环境配置加载完成"
    else
        warn "环境配置文件不存在: $ENV_FILE"
        warn "使用默认配置启动"
    fi
}

# 检查服务状态
check_services() {
    local mode="$1"
    local compose_file="docker-compose.prod.yml"
    
    if [[ "$mode" == "ha" ]]; then
        compose_file="docker-compose.ha.yml"
    fi
    
    log "检查服务状态..."
    
    # 检查是否已经有服务在运行
    if docker-compose -f "$compose_file" ps -q | grep -q .; then
        warn "检测到已有服务在运行"
        echo "当前运行的服务:"
        docker-compose -f "$compose_file" ps
        echo
        read -p "是否要重新启动服务? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "停止现有服务..."
            docker-compose -f "$compose_file" down
            success "现有服务已停止"
        else
            log "取消启动操作"
            exit 0
        fi
    fi
}

# 创建必要目录
create_directories() {
    log "创建必要目录..."
    
    local directories=(
        "data"
        "logs"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
            mkdir -p "$SCRIPT_DIR/$dir"
            log "创建目录: $dir"
        fi
    done
    
    success "目录创建完成"
}

# 启动服务
start_services() {
    local mode="$1"
    local verbose="$2"
    local show_logs="$3"
    
    local compose_file="docker-compose.prod.yml"
    local compose_args=""
    
    if [[ "$mode" == "ha" ]]; then
        compose_file="docker-compose.ha.yml"
    fi
    
    if [[ "$verbose" == "true" ]]; then
        compose_args="--verbose"
    fi
    
    log "启动服务 - 模式: $mode"
    log "使用配置文件: $compose_file"
    
    # 拉取最新镜像
    log "拉取最新镜像..."
    docker-compose -f "$compose_file" pull
    
    # 启动服务
    log "启动容器..."
    if docker-compose -p "${COMPOSE_PROJECT_NAME:-online-time-prod}" -f "$compose_file" up -d $compose_args; then
        success "服务启动成功"
    else
        error "服务启动失败"
        exit 1
    fi
    
    # 等待服务就绪
    log "等待服务就绪..."
    sleep 5
    
    # 显示服务状态
    echo
    log "服务状态:"
    docker-compose -f "$compose_file" ps
    echo
    
    # 显示访问地址
    show_access_info "$mode"
    
    # 显示日志
    if [[ "$show_logs" == "true" ]]; then
        echo
        log "显示服务日志 (Ctrl+C 退出日志查看):"
        echo "----------------------------------------"
        docker-compose -f "$compose_file" logs -f
    fi
}

# 显示访问信息
show_access_info() {
    local mode="$1"
    
    success "========== 服务启动完成 =========="
    echo -e "部署模式: ${GREEN}$mode${NC}"
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
    echo "  重启服务: ./restart.sh"
    echo "  更新镜像: ./pull.sh"
    echo
}

# 显示服务状态
show_status() {
    log "检查服务状态..."
    
    local ha_running=false
    local basic_running=false
    
    # 检查高可用模式
    if docker-compose -f "docker-compose.ha.yml" ps -q 2>/dev/null | grep -q .; then
        echo -e "${GREEN}高可用模式服务状态:${NC}"
        docker-compose -f "docker-compose.ha.yml" ps
        ha_running=true
    fi
    
    # 检查基础/完整模式
    if docker-compose -f "docker-compose.prod.yml" ps -q 2>/dev/null | grep -q .; then
        echo -e "${GREEN}基础/完整模式服务状态:${NC}"
        docker-compose -f "docker-compose.prod.yml" ps
        basic_running=true
    fi
    
    if [[ "$ha_running" == "false" ]] && [[ "$basic_running" == "false" ]]; then
        warn "没有检测到运行中的服务"
        echo "使用 './start.sh [模式]' 启动服务"
    fi
}

# 主函数
main() {
    local mode="basic"
    local verbose="false"
    local show_logs="false"
    local show_status="false"
    
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
            --logs)
                show_logs="true"
                shift
                ;;
            --status)
                show_status="true"
                shift
                ;;
            -d|--detach)
                # 默认就是后台运行
                shift
                ;;
            basic|full|ha)
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
    
    # 如果只是查看状态
    if [[ "$show_status" == "true" ]]; then
        show_status
        exit 0
    fi
    
    log "=== 在线时间工具 - 服务启动 ==="
    log "模式: $mode"
    
    # 检查环境
    check_environment
    
    # 加载环境配置
    load_environment
    
    # 检查服务状态
    check_services "$mode"
    
    # 创建目录
    create_directories
    
    # 启动服务
    start_services "$mode" "$verbose" "$show_logs"
    
    success "启动脚本执行完成"
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi