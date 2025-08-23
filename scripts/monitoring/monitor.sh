#!/bin/bash
# 系统监控脚本

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")")
LOG_FILE="$PROJECT_ROOT/logs/monitor.log"
METRICS_FILE="$PROJECT_ROOT/logs/metrics.log"
ALERT_WEBHOOK="http://localhost:5001/webhook/monitor"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 指标记录
log_metric() {
    local metric_name="$1"
    local value="$2"
    local tags="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $metric_name=$value $tags" >> "$METRICS_FILE"
}

# 发送告警
send_alert() {
    local message="$1"
    local level="${2:-warning}"
    local metric="$3"
    
    curl -s -X POST "$ALERT_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{
            \"level\": \"$level\",
            \"message\": \"$message\",
            \"metric\": \"$metric\",
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\",
            \"service\": \"monitor\"
        }" || true
}

# 获取CPU使用率
get_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    echo "${cpu_usage:-0}"
}

# 获取内存使用率
get_memory_usage() {
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo "${mem_usage:-0}"
}

# 获取磁盘使用率
get_disk_usage() {
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "${disk_usage:-0}"
}

# 获取网络连接数
get_network_connections() {
    local connections
    connections=$(netstat -an | wc -l)
    echo "${connections:-0}"
}

# 获取Docker容器状态
get_container_stats() {
    local container_name="$1"
    
    if ! docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        echo "container_status=0 cpu_percent=0 memory_percent=0 memory_usage=0 memory_limit=0"
        return
    fi
    
    local stats
    stats=$(docker stats --no-stream --format "{{.CPUPerc}} {{.MemPerc}} {{.MemUsage}}" "$container_name" 2>/dev/null || echo "0% 0% 0B / 0B")
    
    local cpu_percent=$(echo "$stats" | awk '{print $1}' | sed 's/%//')
    local mem_percent=$(echo "$stats" | awk '{print $2}' | sed 's/%//')
    local mem_usage=$(echo "$stats" | awk '{print $3}' | sed 's/MiB//')
    local mem_limit=$(echo "$stats" | awk '{print $5}' | sed 's/MiB//')
    
    echo "container_status=1 cpu_percent=${cpu_percent:-0} memory_percent=${mem_percent:-0} memory_usage=${mem_usage:-0} memory_limit=${mem_limit:-0}"
}

# 获取HTTP响应时间
get_http_response_time() {
    local url="$1"
    local response_time
    
    response_time=$(curl -o /dev/null -s -w "%{time_total}" "$url" 2>/dev/null || echo "999")
    echo "${response_time:-999}"
}

# 检查HTTP状态
check_http_status() {
    local url="$1"
    local http_code
    
    http_code=$(curl -o /dev/null -s -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    echo "${http_code:-000}"
}

# 监控系统资源
monitor_system() {
    log "Monitoring system resources"
    
    # CPU使用率
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    log_metric "system_cpu_percent" "$cpu_usage" "host=localhost"
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        send_alert "High CPU usage: ${cpu_usage}%" "warning" "system_cpu_percent"
    fi
    
    # 内存使用率
    local mem_usage
    mem_usage=$(get_memory_usage)
    log_metric "system_memory_percent" "$mem_usage" "host=localhost"
    
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        send_alert "High memory usage: ${mem_usage}%" "warning" "system_memory_percent"
    fi
    
    # 磁盘使用率
    local disk_usage
    disk_usage=$(get_disk_usage)
    log_metric "system_disk_percent" "$disk_usage" "host=localhost,mount=/"
    
    if [[ "$disk_usage" -gt 80 ]]; then
        if [[ "$disk_usage" -gt 90 ]]; then
            send_alert "Critical disk usage: ${disk_usage}%" "critical" "system_disk_percent"
        else
            send_alert "High disk usage: ${disk_usage}%" "warning" "system_disk_percent"
        fi
    fi
    
    # 网络连接数
    local connections
    connections=$(get_network_connections)
    log_metric "system_connections" "$connections" "host=localhost"
    
    if [[ "$connections" -gt 1000 ]]; then
        send_alert "High network connections: $connections" "warning" "system_connections"
    fi
}

# 监控容器
monitor_containers() {
    log "Monitoring Docker containers"
    
    local containers=("online-time-app" "online-time-prometheus" "online-time-grafana" "online-time-redis")
    
    for container in "${containers[@]}"; do
        local stats
        stats=$(get_container_stats "$container")
        
        # 解析统计信息
        local container_status cpu_percent memory_percent memory_usage memory_limit
        eval "$stats"
        
        # 记录指标
        log_metric "container_status" "$container_status" "container=$container"
        log_metric "container_cpu_percent" "$cpu_percent" "container=$container"
        log_metric "container_memory_percent" "$memory_percent" "container=$container"
        log_metric "container_memory_usage" "$memory_usage" "container=$container"
        
        # 检查告警条件
        if [[ "$container_status" -eq 0 ]]; then
            send_alert "Container is not running: $container" "critical" "container_status"
        else
            if (( $(echo "$cpu_percent > 80" | bc -l) )); then
                send_alert "High CPU usage in container $container: ${cpu_percent}%" "warning" "container_cpu_percent"
            fi
            
            if (( $(echo "$memory_percent > 85" | bc -l) )); then
                send_alert "High memory usage in container $container: ${memory_percent}%" "warning" "container_memory_percent"
            fi
        fi
    done
}

# 监控HTTP服务
monitor_http_services() {
    log "Monitoring HTTP services"
    
    local services=(
        "http://localhost/health Online-Time-App"
        "http://localhost:9090/-/healthy Prometheus"
        "http://localhost:3000/api/health Grafana"
        "http://localhost:9093/-/healthy AlertManager"
    )
    
    for service_info in "${services[@]}"; do
        local url service_name
        url=$(echo "$service_info" | awk '{print $1}')
        service_name=$(echo "$service_info" | awk '{print $2}')
        
        # 检查HTTP状态
        local http_code
        http_code=$(check_http_status "$url")
        log_metric "http_status_code" "$http_code" "service=$service_name,url=$url"
        
        # 检查响应时间
        local response_time
        response_time=$(get_http_response_time "$url")
        log_metric "http_response_time" "$response_time" "service=$service_name,url=$url"
        
        # 告警检查
        if [[ "$http_code" != "200" ]]; then
            send_alert "HTTP service unavailable: $service_name (HTTP $http_code)" "critical" "http_status_code"
        elif (( $(echo "$response_time > 5.0" | bc -l) )); then
            send_alert "Slow HTTP response: $service_name (${response_time}s)" "warning" "http_response_time"
        fi
    done
}

# 监控日志文件大小
monitor_log_files() {
    log "Monitoring log files"
    
    local log_dir="$PROJECT_ROOT/logs"
    local max_size_mb=100
    
    if [[ -d "$log_dir" ]]; then
        while IFS= read -r -d '' logfile; do
            local size_mb
            size_mb=$(du -m "$logfile" | cut -f1)
            
            log_metric "log_file_size_mb" "$size_mb" "file=$(basename "$logfile")"
            
            if [[ "$size_mb" -gt "$max_size_mb" ]]; then
                send_alert "Large log file detected: $(basename "$logfile") (${size_mb}MB)" "warning" "log_file_size_mb"
            fi
        done < <(find "$log_dir" -name "*.log" -type f -print0 2>/dev/null || true)
    fi
}

# 生成监控报告
generate_report() {
    local report_file="$PROJECT_ROOT/logs/monitor_report_$(date +%Y%m%d_%H%M).txt"
    
    {
        echo "=== System Monitoring Report - $(date) ==="
        echo ""
        
        echo "System Resources:"
        echo "  CPU Usage: $(get_cpu_usage)%"
        echo "  Memory Usage: $(get_memory_usage)%"
        echo "  Disk Usage: $(get_disk_usage)%"
        echo "  Network Connections: $(get_network_connections)"
        echo ""
        
        echo "Docker Containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker not available"
        echo ""
        
        echo "Recent Alerts:"
        tail -n 10 "$LOG_FILE" | grep -E "(WARNING|ERROR|CRITICAL)" || echo "  No recent alerts"
        echo ""
        
        echo "Disk Usage by Directory:"
        du -sh "$PROJECT_ROOT"/{data,logs,node_modules} 2>/dev/null || echo "  Unable to calculate directory sizes"
        
    } > "$report_file"
    
    log "Monitoring report generated: $(basename "$report_file")"
}

# 清理过期日志
cleanup_logs() {
    local retention_days="${1:-7}"
    
    log "Cleaning up logs older than $retention_days days"
    
    local deleted_count=0
    
    # 清理监控日志
    while IFS= read -r -d '' logfile; do
        rm "$logfile"
        ((deleted_count++))
    done < <(find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +"$retention_days" -print0 2>/dev/null || true)
    
    # 清理报告文件
    while IFS= read -r -d '' reportfile; do
        rm "$reportfile"
        ((deleted_count++))
    done < <(find "$PROJECT_ROOT/logs" -name "*_report_*.txt" -type f -mtime +"$retention_days" -print0 2>/dev/null || true)
    
    log "Cleaned up $deleted_count old log files"
}

# 主监控流程
main() {
    local mode="${1:-full}"
    
    log "=== System Monitoring Started ($mode) ==="
    
    case "$mode" in
        "system")
            monitor_system
            ;;
        "containers")
            monitor_containers
            ;;
        "http")
            monitor_http_services
            ;;
        "logs")
            monitor_log_files
            ;;
        "cleanup")
            cleanup_logs "${2:-7}"
            ;;
        "report")
            generate_report
            ;;
        "full"|*)
            monitor_system
            monitor_containers
            monitor_http_services
            monitor_log_files
            generate_report
            ;;
    esac
    
    log "=== System Monitoring Completed ==="
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi