#!/bin/bash

# =================================
# 跨平台Docker镜像构建推送脚本
# =================================
# 支持 AMD64 (x86_64) 和 ARM64 (Apple Silicon) 架构
# 自动推送到 Docker Hub

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置变量
DOCKER_USERNAME="klause"
IMAGE_NAME="online-time"
REGISTRY="docker.io"
PLATFORMS="linux/amd64,linux/arm64"

# 日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

# 显示帮助信息
show_help() {
    cat << EOF
${CYAN}跨平台Docker镜像构建推送脚本${NC}

用法: $0 [选项]

选项:
  -h, --help          显示帮助信息
  -u, --username      Docker Hub用户名 (默认: klause)
  -i, --image         镜像名称 (默认: online-time)
  -t, --tag           镜像标签 (默认: latest)
  -p, --platforms     目标平台 (默认: linux/amd64,linux/arm64)
  --no-cache          不使用缓存构建
  --push-only         只推送已有镜像，不重新构建
  --dry-run          只显示将要执行的命令

示例:
  $0                                    # 构建并推送 klause/online-time:latest
  $0 -t v1.0.0                         # 构建并推送 klause/online-time:v1.0.0
  $0 -u myuser -i myapp -t v2.0.0      # 构建并推送 myuser/myapp:v2.0.0
  $0 --no-cache                        # 不使用缓存重新构建
  $0 --dry-run                         # 预览执行命令

EOF
}

# 检查依赖
check_dependencies() {
    log_step "检查构建环境..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 检查 Docker Buildx
    if ! docker buildx version &> /dev/null; then
        log_error "Docker Buildx 未安装或未启用"
        log_info "请运行: docker buildx create --use"
        exit 1
    fi
    
    # 检查 Docker 登录状态
    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行"
        exit 1
    fi
    
    log_success "构建环境检查通过"
}

# 设置 Docker Buildx
setup_buildx() {
    log_step "配置 Docker Buildx..."
    
    local builder_name="online-time-builder"
    
    # 检查是否已有构建器
    if docker buildx inspect $builder_name &> /dev/null; then
        log_info "使用现有构建器: $builder_name"
        docker buildx use $builder_name
    else
        log_info "创建新的构建器: $builder_name"
        docker buildx create --name $builder_name --use --platform $PLATFORMS
    fi
    
    # 启动构建器
    log_info "启动构建器..."
    docker buildx inspect --bootstrap
    
    log_success "Buildx 配置完成"
}

# 检查 Docker Hub 登录状态
check_docker_login() {
    log_step "检查 Docker Hub 登录状态..."
    
    # 尝试获取用户信息
    if docker system info 2>/dev/null | grep -q "Username"; then
        local current_user=$(docker system info 2>/dev/null | grep "Username:" | awk '{print $2}')
        if [[ "$current_user" == "$DOCKER_USERNAME" ]]; then
            log_success "已登录 Docker Hub: $current_user"
            return 0
        else
            log_warning "当前登录用户: $current_user，需要切换到: $DOCKER_USERNAME"
        fi
    fi
    
    # 需要登录
    log_info "请登录 Docker Hub..."
    echo -n "Docker Hub 密码: "
    read -s password
    echo
    
    if echo "$password" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
        log_success "Docker Hub 登录成功"
    else
        log_error "Docker Hub 登录失败"
        exit 1
    fi
}

# 生成版本信息
generate_version_info() {
    local tag=$1
    local build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local git_commit=""
    local git_branch=""
    
    if git rev-parse HEAD &> /dev/null; then
        git_commit=$(git rev-parse --short HEAD)
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    fi
    
    echo "BUILD_DATE=${build_date}"
    echo "VERSION=${tag}"
    echo "GIT_COMMIT=${git_commit}"
    echo "GIT_BRANCH=${git_branch}"
}

# 构建镜像
build_image() {
    local image_tag="$1"
    local no_cache="$2"
    local dry_run="$3"
    
    log_step "开始跨平台构建..."
    
    local full_image_name="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${image_tag}"
    local build_args=""
    
    # 生成构建参数
    while IFS= read -r line; do
        build_args+=" --build-arg $line"
    done <<< "$(generate_version_info $image_tag)"
    
    # 构建命令
    local build_cmd="docker buildx build \
        --platform $PLATFORMS \
        --tag $full_image_name \
        $build_args \
        $([ "$no_cache" = "true" ] && echo "--no-cache") \
        --push \
        ."
    
    if [ "$dry_run" = "true" ]; then
        log_info "预览命令:"
        echo "$build_cmd"
        return 0
    fi
    
    log_info "构建目标: $full_image_name"
    log_info "支持平台: $PLATFORMS"
    
    # 执行构建
    eval $build_cmd
    
    log_success "构建完成: $full_image_name"
}

# 推送已有镜像
push_existing_image() {
    local image_tag="$1"
    local dry_run="$2"
    
    log_step "推送已有镜像..."
    
    local full_image_name="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${image_tag}"
    
    # 检查本地镜像是否存在
    if ! docker image inspect "$IMAGE_NAME:$image_tag" &> /dev/null; then
        log_error "本地镜像不存在: $IMAGE_NAME:$image_tag"
        exit 1
    fi
    
    # 推送命令
    local push_cmd="docker push $full_image_name"
    
    if [ "$dry_run" = "true" ]; then
        log_info "预览命令:"
        echo "docker tag $IMAGE_NAME:$image_tag $full_image_name"
        echo "$push_cmd"
        return 0
    fi
    
    # 标记并推送
    docker tag "$IMAGE_NAME:$image_tag" "$full_image_name"
    docker push "$full_image_name"
    
    log_success "推送完成: $full_image_name"
}

# 验证镜像
verify_image() {
    local image_tag="$1"
    
    log_step "验证远程镜像..."
    
    local full_image_name="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${image_tag}"
    
    # 检查镜像清单
    if docker manifest inspect "$full_image_name" &> /dev/null; then
        log_success "镜像验证通过: $full_image_name"
        
        # 显示支持的架构
        local archs=$(docker manifest inspect "$full_image_name" | jq -r '.manifests[].platform.architecture' | tr '\n' ',' | sed 's/,$//')
        log_info "支持架构: $archs"
    else
        log_error "镜像验证失败: $full_image_name"
        exit 1
    fi
}

# 清理构建缓存
cleanup_cache() {
    log_step "清理构建缓存..."
    
    # 清理构建缓存
    docker buildx prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    log_success "缓存清理完成"
}

# 显示使用说明
show_usage_info() {
    local image_tag="$1"
    local full_image_name="${REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${image_tag}"
    
    cat << EOF

${GREEN}🎉 构建推送完成！${NC}

${CYAN}镜像信息:${NC}
  镜像名称: $full_image_name
  支持平台: $PLATFORMS
  
${CYAN}使用方法:${NC}
  # 拉取镜像
  docker pull $full_image_name
  
  # 运行容器
  docker run -d --name online-time-app -p 9653:9653 $full_image_name
  
${CYAN}生产部署:${NC}
  # 在生产服务器上更新 .env.prod
  DOCKER_IMAGE=$full_image_name
  
  # 重新部署
  ./stop.sh && ./start.sh 1panel

${CYAN}验证部署:${NC}
  curl http://localhost:9653/health

EOF
}

# 主函数
main() {
    local image_tag="latest"
    local no_cache="false"
    local push_only="false"
    local dry_run="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -u|--username)
                DOCKER_USERNAME="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                image_tag="$2"
                shift 2
                ;;
            -p|--platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            --no-cache)
                no_cache="true"
                shift
                ;;
            --push-only)
                push_only="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示配置
    log_info "构建配置:"
    echo "  用户名: $DOCKER_USERNAME"
    echo "  镜像名: $IMAGE_NAME"
    echo "  标签: $image_tag"
    echo "  平台: $PLATFORMS"
    echo "  无缓存: $no_cache"
    echo "  仅推送: $push_only"
    echo "  预览模式: $dry_run"
    echo
    
    # 执行构建流程
    if [ "$dry_run" != "true" ]; then
        check_dependencies
        check_docker_login
    fi
    
    if [ "$push_only" = "true" ]; then
        push_existing_image "$image_tag" "$dry_run"
    else
        if [ "$dry_run" != "true" ]; then
            setup_buildx
        fi
        build_image "$image_tag" "$no_cache" "$dry_run"
    fi
    
    if [ "$dry_run" != "true" ]; then
        verify_image "$image_tag"
        show_usage_info "$image_tag"
    fi
    
    log_success "所有操作完成！"
}

# 脚本入口
main "$@"