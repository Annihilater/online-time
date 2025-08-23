#!/bin/bash

# =================================
# 在线时间工具 - 镜像拉取脚本
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
    echo "在线时间工具 - 镜像拉取脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -v, --verbose    详细输出"
    echo "  -f, --force      强制拉取 (跳过版本检查)"
    echo "  --tag TAG        指定镜像标签 (默认: latest)"
    echo "  --image IMAGE    指定镜像名称"
    echo "  --all            拉取所有相关镜像"
    echo "  --dry-run        仅显示将要拉取的镜像，不执行"
    echo
    echo "示例:"
    echo "  $0               # 拉取默认镜像"
    echo "  $0 --tag 1.0.0   # 拉取指定版本"
    echo "  $0 --all         # 拉取所有相关镜像"
    echo "  $0 --dry-run     # 预览要拉取的镜像"
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
        warn "使用默认配置"
        # 设置默认值
        DOCKER_IMAGE="klause/online-time:latest"
    fi
}

# 获取镜像信息
get_image_info() {
    local image="$1"
    local verbose="$2"
    
    log "获取镜像信息: $image"
    
    # 检查本地镜像
    local local_id=""
    if docker images --format "{{.ID}}" "$image" | head -1 | grep -q .; then
        local_id=$(docker images --format "{{.ID}}" "$image" | head -1)
        if [[ "$verbose" == "true" ]]; then
            echo -e "${YELLOW}本地镜像:${NC}"
            docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}" "$image"
        fi
    else
        warn "本地未找到镜像: $image"
    fi
    
    # 检查远程镜像信息
    if [[ "$verbose" == "true" ]]; then
        log "检查远程镜像信息..."
        if docker manifest inspect "$image" &>/dev/null; then
            success "远程镜像可用: $image"
        else
            warn "无法获取远程镜像信息: $image"
        fi
    fi
    
    echo "$local_id"
}

# 拉取单个镜像
pull_image() {
    local image="$1"
    local verbose="$2"
    local force="$3"
    
    log "准备拉取镜像: $image"
    
    # 获取当前镜像信息
    local old_id
    old_id=$(get_image_info "$image" "$verbose")
    
    # 如果不是强制拉取，检查是否需要更新
    if [[ "$force" == "false" ]] && [[ -n "$old_id" ]]; then
        log "检查镜像是否需要更新..."
        
        # 先拉取manifest检查
        if docker pull "$image" --quiet 2>/dev/null; then
            local new_id
            new_id=$(docker images --format "{{.ID}}" "$image" | head -1)
            
            if [[ "$old_id" == "$new_id" ]]; then
                success "镜像已是最新版本: $image"
                return 0
            else
                log "发现新版本镜像"
            fi
        else
            warn "无法检查镜像更新: $image"
        fi
    fi
    
    # 执行拉取
    log "正在拉取镜像: $image"
    
    local pull_args=""
    if [[ "$verbose" == "false" ]]; then
        pull_args="--quiet"
    fi
    
    if docker pull $pull_args "$image"; then
        success "镜像拉取成功: $image"
        
        # 显示新镜像信息
        if [[ "$verbose" == "true" ]]; then
            echo -e "${GREEN}新镜像信息:${NC}"
            docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}" "$image"
        fi
        
        # 清理旧镜像
        if [[ -n "$old_id" ]] && [[ "$old_id" != "$(docker images --format "{{.ID}}" "$image" | head -1)" ]]; then
            log "清理旧镜像: $old_id"
            docker rmi "$old_id" 2>/dev/null || warn "无法删除旧镜像: $old_id"
        fi
        
        return 0
    else
        error "镜像拉取失败: $image"
        return 1
    fi
}

# 获取相关镜像列表
get_related_images() {
    local base_image="$1"
    local tag="$2"
    
    # 基础镜像
    local images=("$base_image")
    
    # 如果是拉取所有镜像，添加相关镜像
    images+=(
        "nginx:alpine"
        "redis:alpine"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
        "haproxy:alpine"
        "prom/node-exporter:latest"
        "prom/alertmanager:latest"
        "grafana/loki:latest"
        "grafana/promtail:latest"
    )
    
    # 输出镜像列表
    printf '%s\n' "${images[@]}"
}

