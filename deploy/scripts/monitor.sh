#!/bin/bash
# =================================
# 在线时间工具 - 性能监控脚本
# =================================

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${DEPLOY_DIR}/logs/monitor.log"
REPORT_DIR="${DEPLOY_DIR}/logs/reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 创建必要目录
mkdir -p "$REPORT_DIR"

# 日志函数
log() {
    echo -e "${TIMESTAMP} $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_metric() {
    log "${CYAN}[METRIC]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# 系统性能监控
monitor_system_performance() {
    log_info "收集系统性能指标..."
    
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    log_metric "CPU使用率: ${cpu_usage}%"
    
    # 内存使用情况
    local mem_info=$(free -h | grep -E "Mem:|Swap:")
    log_info "内存使用情况:"
    echo "$mem_info" | while read line; do
        log_metric "$line"
    done
    
    # 磁盘使用情况
    local disk_info=$(df -h | grep -vE '^Filesystem|tmpfs|cdrom')
    log_info "磁盘使用情况:"
    echo "$disk_info" | while read line; do
        log_metric "$line"
    done
    
    # 系统负载
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    log_metric "系统负载:$load_avg"
    
    # 网络连接统计
    local network_stats=$(ss -tuln | tail -n +2 | wc -l)
    log_metric "活动网络连接数: $network_stats"
}

# Docker容器性能监控
monitor_container_performance() {
    log_info "收集容器性能指标..."
    
    # 检查是否有容器在运行
    if ! docker ps -q > /dev/null 2>&1; then
        log_warning "无法访问Docker或没有运行的容器"
        return 1
    fi
    
    # 容器资源使用情况
    local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}")
    log_info "容器状态:"
    echo "$containers" | while read line; do
        if [[ "$line" != "NAMES"* ]]; then
            log_metric "$line"
        fi
    done
    
    # 详细的容器统计信息
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | while read line; do
        if [[ "$line" != "NAME"* ]]; then
            log_metric "容器资源: $line"
        fi
    done
    
    # 检查容器健康状态
    for container in $(docker ps --format "{{.Names}}"); do
        local health=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
        log_metric "容器健康状态 $container: $health"
    done
}

