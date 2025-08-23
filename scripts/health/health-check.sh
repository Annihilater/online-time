#!/bin/bash
# 健康检查脚本

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")")
LOG_FILE="$PROJECT_ROOT/logs/health-check.log"
ALERT_WEBHOOK="http://localhost:5001/webhook/health"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 发送告警
send_alert() {
    local message="$1"
    local level="${2:-warning}"
    
    curl -s -X POST "$ALERT_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{
            \"level\": \"$level\",
            \"message\": \"$message\",
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\",
            \"service\": \"health-check\"
        }" || true
}

# 检查HTTP响应
check_http() {
    local url="$1"
    local name="$2"
    local expected_status="${3:-200}"
    
    log "Checking $name ($url)"
    
    local response
    local http_code
    local response_time
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" "$url" || echo "ERROR\n000\n0")
    http_code=$(echo "$response" | tail -n 2 | head -n 1)
    response_time=$(echo "$response" | tail -n 1)
    
    if [[ "$http_code" == "$expected_status" ]]; then
        log "✓ $name is healthy (${response_time}s)"
        return 0
    else
        log "✗ $name is unhealthy (HTTP $http_code)"
        send_alert "$name is unhealthy (HTTP $http_code)" "critical"
        return 1
    fi
}

# 检查Docker容器
check_container() {
    local container_name="$1"
    
    log "Checking container: $container_name"
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        log "✓ Container $container_name is running"
        
        # 检查容器健康状态
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
        
        if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "none" ]]; then
            log "✓ Container $container_name is healthy"
            return 0
        else
            log "✗ Container $container_name is unhealthy ($health_status)"
            send_alert "Container $container_name is unhealthy ($health_status)" "warning"
            return 1
        fi
    else
        log "✗ Container $container_name is not running"
        send_alert "Container $container_name is not running" "critical"
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    local threshold="${1:-80}"
    
    log "Checking disk space (threshold: ${threshold}%)"
    
    local usage
    usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ "$usage" -lt "$threshold" ]]; then
        log "✓ Disk usage is acceptable (${usage}%)"
        return 0
    else
        log "✗ Disk usage is high (${usage}%)"
        if [[ "$usage" -gt 90 ]]; then
            send_alert "Disk usage is critical (${usage}%)" "critical"
        else
            send_alert "Disk usage is high (${usage}%)" "warning"
        fi
        return 1
    fi
}

# 检查内存使用
check_memory() {
    local threshold="${1:-80}"
    
    log "Checking memory usage (threshold: ${threshold}%)"
    
    local usage
    usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [[ "$usage" -lt "$threshold" ]]; then
        log "✓ Memory usage is acceptable (${usage}%)"
        return 0
    else
        log "✗ Memory usage is high (${usage}%)"
        if [[ "$usage" -gt 90 ]]; then
            send_alert "Memory usage is critical (${usage}%)" "critical"
        else
            send_alert "Memory usage is high (${usage}%)" "warning"
        fi
        return 1
    fi
}

# 主检查流程
main() {
    log "=== Health Check Started ==="
    
    local exit_code=0
    
    # 检查应用服务
    check_http "http://localhost/health" "Online Time App" || exit_code=1
    
    # 检查监控服务
    check_http "http://localhost:9090/-/healthy" "Prometheus" || exit_code=1
    check_http "http://localhost:3000/api/health" "Grafana" || exit_code=1
    check_http "http://localhost:9093/-/healthy" "AlertManager" || exit_code=1
    
    # 检查容器状态
    check_container "online-time-app" || exit_code=1
    
    # 检查系统资源
    check_disk_space 80 || exit_code=1
    check_memory 80 || exit_code=1
    
    if [[ $exit_code -eq 0 ]]; then
        log "=== All Health Checks Passed ==="
    else
        log "=== Some Health Checks Failed ==="
    fi
    
    log "=== Health Check Completed ==="
    return $exit_code
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi