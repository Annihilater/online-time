#!/bin/bash

# =================================
# 在线时间工具 - 一键部署脚本
# =================================
# 支持三种部署模式：basic | full | ha
# 用法: ./deploy.sh [模式] [选项]

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

# 默认配置
DEFAULT_MODE="basic"
CONFIG_FILE=".env.prod"
COMPOSE_FILE="docker-compose.prod.yml"
LOG_FILE="logs/deploy.log"
ENABLE_MONITORING=false
DISABLE_MONITORING=false

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
print_step() { print_msg "$PURPLE" "🚀 $1"; }

# 函数：显示帮助信息
show_help() {
    cat << EOF
在线时间工具 - 一键部署脚本

用法: $0 [模式] [选项]

部署模式:
  basic    基础模式 (应用 + nginx)
  1panel   1Panel单容器模式 (端口: 9653，适用于反向代理)
  full     完整模式 (应用 + nginx + redis)
  ha       高可用模式 (多实例 + 负载均衡 + 监控)

选项:
  -h, --help           显示帮助信息
  -c, --config FILE    指定配置文件 (默认: .env.prod)
  -f, --force          强制重新部署
  -v, --verbose        详细输出
  --dry-run           只检查不执行
  --skip-deps         跳过依赖检查
  --pull              强制拉取最新镜像

示例:
  $0                   # 基础模式部署
  $0 1panel           # 1Panel单容器部署
  $0 full             # 完整模式部署
  $0 ha --force       # 强制重新部署高可用模式
  $0 1panel --dry-run # 检查1Panel模式部署

EOF
}

# 函数：解析命令行参数
parse_args() {
    MODE="$DEFAULT_MODE"
    FORCE=false
    VERBOSE=false
    DRY_RUN=false
    SKIP_DEPS=false
    PULL_IMAGES=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            basic|1panel|full|ha)
                MODE="$1"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --pull)
                PULL_IMAGES=true
                shift
                ;;
            --monitoring)
                ENABLE_MONITORING=true
                shift
                ;;
            --no-monitoring)
                DISABLE_MONITORING=true
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 根据模式设置compose文件
    case "$MODE" in
        basic|1panel)
            COMPOSE_FILE="docker-compose.prod.yml"
            if [[ "$MODE" == "1panel" ]]; then
                print_info "使用1Panel单容器模式 (端口: 9653)"
            fi
            ;;
        full)
            COMPOSE_FILE="docker-compose.prod.yml"
            COMPOSE_PROFILES="--profile full"
            ;;
        ha)
            COMPOSE_FILE="docker-compose.ha.yml"
            ;;
        ha-monitoring)
            COMPOSE_FILE="docker-compose.ha.yml"
            ENABLE_MONITORING=true
            ;;
    esac
}

# 函数：检查系统依赖
check_dependencies() {
    if [[ "$SKIP_DEPS" == "true" ]]; then
        print_warning "跳过依赖检查"
        return 0
    fi
    
    print_step "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        # 检查Docker服务状态
        if ! docker info &> /dev/null; then
            print_error "Docker 服务未运行"
            return 1
        fi
        print_success "Docker: $(docker --version)"
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    else
        print_success "Docker Compose: $(docker-compose --version)"
    fi
    
    # 检查其他工具
    for tool in curl wget; do
        if ! command -v $tool &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "缺少以下依赖: ${missing_deps[*]}"
        print_info "请安装缺少的依赖后重试"
        return 1
    fi
    
    print_success "所有依赖检查通过"
}

# 函数：创建必要目录
create_directories() {
    print_step "创建必要目录..."
    
    local dirs=("data" "logs")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                mkdir -p "$dir"
            fi
            print_success "创建目录: $dir"
        fi
    done
}

# 函数：检查配置文件
check_config() {
    print_step "检查配置文件..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        if [[ -f ".env.example" ]]; then
            print_warning "配置文件不存在，从模板创建: $CONFIG_FILE"
            if [[ "$DRY_RUN" == "false" ]]; then
                cp .env.example "$CONFIG_FILE"
            fi
        else
            print_error "配置文件和模板都不存在: $CONFIG_FILE"
            return 1
        fi
    fi
    
    # 加载配置
    if [[ "$DRY_RUN" == "false" ]]; then
        set -a
        source "$CONFIG_FILE"
        set +a
    fi
    
    print_success "配置文件加载成功: $CONFIG_FILE"
    
    # 检查关键配置项
    local required_vars=("DOCKER_IMAGE")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" && "$DRY_RUN" == "false" ]]; then
            print_error "必需的配置项未设置: $var"
            return 1
        fi
    done
}

# 函数：拉取镜像
pull_images() {
    if [[ "$PULL_IMAGES" == "true" || "$FORCE" == "true" ]]; then
        print_step "拉取最新镜像..."
        
        if [[ "$DRY_RUN" == "false" ]]; then
            docker-compose -f "$COMPOSE_FILE" $COMPOSE_PROFILES pull
        fi
        
        print_success "镜像拉取完成"
    fi
}

# 函数：检查端口占用
check_ports() {
    print_step "检查端口占用..."
    
    local ports=("${HTTP_PORT:-80}")
    
    if [[ "$MODE" == "ha" ]] || [[ "$ENABLE_MONITORING" == "true" ]]; then
        ports+=("${HAPROXY_STATS_PORT:-8404}" "${PROMETHEUS_PORT:-9090}" "${GRAFANA_PORT:-3001}")
        ports+=("${LOKI_PORT:-3100}" "${ALERTMANAGER_PORT:-9093}" "${NODE_EXPORTER_PORT:-9100}")
    fi
    
    for port in "${ports[@]}"; do
        if command -v ss &> /dev/null; then
            if ss -tlnp | grep -q ":$port "; then
                print_warning "端口 $port 已被占用"
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -tlnp | grep -q ":$port "; then
                print_warning "端口 $port 已被占用"
            fi
        fi
    done
}

# 函数：配置监控服务
setup_monitoring() {
    if [[ "$ENABLE_MONITORING" == "true" ]] || [[ "$MODE" == "ha" ]] || [[ "$MODE" == "ha-monitoring" ]]; then
        print_step "配置监控服务..."
        
        # 创建监控相关目录
        local monitoring_dirs=(
            "data/prometheus"
            "data/grafana" 
            "data/alertmanager"
            "data/loki"
            "config/monitoring/prometheus"
            "config/monitoring/alertmanager"
            "config/monitoring/loki"
            "config/grafana/provisioning/datasources"
            "config/grafana/provisioning/dashboards"
        )
        
        for dir in "${monitoring_dirs[@]}"; do
            if [[ ! -d "$dir" ]] && [[ "$DRY_RUN" == "false" ]]; then
                mkdir -p "$dir"
                print_success "创建监控目录: $dir"
            fi
        done
        
        # 设置Grafana权限
        if [[ "$DRY_RUN" == "false" ]] && [[ -d "data/grafana" ]]; then
            chown -R 472:472 data/grafana 2>/dev/null || true
        fi
        
        # 加载监控环境变量
        if [[ -f ".env.monitoring" ]] && [[ "$DRY_RUN" == "false" ]]; then
            set -a
            source .env.monitoring
            set +a
            print_success "监控环境变量加载完成"
        fi
        
        print_success "监控配置完成"
    fi
}

# 函数：部署服务
deploy_services() {
    print_step "部署 $MODE 模式服务..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN - 将执行以下命令:"
        echo "docker-compose -f $COMPOSE_FILE $COMPOSE_PROFILES --env-file $CONFIG_FILE up -d"
        return 0
    fi
    
    # 停止现有服务 (如果存在且强制部署)
    if [[ "$FORCE" == "true" ]]; then
        print_info "停止现有服务..."
        docker-compose -f "$COMPOSE_FILE" $COMPOSE_PROFILES --env-file "$CONFIG_FILE" down --remove-orphans || true
    fi
    
    # 启动服务
    docker-compose -f "$COMPOSE_FILE" $COMPOSE_PROFILES --env-file "$CONFIG_FILE" up -d
    
    print_success "服务部署完成"
}

# 函数：健康检查
health_check() {
    print_step "进行服务健康检查..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN - 跳过健康检查"
        return 0
    fi
    
    local max_attempts=30
    local attempt=1
    local http_port="${HTTP_PORT:-80}"
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "健康检查 ($attempt/$max_attempts)..."
        
        if curl -sf "http://localhost:$http_port/health" &> /dev/null; then
            print_success "服务健康检查通过"
            return 0
        fi
        
        sleep 5
        ((attempt++))
    done
    
    print_error "服务健康检查失败"
    print_info "请检查服务日志: docker-compose -f $COMPOSE_FILE logs"
    return 1
}

# 函数：显示部署信息
show_deployment_info() {
    print_step "部署信息"
    
    echo "
╔═══════════════════════════════════════════════════════════════════════════════╗
║                            🎉 部署成功完成！                                   ║
╚═══════════════════════════════════════════════════════════════════════════════╝

📋 部署详情:
   模式: $MODE
   配置文件: $CONFIG_FILE
   Compose文件: $COMPOSE_FILE

🌐 访问地址:
   主应用: http://localhost:${HTTP_PORT:-80}
   健康检查: http://localhost:${HTTP_PORT:-80}/health"
    
    if [[ "$MODE" == "ha" ]] || [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo "   HAProxy统计: http://localhost:${HAPROXY_STATS_PORT:-8404}/stats
   Prometheus: http://localhost:${PROMETHEUS_PORT:-9090}
   Grafana: http://localhost:${GRAFANA_PORT:-3001} (admin/admin123)
   AlertManager: http://localhost:${ALERTMANAGER_PORT:-9093}
   Loki: http://localhost:${LOKI_PORT:-3100}"
    fi
    
    echo "
🔧 管理命令:
   查看状态: docker-compose -f $COMPOSE_FILE ps
   查看日志: docker-compose -f $COMPOSE_FILE logs -f
   停止服务: ./stop.sh
   更新服务: ./update.sh

📊 监控:
   容器状态: docker ps
   资源使用: docker stats
   日志位置: ./logs/

📝 注意事项:
   - 首次启动可能需要几分钟时间
   - 如遇问题请查看日志文件
   - 生产环境建议配置域名和反向代理
"
}

# 函数：清理函数
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "部署过程中出现错误 (退出码: $exit_code)"
        print_info "请查看日志文件: $LOG_FILE"
    fi
}

# 主函数
main() {
    # 设置错误处理
    trap cleanup EXIT
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    print_step "在线时间工具 - 一键部署开始"
    print_info "部署模式: $MODE"
    
    # 执行部署步骤
    parse_args "$@"
    check_dependencies
    create_directories
    check_config
    setup_monitoring
    check_ports
    pull_images
    deploy_services
    health_check
    show_deployment_info
    
    print_success "🎉 部署全部完成！"
}

# 执行主函数
main "$@"