# 应用性能监控
monitor_application_performance() {
    log_info "收集应用性能指标..."
    
    # HTTP响应时间测试
    local endpoints=(
        "http://localhost/"
        "http://localhost/clock"
        "http://localhost/timer"
        "http://localhost/stopwatch"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local response_time=$(curl -w "%{time_total}" -s -o /dev/null --max-time 10 "$endpoint" 2>/dev/null || echo "timeout")
        local http_code=$(curl -w "%{http_code}" -s -o /dev/null --max-time 10 "$endpoint" 2>/dev/null || echo "000")
        
        if [ "$response_time" != "timeout" ]; then
            log_metric "端点 $endpoint: ${response_time}s (HTTP $http_code)"
        else
            log_warning "端点 $endpoint: 超时或无法访问"
        fi
    done
    
    # 检查HAProxy状态
    if curl -sf --max-time 5 "http://localhost:8404/stats;csv" > /dev/null 2>&1; then
        local haproxy_stats=$(curl -s --max-time 5 "http://localhost:8404/stats;csv" | grep -E "app-[0-9]+" | head -3)
        log_info "HAProxy后端状态:"
        echo "$haproxy_stats" | while read line; do
            local server=$(echo "$line" | cut -d',' -f2)
            local status=$(echo "$line" | cut -d',' -f18)
            local sessions=$(echo "$line" | cut -d',' -f5)
            log_metric "服务器 $server: 状态=$status, 会话数=$sessions"
        done
    else
        log_warning "无法获取HAProxy统计信息"
    fi
}

# 数据库性能监控
monitor_database_performance() {
    log_info "收集数据库性能指标..."
    
    # Redis监控
    local redis_containers=("online-time-redis-master" "online-time-redis-slave")
    
    for container in "${redis_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            local redis_info=$(docker exec "$container" redis-cli info memory 2>/dev/null | grep -E "used_memory_human|maxmemory_human")
            if [ -n "$redis_info" ]; then
                log_metric "Redis内存 ($container):"
                echo "$redis_info" | while read line; do
                    log_metric "  $line"
                done
            fi
            
            # Redis连接数
            local connections=$(docker exec "$container" redis-cli info clients 2>/dev/null | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
            if [ -n "$connections" ]; then
                log_metric "Redis连接数 ($container): $connections"
            fi
        else
            log_warning "Redis容器 $container 未运行"
        fi
    done
}

# 网络性能监控
monitor_network_performance() {
    log_info "收集网络性能指标..."
    
    # 网络接口统计
    local network_interfaces=$(ip -s link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/://')
    
    for interface in $network_interfaces; do
        if [ "$interface" != "lo" ]; then
            local stats=$(ip -s link show "$interface" | tail -2)
            log_metric "网络接口 $interface 统计:"
            echo "$stats" | while read line; do
                log_metric "  $line"
            done
        fi
    done
    
    # 端口监听状态
    local listening_ports=$(ss -tuln | grep LISTEN | wc -l)
    log_metric "监听端口数量: $listening_ports"
    
    # 重要端口检查
    local important_ports=(80 9090 3001 8404 6379)
    for port in "${important_ports[@]}"; do
        if ss -tuln | grep -q ":${port} "; then
            log_metric "端口 $port: 正在监听"
        else
            log_warning "端口 $port: 未监听"
        fi
    done
}

# 日志分析
analyze_logs() {
    log_info "分析日志文件..."
    
    local log_dirs=(
        "${DEPLOY_DIR}/logs"
        "/var/log/nginx"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # 统计错误日志
            local error_count=$(find "$log_dir" -name "*.log" -mmin -60 -exec grep -c "ERROR\|CRITICAL\|FATAL" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            log_metric "最近1小时错误日志 ($log_dir): $error_count"
            
            # 统计警告日志
            local warning_count=$(find "$log_dir" -name "*.log" -mmin -60 -exec grep -c "WARNING\|WARN" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            log_metric "最近1小时警告日志 ($log_dir): $warning_count"
            
            # 日志文件大小
            local log_size=$(du -sh "$log_dir" 2>/dev/null | cut -f1)
            log_metric "日志目录大小 ($log_dir): $log_size"
        fi
    done
    
    # Nginx访问日志分析
    local nginx_log="/var/log/nginx/access.log"
    if [ -f "$nginx_log" ]; then
        local requests_last_hour=$(awk -v date="$(date -d '1 hour ago' '+%d/%b/%Y:%H')" '$0 ~ date' "$nginx_log" | wc -l)
        log_metric "最近1小时HTTP请求数: $requests_last_hour"
        
        local status_codes=$(tail -1000 "$nginx_log" | awk '{print $9}' | sort | uniq -c | sort -nr | head -5)
        log_info "最近HTTP状态码统计:"
        echo "$status_codes" | while read line; do
            log_metric "  $line"
        done
    fi
}

# 生成性能报告
generate_performance_report() {
    local report_file="${REPORT_DIR}/performance-report-$(date +%Y%m%d-%H%M%S).json"
    
    # 收集基本系统信息
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    
    cat << EOF > "$report_file"
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "uptime": "$(uptime -p)",
    "system_metrics": {
        "cpu_usage_percent": $cpu_usage,
        "memory_usage_percent": $mem_usage,
        "disk_usage_percent": $disk_usage,
        "load_average": "$load_avg"
    },
    "docker_metrics": {
        "running_containers": $(docker ps -q | wc -l),
        "total_containers": $(docker ps -aq | wc -l),
        "images_count": $(docker images -q | wc -l)
    },
    "network_metrics": {
        "listening_ports": $(ss -tuln | grep LISTEN | wc -l),
        "established_connections": $(ss -tun | grep ESTAB | wc -l)
    },
    "application_status": {
        "nginx_running": $(docker ps | grep -q "online-time-nginx" && echo "true" || echo "false"),
        "app_instances": $(docker ps | grep -c "online-time-app" || echo "0"),
        "redis_running": $(docker ps | grep -q "online-time-redis" && echo "true" || echo "false")
    }
}
EOF
    
    log_info "性能报告已生成: $report_file"
}

# 实时监控模式
realtime_monitor() {
    local interval=${1:-5}
    log_info "开始实时监控模式 (间隔: ${interval}s，按Ctrl+C停止)"
    
    trap 'log_info "停止实时监控"; exit 0' INT
    
    while true; do
        clear
        echo -e "${BLUE}==================== 在线时间工具 - 实时监控 ====================${NC}"
        echo -e "${CYAN}更新时间: $(date)${NC}"
        echo
        
        # 系统概览
        echo -e "${GREEN}系统状态:${NC}"
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
        
        printf "  CPU: %6.1f%% | 内存: %6.1f%% | 磁盘: %3d%%\n" "$cpu_usage" "$mem_usage" "$disk_usage"
        echo
        
        # 容器状态
        echo -e "${GREEN}容器状态:${NC}"
        docker ps --format "  {{.Names}}: {{.Status}}" | head -10
        echo
        
        # 网络连接
        echo -e "${GREEN}网络状态:${NC}"
        local connections=$(ss -tun | grep ESTAB | wc -l)
        local listening=$(ss -tuln | grep LISTEN | wc -l)
        printf "  活动连接: %d | 监听端口: %d\n" "$connections" "$listening"
        echo
        
        sleep "$interval"
    done
}

# 性能基准测试
run_performance_benchmark() {
    log_info "运行性能基准测试..."
    
    local test_url="http://localhost/"
    local test_count=10
    local total_time=0
    local success_count=0
    
    for ((i=1; i<=test_count; i++)); do
        local response_time=$(curl -w "%{time_total}" -s -o /dev/null --max-time 5 "$test_url" 2>/dev/null || echo "0")
        local http_code=$(curl -w "%{http_code}" -s -o /dev/null --max-time 5 "$test_url" 2>/dev/null || echo "000")
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            total_time=$(echo "$total_time + $response_time" | bc)
            ((success_count++))
        fi
        
        echo -n "."
    done
    echo
    
    if [ $success_count -gt 0 ]; then
        local avg_time=$(echo "scale=3; $total_time / $success_count" | bc)
        local success_rate=$(echo "scale=2; $success_count * 100 / $test_count" | bc)
        
        log_metric "性能测试结果:"
        log_metric "  成功率: ${success_rate}%"
        log_metric "  平均响应时间: ${avg_time}s"
        log_metric "  总请求数: $test_count"
    else
        log_error "所有性能测试请求都失败了"
        return 1
    fi
}

# 主函数
main() {
    local mode=${1:-"report"}
    
    case $mode in
        "report")
            log_info "==================== 性能监控报告 ===================="
            monitor_system_performance
            monitor_container_performance
            monitor_application_performance
            monitor_database_performance
            monitor_network_performance
            analyze_logs
            generate_performance_report
            log_info "==================== 监控报告完成 ===================="
            ;;
        "realtime")
            realtime_monitor "${2:-5}"
            ;;
        "benchmark")
            run_performance_benchmark
            ;;
        "system")
            monitor_system_performance
            ;;
        "containers")
            monitor_container_performance
            ;;
        "app")
            monitor_application_performance
            ;;
        "network")
            monitor_network_performance
            ;;
        *)
            echo "用法: $0 [report|realtime|benchmark|system|containers|app|network]"
            echo "  report    - 生成完整性能报告 (默认)"
            echo "  realtime  - 实时监控模式"
            echo "  benchmark - 性能基准测试"
            echo "  system    - 仅监控系统性能"
            echo "  containers- 仅监控容器性能"
            echo "  app       - 仅监控应用性能"
            echo "  network   - 仅监控网络性能"
            exit 1
            ;;
    esac
}

# 检查依赖
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