#!/bin/bash

# Online Time 部署脚本
# 支持Docker容器化部署的自动化脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
IMAGE_NAME="online-time"
CONTAINER_NAME="online-time-app"
PORT=${PORT:-80}
ENV=${ENV:-production}
COMPOSE_PROFILES=${COMPOSE_PROFILES:-""}

# 函数：打印日志
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 函数：检查Docker是否安装
check_docker() {
    log "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    success "Docker环境检查通过"
}

# 函数：清理旧容器和镜像
cleanup() {
    log "清理旧的容器和镜像..."
    
    # 停止并删除容器
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "停止容器 ${CONTAINER_NAME}..."
        docker stop ${CONTAINER_NAME} || true
        docker rm ${CONTAINER_NAME} || true
    fi
    
    # 清理无用的镜像
    docker image prune -f
    
    success "清理完成"
}

# 函数：构建Docker镜像
build_image() {
    log "构建Docker镜像..."
    
    # 检查是否存在Dockerfile
    if [ ! -f "Dockerfile" ]; then
        error "Dockerfile不存在"
        exit 1
    fi
    
    # 构建镜像
    docker build \
        --tag ${IMAGE_NAME}:latest \
        --tag ${IMAGE_NAME}:$(date +%Y%m%d-%H%M%S) \
        --build-arg NODE_ENV=${ENV} \
        -f docker/base/Dockerfile \
        .
    
    success "Docker镜像构建完成"
}

# 函数：运行健康检查
health_check() {
    log "进行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://127.0.0.1:${PORT}/health &> /dev/null; then
            success "应用健康检查通过"
            return 0
        fi
        
        log "健康检查尝试 ${attempt}/${max_attempts}..."
        sleep 2
        ((attempt++))
    done
    
    error "应用健康检查失败"
    return 1
}

# 函数：显示部署信息
show_info() {
    echo
    success "========== 部署完成 =========="
    echo -e "应用名称: ${GREEN}Online Time${NC}"
    echo -e "访问地址: ${GREEN}http://localhost:${PORT}${NC}"
    echo -e "健康检查: ${GREEN}http://localhost:${PORT}/health${NC}"
    echo -e "容器名称: ${GREEN}${CONTAINER_NAME}${NC}"
    echo -e "镜像版本: ${GREEN}${IMAGE_NAME}:latest${NC}"
    echo
    echo "常用命令:"
    echo "  查看日志: docker logs -f ${CONTAINER_NAME}"
    echo "  重启应用: docker restart ${CONTAINER_NAME}"
    echo "  停止应用: docker stop ${CONTAINER_NAME}"
    echo "  进入容器: docker exec -it ${CONTAINER_NAME} sh"
    echo
}

# 函数：使用Docker Compose部署
deploy_compose() {
    log "使用Docker Compose部署..."
    
    # 设置环境变量
    export NODE_ENV=${ENV}
    export PORT=${PORT}
    
    # 构建和启动服务
    if [ -n "${COMPOSE_PROFILES}" ]; then
        docker-compose --profile ${COMPOSE_PROFILES} up -d --build
    else
        docker-compose up -d --build
    fi
    
    success "Docker Compose部署完成"
}

# 函数：单容器部署
deploy_single() {
    log "单容器部署模式..."
    
    # 清理旧环境
    cleanup
    
    # 构建镜像
    build_image
    
    # 运行容器
    log "启动容器..."
    docker run -d \
        --name ${CONTAINER_NAME} \
        --restart unless-stopped \
        -p ${PORT}:80 \
        -e NODE_ENV=${ENV} \
        ${IMAGE_NAME}:latest
    
    success "容器启动完成"
}

# 函数：显示帮助信息
show_help() {
    echo "Online Time 部署脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -e, --env ENV           设置环境 (default: production)"
    echo "  -p, --port PORT         设置端口 (default: 80)"
    echo "  -c, --compose           使用Docker Compose部署"
    echo "  -s, --single            单容器部署 (default)"
    echo "  --profile PROFILE       Docker Compose profile (lb, monitoring)"
    echo "  --cleanup-only          仅清理环境"
    echo "  --no-health-check       跳过健康检查"
    echo
    echo "示例:"
    echo "  $0                      # 默认单容器部署"
    echo "  $0 -c                   # 使用Docker Compose部署"
    echo "  $0 -c --profile lb      # 启用负载均衡"
    echo "  $0 -p 8080 -e development  # 开发环境，端口8080"
    echo
}

# 主函数
main() {
    local use_compose=false
    local cleanup_only=false
    local skip_health_check=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--env)
                ENV="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -c|--compose)
                use_compose=true
                shift
                ;;
            -s|--single)
                use_compose=false
                shift
                ;;
            --profile)
                COMPOSE_PROFILES="$2"
                shift 2
                ;;
            --cleanup-only)
                cleanup_only=true
                shift
                ;;
            --no-health-check)
                skip_health_check=true
                shift
                ;;
            *)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示配置
    log "部署配置："
    echo "  环境: ${ENV}"
    echo "  端口: ${PORT}"
    echo "  模式: $([ "$use_compose" = true ] && echo 'Docker Compose' || echo '单容器')"
    [ -n "${COMPOSE_PROFILES}" ] && echo "  Profile: ${COMPOSE_PROFILES}"
    echo
    
    # 检查Docker环境
    check_docker
    
    # 仅清理模式
    if [ "$cleanup_only" = true ]; then
        cleanup
        success "清理完成"
        exit 0
    fi
    
    # 部署应用
    if [ "$use_compose" = true ]; then
        deploy_compose
    else
        deploy_single
    fi
    
    # 健康检查
    if [ "$skip_health_check" = false ]; then
        sleep 5  # 等待容器启动
        if ! health_check; then
            error "部署失败：健康检查未通过"
            exit 1
        fi
    fi
    
    # 显示部署信息
    show_info
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi