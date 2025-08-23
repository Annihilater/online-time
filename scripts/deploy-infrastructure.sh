#!/bin/bash
# 基础设施自动化部署脚本

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/deploy.log"
ENVIRONMENT="${1:-dev}"
DEPLOY_TYPE="${2:-basic}"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}INFO: $1${NC}"
}

log_success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

log_error() {
    log "${RED}ERROR: $1${NC}"
}

# 错误处理
handle_error() {
    log_error "Deployment failed at line $1"
    cleanup_on_error
    exit 1
}

trap 'handle_error $LINENO' ERR

# 错误清理
cleanup_on_error() {
    log_warning "Cleaning up due to error..."
    # 停止可能启动的服务
    docker-compose -f docker-compose.yml down 2>/dev/null || true
    docker-compose -f docker-compose.monitoring.yml down 2>/dev/null || true
    docker-compose -f docker-compose.ha.yml down 2>/dev/null || true
}

# 检查依赖
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # 检查Docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
    fi
    
    # 检查curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_error "Please install the missing dependencies and try again"
        exit 1
    fi
    
    # 检查Docker服务
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker service is not running"
        exit 1
    fi
    
    log_success "All dependencies are satisfied"
}

# 创建目录结构
create_directories() {
    log_info "Creating directory structure..."
    
    local directories=(
        "data/redis"
        "data/prometheus"
        "data/grafana"
        "data/loki"
        "data/alertmanager"
        "data/backups"
        "logs"
        "config"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$PROJECT_ROOT/$dir"
        log_info "Created directory: $dir"
    done
    
    log_success "Directory structure created"
}

# 设置环境配置
setup_environment() {
    log_info "Setting up $ENVIRONMENT environment configuration..."
    
    if [[ ! -f "$PROJECT_ROOT/environments/$ENVIRONMENT/.env" ]]; then
        log_error "Environment configuration not found: environments/$ENVIRONMENT/.env"
        exit 1
    fi
    
    # 复制环境配置
    cp "$PROJECT_ROOT/environments/$ENVIRONMENT/.env" "$PROJECT_ROOT/.env"
    
    log_success "Environment configuration set for: $ENVIRONMENT"
}

# 生成动态配置
generate_configs() {
    log_info "Generating dynamic configurations..."
    
    # 生成Prometheus配置
    if [[ ! -f "$PROJECT_ROOT/monitoring/prometheus.yml" ]]; then
        log_warning "Prometheus config not found, using default"
    fi
    
    # 检查并更新Redis密码
    if grep -q "CHANGE_ME" "$PROJECT_ROOT/.env" 2>/dev/null; then
        log_warning "Default passwords detected in .env file"
        log_warning "Please update passwords before production deployment"
    fi
    
    log_success "Configuration generation completed"
}

# 部署基础服务
deploy_basic() {
    log_info "Deploying basic services..."
    
    # 构建镜像
    docker-compose -f docker-compose.yml build --no-cache
    
    # 启动服务
    docker-compose -f docker-compose.yml up -d
    
    # 等待服务启动
    wait_for_service "http://localhost/health" "Online Time App" 60
    
    log_success "Basic services deployed successfully"
}

# 部署监控服务
deploy_monitoring() {
    log_info "Deploying monitoring services..."
    
    # 启动监控服务
    docker-compose -f docker-compose.monitoring.yml up -d
    
    # 等待服务启动
    wait_for_service "http://localhost:9090/-/healthy" "Prometheus" 60
    wait_for_service "http://localhost:3000/api/health" "Grafana" 60
    wait_for_service "http://localhost:9093/-/healthy" "AlertManager" 60
    
    log_success "Monitoring services deployed successfully"
    log_info "Access URLs:"
    log_info "  Prometheus: http://localhost:9090"
    log_info "  Grafana: http://localhost:3000 (admin/admin123)"
    log_info "  AlertManager: http://localhost:9093"
}

# 部署高可用性服务
deploy_ha() {
    log_info "Deploying high availability services..."
    
    # 启动高可用性服务
    docker-compose -f docker-compose.ha.yml up -d
    
    # 等待服务启动
    wait_for_service "http://localhost:8404/stats" "HAProxy Stats" 60
    wait_for_service "http://localhost" "Load Balanced App" 60
    
    log_success "High availability services deployed successfully"
    log_info "Access URLs:"
    log_info "  Application: http://localhost"
    log_info "  HAProxy Stats: http://localhost:8404/stats"
}

# 等待服务可用
wait_for_service() {
    local url="$1"
    local service_name="$2"
    local timeout="${3:-30}"
    local interval=5
    local elapsed=0
    
    log_info "Waiting for $service_name to be available..."
    
    while [[ $elapsed -lt $timeout ]]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            log_success "$service_name is now available"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        log_info "Waiting for $service_name... (${elapsed}s/${timeout}s)"
    done
    
    log_error "$service_name failed to become available within ${timeout}s"
    return 1
}

# 运行初始化检查
run_initial_checks() {
    log_info "Running initial health checks..."
    
    # 运行健康检查
    if [[ -f "$PROJECT_ROOT/scripts/health/health-check.sh" ]]; then
        chmod +x "$PROJECT_ROOT/scripts/health/health-check.sh"
        "$PROJECT_ROOT/scripts/health/health-check.sh" || {
            log_warning "Initial health check failed, but continuing deployment"
        }
    fi
    
    log_success "Initial checks completed"
}

# 设置定时任务
setup_cron_jobs() {
    log_info "Setting up cron jobs..."
    
    local cron_file="/tmp/online-time-cron"
    
    # 创建 cron 任务
    cat > "$cron_file" << EOF
# Online Time 维护任务

# 每日 2:00 执行备份
0 2 * * * cd $PROJECT_ROOT && ./scripts/backup/backup.sh full >> logs/cron.log 2>&1

# 每小时执行健康检查
0 * * * * cd $PROJECT_ROOT && ./scripts/health/health-check.sh >> logs/cron.log 2>&1

# 每 5 分钟执行系统监控
*/5 * * * * cd $PROJECT_ROOT && ./scripts/monitoring/monitor.sh >> logs/cron.log 2>&1

# 每周日 3:00 清理日志
0 3 * * 0 cd $PROJECT_ROOT && ./scripts/monitoring/monitor.sh cleanup 7 >> logs/cron.log 2>&1

EOF
    
    # 安装 cron 任务(仅在非容器环境)
    if [[ ! -f "/.dockerenv" ]] && command -v crontab >/dev/null 2>&1; then
        crontab "$cron_file"
        log_success "Cron jobs installed"
    else
        log_warning "Skipping cron installation (container environment or crontab not available)"
    fi
    
    rm -f "$cron_file"
}

# 显示部署结果
show_deployment_summary() {
    log_info "=== Deployment Summary ==="
    
    echo ""
    echo -e "${GREEN}部署成功！${NC}"
    echo -e "${BLUE}环境: ${ENVIRONMENT}${NC}"
    echo -e "${BLUE}部署类型: ${DEPLOY_TYPE}${NC}"
    echo ""
    
    echo -e "${YELLOW}访问地址:${NC}"
    echo "  主应用: http://localhost"
    
    if docker ps | grep -q "prometheus"; then
        echo "  Prometheus: http://localhost:9090"
        echo "  Grafana: http://localhost:3000 (admin/admin123)"
        echo "  AlertManager: http://localhost:9093"
    fi
    
    if docker ps | grep -q "haproxy"; then
        echo "  HAProxy Stats: http://localhost:8404/stats"
    fi
    
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  查看服务状态: make -f Makefile.infrastructure status"
    echo "  查看日志: make -f Makefile.infrastructure logs"
    echo "  健康检查: make -f Makefile.infrastructure health-check"
    echo "  执行备份: make -f Makefile.infrastructure backup"
    echo ""
}

# 显示帮助
show_help() {
    cat << EOF
基础设施部署脚本

用法: $0 [environment] [deploy_type]

参数:
  environment    部署环境 (dev|test|prod) [默认: dev]
  deploy_type    部署类型 (basic|monitoring|ha|full) [默认: basic]

部署类型说明:
  basic         只部署基础应用服务
  monitoring    部署应用服务 + 监控服务
  ha            部署高可用性服务
  full          部署所有服务

示例:
  $0 dev basic          # 部署开发环境基础服务
  $0 prod monitoring    # 部署生产环境含监控
  $0 prod full         # 部署生产环境全部服务

EOF
}

# 主部署流程
main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    log_info "=== Starting Infrastructure Deployment ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Deploy Type: $DEPLOY_TYPE"
    
    # 检查依赖
    check_dependencies
    
    # 创建目录
    create_directories
    
    # 设置环境
    setup_environment
    
    # 生成配置
    generate_configs
    
    # 根据部署类型执行部署
    case "$DEPLOY_TYPE" in
        "basic")
            deploy_basic
            ;;
        "monitoring")
            deploy_basic
            deploy_monitoring
            ;;
        "ha")
            deploy_ha
            ;;
        "full")
            deploy_basic
            deploy_monitoring
            deploy_ha
            ;;
        *)
            log_error "Unknown deploy type: $DEPLOY_TYPE"
            show_help
            exit 1
            ;;
    esac
    
    # 运行检查
    run_initial_checks
    
    # 设置定时任务
    setup_cron_jobs
    
    # 显示部署结果
    show_deployment_summary
    
    log_success "=== Infrastructure Deployment Completed Successfully ==="
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi