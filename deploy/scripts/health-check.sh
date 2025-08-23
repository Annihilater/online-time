#!/bin/bash
# =================================
# 在线时间工具 - 健康检查脚本
# =================================

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${DEPLOY_DIR}/logs/health-check.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${TIMESTAMP} $1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

log_error() {
    log "${RED}✗ $1${NC}"
}

log_info() {
    log "${BLUE}ℹ $1${NC}"
}

# 检查Docker容器状态
check_containers() {
    log_info "检查Docker容器状态..."
    
    local containers=(
        "online-time-app-1"
        "online-time-app-2" 
        "online-time-app-3"
        "online-time-nginx"
        "online-time-haproxy"
        "online-time-redis-master"
        "online-time-redis-slave"
        "online-time-prometheus"
        "online-time-grafana"
    )
    
    local failed=0
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
            local status=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            if [ "$status" = "healthy" ] || [ "$status" = "no-healthcheck" ]; then
                log_success "容器 $container 运行正常"
            else
                log_warning "容器 $container 健康检查失败: $status"
                ((failed++))
            fi
        else
            log_error "容器 $container 未运行"
            ((failed++))
        fi
    done
    
    return $failed
}

# 检查应用服务可用性
check_app_services() {
    log_info "检查应用服务可用性..."
    
    local endpoints=(
        "http://localhost:80/"
        "http://localhost:80/health"
    )
    
    local failed=0
    
    for endpoint in "${endpoints[@]}"; do
        if curl -sf --max-time 10 "$endpoint" > /dev/null; then
            log_success "端点 $endpoint 响应正常"
        else
            log_error "端点 $endpoint 无响应"
            ((failed++))
        fi
    done
    
    # 检查负载均衡器状态
    if curl -sf --max-time 5 "http://localhost:8404/stats" > /dev/null; then
        log_success "HAProxy统计页面可访问"
    else
        log_error "HAProxy统计页面不可访问"
        ((failed++))
    fi
    
    return $failed
}

# 检查监控服务
check_monitoring_services() {
    log_info "检查监控服务..."
    
    local services=(
        "http://localhost:9090/-/healthy"     # Prometheus
        "http://localhost:3001/api/health"    # Grafana
        "http://localhost:3100/ready"         # Loki (如果启用)
    )
    
    local failed=0
    
    for service in "${services[@]}"; do
        local service_name=$(echo "$service" | cut -d'/' -f3 | cut -d':' -f1)
        if curl -sf --max-time 10 "$service" > /dev/null 2>&1; then
            log_success "监控服务 $service_name 运行正常"
        else
            log_warning "监控服务 $service_name 可能未启用或响应异常"
        fi
    done
    
    return $failed
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源使用情况..."
    
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log_warning "CPU使用率较高: ${cpu_usage}%"
    else
        log_success "CPU使用率正常: ${cpu_usage}%"
    fi
    
    # 内存使用率
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        log_warning "内存使用率较高: ${mem_usage}%"
    else
        log_success "内存使用率正常: ${mem_usage}%"
    fi
    
    # 磁盘使用率
    local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
    if [ "$disk_usage" -gt 90 ]; then
        log_error "磁盘空间不足: ${disk_usage}% 已使用"
        return 1
    elif [ "$disk_usage" -gt 80 ]; then
        log_warning "磁盘使用率较高: ${disk_usage}%"
    else
        log_success "磁盘空间充足: ${disk_usage}% 已使用"
    fi
    
    # 检查Docker磁盘使用
    local docker_usage=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}")
    log_info "Docker磁盘使用情况:"
    echo "$docker_usage" | tee -a "$LOG_FILE"
    
    return 0
}

# 检查网络连通性
check_network_connectivity() {
    log_info "检查网络连通性..."
    
    # 检查DNS解析
    if nslookup google.com > /dev/null 2>&1; then
        log_success "DNS解析正常"
    else
        log_error "DNS解析失败"
        return 1
    fi
    
    # 检查外网连通性
    if curl -sf --max-time 10 "http://httpbin.org/ip" > /dev/null; then
        log_success "外网连通性正常"
    else
        log_warning "外网连通性异常"
    fi
    
    # 检查内部网络
    if docker network ls | grep -q "online-time"; then
        log_success "Docker网络正常"
    else
        log_error "Docker网络异常"
        return 1
    fi
    
    return 0
}

# 检查日志状态
check_logs() {
    log_info "检查最近的错误日志..."
    
    local log_dirs=(
        "${DEPLOY_DIR}/logs"
        "/var/log/nginx"
    )
    
    local error_count=0
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # 查找最近1小时的ERROR级别日志
            local recent_errors=$(find "$log_dir" -name "*.log" -mmin -60 -exec grep -l "ERROR\|CRITICAL\|FATAL" {} \; 2>/dev/null | wc -l)
            if [ "$recent_errors" -gt 0 ]; then
                log_warning "在 $log_dir 中发现 $recent_errors 个包含错误的日志文件"
                ((error_count++))
            fi
        fi
    done
    
    if [ $error_count -eq 0 ]; then
        log_success "未发现最近的错误日志"
    fi
    
    return 0
}

# 性能基准测试
run_performance_test() {
    log_info "运行性能基准测试..."
    
    # 简单的响应时间测试
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost/")
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        log_success "响应时间正常: ${response_time}s"
    elif (( $(echo "$response_time < 3.0" | bc -l) )); then
        log_warning "响应时间较慢: ${response_time}s"
    else
        log_error "响应时间过慢: ${response_time}s"
        return 1
    fi
    
    return 0
}

# 生成健康报告
generate_health_report() {
    local report_file="${DEPLOY_DIR}/logs/health-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat << EOF > "$report_file"
{
    "timestamp": "$(date -Iseconds)",
    "overall_status": "$1",
    "checks": {
        "containers": $2,
        "app_services": $3,
        "monitoring": $4,
        "system_resources": $5,
        "network": $6,
        "logs": $7,
        "performance": $8
    },
    "system_info": {
        "hostname": "$(hostname)",
        "uptime": "$(uptime -p)",
        "docker_version": "$(docker --version)",
        "compose_version": "$(docker-compose --version)"
    }
}
EOF
    
    log_info "健康报告已生成: $report_file"
}

# 主函数
main() {
    log_info "==================== 开始健康检查 ===================="
    
    mkdir -p "${DEPLOY_DIR}/logs"
    
    # 执行各项检查
    local total_failed=0
    local checks=()
    
    check_containers && checks+=(0) || { checks+=(1); ((total_failed++)); }
    check_app_services && checks+=(0) || { checks+=(1); ((total_failed++)); }
    check_monitoring_services && checks+=(0) || { checks+=(1); ((total_failed++)); }
    check_system_resources && checks+=(0) || { checks+=(1); ((total_failed++)); }
    check_network_connectivity && checks+=(0) || { checks+=(1); ((total_failed++)); }
    check_logs && checks+=(0) || { checks+=(1); ((total_failed++)); }
    run_performance_test && checks+=(0) || { checks+=(1); ((total_failed++)); }
    
    # 生成总结报告
    if [ $total_failed -eq 0 ]; then
        log_success "==================== 所有检查通过 ===================="
        generate_health_report "healthy" "${checks[@]}"
        exit 0
    elif [ $total_failed -le 2 ]; then
        log_warning "==================== 发现 $total_failed 个问题 ===================="
        generate_health_report "warning" "${checks[@]}"
        exit 1
    else
        log_error "==================== 发现 $total_failed 个严重问题 ===================="
        generate_health_report "critical" "${checks[@]}"
        exit 2
    fi
}

# 检查依赖工具
check_dependencies() {
    local deps=("docker" "curl" "bc")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "缺少依赖工具: $dep"
            exit 1
        fi
    done
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    check_dependencies
    main "$@"
fi