# 检测当前使用的镜像
detect_current_images() {
    log "检测当前使用的镜像..."
    
    local images=()
    
    # 检查compose文件中定义的镜像
    if [[ -f "docker-compose.prod.yml" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ image:\ (.+) ]]; then
                images+=("${BASH_REMATCH[1]}")
            fi
        done < "docker-compose.prod.yml"
    fi
    
    if [[ -f "docker-compose.ha.yml" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ image:\ (.+) ]]; then
                images+=("${BASH_REMATCH[1]}")
            fi
        done < "docker-compose.ha.yml"
    fi
    
    # 去重并输出
    printf '%s\n' "${images[@]}" | sort -u
}

# 主拉取逻辑
main_pull() {
    local verbose="$1"
    local force="$2"
    local tag="$3"
    local image="$4"
    local pull_all="$5"
    local dry_run="$6"
    
    local images_to_pull=()
    
    if [[ "$pull_all" == "true" ]]; then
        log "获取所有相关镜像列表..."
        mapfile -t images_to_pull < <(detect_current_images)
    else
        # 确定要拉取的镜像
        if [[ -n "$image" ]]; then
            if [[ -n "$tag" ]] && [[ "$image" != *":"* ]]; then
                images_to_pull=("$image:$tag")
            else
                images_to_pull=("$image")
            fi
        else
            # 使用环境配置中的镜像
            local base_image="$DOCKER_IMAGE"
            if [[ -n "$tag" ]] && [[ "$base_image" == *":latest" ]]; then
                base_image="${base_image%:latest}:$tag"
            fi
            images_to_pull=("$base_image")
        fi
    fi
    
    if [[ ${#images_to_pull[@]} -eq 0 ]]; then
        warn "没有找到要拉取的镜像"
        exit 1
    fi
    
    # 显示将要拉取的镜像
    echo -e "${YELLOW}将要拉取的镜像:${NC}"
    printf '  %s\n' "${images_to_pull[@]}"
    echo
    
    if [[ "$dry_run" == "true" ]]; then
        success "Dry-run 模式完成"
        exit 0
    fi
    
    # 确认拉取
    if [[ ${#images_to_pull[@]} -gt 1 ]]; then
        read -p "确认要拉取 ${#images_to_pull[@]} 个镜像吗? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "操作已取消"
            exit 0
        fi
    fi
    
    # 执行拉取
    local success_count=0
    local total_count=${#images_to_pull[@]}
    
    for img in "${images_to_pull[@]}"; do
        echo
        log "=== 拉取镜像 ($((success_count + 1))/$total_count): $img ==="
        
        if pull_image "$img" "$verbose" "$force"; then
            ((success_count++))
        else
            warn "跳过失败的镜像: $img"
        fi
    done
    
    # 显示拉取结果
    echo
    success "========== 镜像拉取完成 =========="
    echo -e "成功拉取: ${GREEN}$success_count${NC}/$total_count 个镜像"
    
    if [[ $success_count -lt $total_count ]]; then
        warn "部分镜像拉取失败，请检查网络连接或镜像名称"
    fi
    
    # 显示磁盘使用情况
    if [[ "$verbose" == "true" ]]; then
        echo
        log "当前Docker镜像磁盘使用情况:"
        docker system df
    fi
}

# 主函数
main() {
    local verbose="false"
    local force="false"
    local tag=""
    local image=""
    local pull_all="false"
    local dry_run="false"
    
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
            --tag)
                tag="$2"
                shift 2
                ;;
            --image)
                image="$2"
                shift 2
                ;;
            --all)
                pull_all="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            *)
                error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log "=== 在线时间工具 - 镜像拉取 ==="
    
    # 检查Docker
    check_docker
    
    # 加载环境配置
    load_environment
    
    # 执行拉取
    main_pull "$verbose" "$force" "$tag" "$image" "$pull_all" "$dry_run"
    
    success "拉取脚本执行完成"
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi