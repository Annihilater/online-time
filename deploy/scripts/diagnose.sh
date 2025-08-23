#!/bin/bash
# =================================
# 在线时间工具 - 故障诊断脚本
# =================================

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${DEPLOY_DIR}/logs/diagnose.log"
REPORT_DIR="${DEPLOY_DIR}/logs/diagnose"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

log_debug() {
    log "${CYAN}[DEBUG]${NC} $1"
}

log_critical() {
    log "${MAGENTA}[CRITICAL]${NC} $1"
}

# 系统基础信息收集
collect_system_info() {
    log_info "收集系统基础信息..."
    
    local info_file="${REPORT_DIR}/system-info-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== 系统基础信息 ===================="
        echo "主机名: $(hostname)"
        echo "系统时间: $(date)"
        echo "运行时间: $(uptime)"
        echo "内核版本: $(uname -a)"
        echo
        
        echo "==================== CPU信息 ===================="
        lscpu 2>/dev/null || sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "CPU信息获取失败"
        echo
        
        echo "==================== 内存信息 ===================="
        free -h 2>/dev/null || vm_stat 2>/dev/null || echo "内存信息获取失败"
        echo
        
        echo "==================== 磁盘信息 ===================="
        df -h
        echo
        
        echo "==================== 网络接口信息 ===================="
        ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "网络接口信息获取失败"
        echo
        
        echo "==================== 进程信息 ===================="
        ps aux | head -20
        echo
        
        echo "==================== 网络连接 ===================="
        ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null || echo "网络连接信息获取失败"
        echo
        
    } > "$info_file"
    
    log_success "系统信息已保存到: $info_file"
}

# Docker环境诊断
diagnose_docker_environment() {
    log_info "诊断Docker环境..."
    
    local docker_file="${REPORT_DIR}/docker-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== Docker版本信息 ===================="
        docker --version
        docker-compose --version
        echo
        
        echo "==================== Docker系统信息 ===================="
        docker system info
        echo
        
        echo "==================== Docker磁盘使用 ===================="
        docker system df
        echo
        
        echo "==================== 运行中的容器 ===================="
        docker ps -a
        echo
        
        echo "==================== 容器详细状态 ===================="
        for container in $(docker ps --format "{{.Names}}"); do
            echo "--- 容器: $container ---"
            docker inspect "$container" | jq '.[] | {
                State: .State,
                NetworkSettings: .NetworkSettings.Networks,
                Mounts: .Mounts,
                RestartCount: .RestartCount,
                LogPath: .LogPath
            }' 2>/dev/null || docker inspect "$container"
            echo
        done
        
        echo "==================== 容器资源使用 ===================="
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"
        echo
        
        echo "==================== Docker网络 ===================="
        docker network ls
        for network in $(docker network ls --format "{{.Name}}" | grep -v bridge | grep -v host | grep -v none); do
            echo "--- 网络: $network ---"
            docker network inspect "$network"
            echo
        done
        
        echo "==================== Docker卷 ===================="
        docker volume ls
        echo
        
        echo "==================== Docker镜像 ===================="
        docker images
        echo
        
    } > "$docker_file"
    
    log_success "Docker诊断信息已保存到: $docker_file"
}

# 应用服务诊断
diagnose_application_services() {
    log_info "诊断应用服务..."
    
    local app_file="${REPORT_DIR}/application-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== 应用服务状态检查 ===================="
        
        # 检查主要端点
        local endpoints=(
            "http://localhost/"
            "http://localhost/health"
            "http://localhost/clock"
            "http://localhost/timer"
            "http://localhost/stopwatch"
            "http://localhost/alarm"
        )
        
        for endpoint in "${endpoints[@]}"; do
            echo "检查端点: $endpoint"
            local response=$(curl -w "HTTP状态: %{http_code} | 响应时间: %{time_total}s | 大小: %{size_download}bytes" -s -o /dev/null --max-time 10 "$endpoint" 2>&1)
            echo "结果: $response"
            echo
        done
        
        echo "==================== HAProxy状态 ===================="
        if curl -sf --max-time 5 "http://localhost:8404/stats" > /dev/null 2>&1; then
            echo "HAProxy统计页面可访问"
            curl -s --max-time 5 "http://localhost:8404/stats;csv" | head -10
        else
            echo "HAProxy统计页面不可访问"
        fi
        echo
        
        echo "==================== Nginx状态 ===================="
        if docker exec online-time-nginx nginx -t 2>&1; then
            echo "Nginx配置验证通过"
        else
            echo "Nginx配置验证失败"
        fi
        echo
        
        # 检查Nginx进程
        docker exec online-time-nginx ps aux | grep nginx || echo "无法获取Nginx进程信息"
        echo
        
        echo "==================== 应用容器日志 (最近50行) ===================="
        for container in $(docker ps --format "{{.Names}}" | grep "app"); do
            echo "--- $container 日志 ---"
            docker logs --tail=50 "$container" 2>&1 | tail -20
            echo
        done
        
    } > "$app_file"
    
    log_success "应用诊断信息已保存到: $app_file"
}

# 网络诊断
diagnose_network() {
    log_info "诊断网络连接..."
    
    local network_file="${REPORT_DIR}/network-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== 网络连通性测试 ===================="
        
        # 本地回环测试
        echo "本地回环测试:"
        ping -c 3 127.0.0.1 2>&1 || echo "本地回环测试失败"
        echo
        
        # DNS解析测试
        echo "DNS解析测试:"
        nslookup google.com 2>&1 || echo "DNS解析测试失败"
        echo
        
        # 外网连通性测试
        echo "外网连通性测试:"
        curl -I --max-time 10 http://httpbin.org/ip 2>&1 || echo "外网连通性测试失败"
        echo
        
        # 端口连通性测试
        echo "关键端口连通性测试:"
        local ports=(80 8404 9090 3001 6379)
        for port in "${ports[@]}"; do
            if nc -z localhost "$port" 2>/dev/null; then
                echo "端口 $port: 开放"
            else
                echo "端口 $port: 关闭或无法访问"
            fi
        done
        echo
        
        echo "==================== 网络路由信息 ===================="
        route -n 2>/dev/null || netstat -rn 2>/dev/null || echo "路由信息获取失败"
        echo
        
        echo "==================== 防火墙状态 ===================="
        ufw status 2>/dev/null || iptables -L -n 2>/dev/null | head -20 || echo "防火墙状态获取失败"
        echo
        
        echo "==================== Docker网络连通性 ===================="
        # 测试容器间网络
        if docker ps --format "{{.Names}}" | grep -q "app-1"; then
            echo "容器间网络测试:"
            docker exec online-time-app-1 wget -q --timeout=5 --spider http://online-time-haproxy:8404/stats 2>&1 && echo "app-1 -> haproxy: 成功" || echo "app-1 -> haproxy: 失败"
            docker exec online-time-app-1 redis-cli -h online-time-redis-master ping 2>&1 | head -1
        fi
        echo
        
    } > "$network_file"
    
    log_success "网络诊断信息已保存到: $network_file"
}

# 日志分析诊断
diagnose_logs() {
    log_info "分析日志文件..."
    
    local log_analysis_file="${REPORT_DIR}/log-analysis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== 错误日志分析 ===================="
        
        # 应用容器错误日志
        echo "应用容器错误日志 (最近100条):"
        for container in $(docker ps --format "{{.Names}}" | grep -E "(app|nginx|haproxy)"); do
            echo "--- $container 错误日志 ---"
            docker logs --tail=100 "$container" 2>&1 | grep -i error | tail -10 || echo "无错误日志"
            echo
        done
        
        echo "==================== 系统日志分析 ===================="
        
        # 分析nginx日志
        if [ -f "/var/log/nginx/error.log" ]; then
            echo "Nginx错误日志 (最近20条):"
            tail -20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取Nginx错误日志"
            echo
        fi
        
        # 分析应用日志目录
        if [ -d "${DEPLOY_DIR}/logs" ]; then
            echo "应用日志目录分析:"
            find "${DEPLOY_DIR}/logs" -name "*.log" -mtime -1 -exec echo "文件: {}" \; -exec tail -10 {} \; -exec echo "---" \; 2>/dev/null | head -50
            echo
        fi
        
        echo "==================== 日志统计信息 ===================="
        
        # 错误级别统计
        echo "最近24小时错误级别统计:"
        for container in $(docker ps --format "{{.Names}}"); do
            local errors=$(docker logs --since="24h" "$container" 2>&1 | grep -ic error 2>/dev/null || echo 0)
            local warnings=$(docker logs --since="24h" "$container" 2>&1 | grep -ic warning 2>/dev/null || echo 0)
            echo "$container: ERRORS=$errors, WARNINGS=$warnings"
        done
        echo
        
        # 日志文件大小
        echo "日志文件大小:"
        du -sh "${DEPLOY_DIR}/logs"/* 2>/dev/null | sort -hr | head -10 || echo "无应用日志文件"
        echo
        
        # Docker日志大小
        echo "Docker容器日志大小:"
        for container in $(docker ps --format "{{.Names}}"); do
            local log_path=$(docker inspect --format='{{.LogPath}}' "$container" 2>/dev/null)
            if [ -f "$log_path" ]; then
                local size=$(du -sh "$log_path" | cut -f1)
                echo "$container: $size"
            fi
        done
        echo
        
    } > "$log_analysis_file"
    
    log_success "日志分析结果已保存到: $log_analysis_file"
}

# 性能瓶颈诊断
diagnose_performance_bottlenecks() {
    log_info "诊断性能瓶颈..."
    
    local perf_file="${REPORT_DIR}/performance-bottlenecks-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== CPU性能分析 ===================="
        
        # CPU使用率前10进程
        echo "CPU使用率前10进程:"
        ps aux --sort=-%cpu | head -11
        echo
        
        # CPU负载历史
        echo "系统负载:"
        uptime
        echo
        
        echo "==================== 内存性能分析 ===================="
        
        # 内存使用率前10进程
        echo "内存使用率前10进程:"
        ps aux --sort=-%mem | head -11
        echo
        
        # 内存详细信息
        echo "内存详细信息:"
        free -m
        echo
        
        # 交换空间使用情况
        echo "交换空间使用情况:"
        swapon -s 2>/dev/null || echo "无交换空间或无法获取信息"
        echo
        
        echo "==================== 磁盘I/O分析 ===================="
        
        # 磁盘使用情况
        echo "磁盘使用情况:"
        df -h
        echo
        
        # I/O统计 (如果可用)
        echo "磁盘I/O统计:"
        iostat -x 1 3 2>/dev/null | tail -20 || echo "iostat不可用"
        echo
        
        echo "==================== 网络性能分析 ===================="
        
        # 网络连接统计
        echo "网络连接统计:"
        ss -s 2>/dev/null || netstat -s 2>/dev/null | head -20 || echo "网络统计不可用"
        echo
        
        # 活动连接
        echo "活动网络连接 (前20个):"
        ss -tunp 2>/dev/null | head -20 || netstat -tunp 2>/dev/null | head -20 || echo "网络连接信息不可用"
        echo
        
        echo "==================== Docker性能分析 ===================="
        
        # 容器资源使用
        echo "容器资源使用情况:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
        echo
        
        # 容器进程
        for container in $(docker ps --format "{{.Names}}" | head -5); do
            echo "--- $container 进程信息 ---"
            docker exec "$container" ps aux 2>/dev/null | head -10 || echo "无法获取进程信息"
            echo
        done
        
        echo "==================== 应用响应时间测试 ===================="
        
        # 响应时间测试
        echo "应用响应时间测试:"
        for i in {1..5}; do
            local response_time=$(curl -w "%{time_total}" -s -o /dev/null --max-time 10 "http://localhost/" 2>/dev/null || echo "timeout")
            echo "测试 $i: ${response_time}s"
        done
        echo
        
    } > "$perf_file"
    
    log_success "性能瓶颈分析已保存到: $perf_file"
}

# 配置文件诊断
diagnose_configuration() {
    log_info "诊断配置文件..."
    
    local config_file="${REPORT_DIR}/configuration-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "==================== 配置文件检查 ===================="
        
        # Docker Compose文件
        echo "Docker Compose配置验证:"
        cd "$DEPLOY_DIR"
        docker-compose -f docker-compose.ha.yml config --quiet 2>&1 && echo "HA配置文件有效" || echo "HA配置文件有错误"
        docker-compose -f docker-compose.prod.yml config --quiet 2>&1 && echo "生产配置文件有效" || echo "生产配置文件有错误"
        echo
        
        # Nginx配置
        echo "Nginx配置验证:"
        docker exec online-time-nginx nginx -t 2>&1 || echo "Nginx配置测试失败"
        echo
        
        # HAProxy配置
        echo "HAProxy配置检查:"
        docker exec online-time-haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg 2>&1 || echo "HAProxy配置测试失败"
        echo
        
        # 环境变量
        echo "环境变量配置:"
        if [ -f "${DEPLOY_DIR}/.env.prod" ]; then
            echo "生产环境变量文件存在"
            grep -v "^#\|^$" "${DEPLOY_DIR}/.env.prod" | wc -l | xargs echo "配置项数量:"
        else
            echo "生产环境变量文件不存在"
        fi
        echo
        
        # 服务访问配置
        echo "服务访问配置:"
        echo "服务仅支持HTTP访问，如需HTTPS请使用外部反向代理"
        echo
        
        # 监控配置
        echo "监控配置检查:"
        if [ -f "${DEPLOY_DIR}/config/prometheus.yml" ]; then
            echo "Prometheus配置文件存在"
            docker exec online-time-prometheus promtool check config /etc/prometheus/prometheus.yml 2>&1 || echo "Prometheus配置验证失败"
        fi
        echo
        
    } > "$config_file"
    
    log_success "配置诊断信息已保存到: $config_file"
}

# 生成综合诊断报告
generate_diagnosis_summary() {
    log_info "生成综合诊断报告..."
    
    local summary_file="${REPORT_DIR}/diagnosis-summary-$(date +%Y%m%d-%H%M%S).html"
    
    cat << 'EOF' > "$summary_file"
<!DOCTYPE html>
<html>
<head>
    <title>在线时间工具 - 故障诊断报告</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { background: #d4edda; border-color: #c3e6cb; }
        .warning { background: #fff3cd; border-color: #ffeaa7; }
        .error { background: #f8d7da; border-color: #f5c6cb; }
        .info { background: #e2e3e5; border-color: #d6d8db; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>在线时间工具 - 故障诊断报告</h1>
        <p>生成时间: $(date)</p>
        <p>主机名: $(hostname)</p>
    </div>
EOF
    
    # 添加系统概览
    cat << EOF >> "$summary_file"
    <div class="section info">
        <h2>系统概览</h2>
        <table>
            <tr><th>项目</th><th>状态</th><th>详情</th></tr>
            <tr>
                <td>系统运行时间</td>
                <td>$(uptime -p)</td>
                <td>$(uptime)</td>
            </tr>
            <tr>
                <td>Docker状态</td>
                <td>$(docker --version)</td>
                <td>运行容器: $(docker ps -q | wc -l)</td>
            </tr>
            <tr>
                <td>CPU使用率</td>
                <td>$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')%</td>
                <td>$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "N/A") 核心</td>
            </tr>
            <tr>
                <td>内存使用率</td>
                <td>$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%</td>
                <td>$(free -h | grep Mem | awk '{print $3"/"$2}')</td>
            </tr>
            <tr>
                <td>磁盘使用率</td>
                <td>$(df / | grep -vE '^Filesystem' | awk '{print $5}')%</td>
                <td>$(df -h / | grep -vE '^Filesystem' | awk '{print $3"/"$2}')</td>
            </tr>
        </table>
    </div>
EOF
    
    # 添加容器状态
    cat << EOF >> "$summary_file"
    <div class="section">
        <h2>容器状态</h2>
        <pre>$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")</pre>
    </div>
    
    <div class="section">
        <h2>服务可用性测试</h2>
        <table>
            <tr><th>服务</th><th>状态</th><th>响应时间</th></tr>
EOF
    
    # 测试关键服务
    local services=(
        "http://localhost/,主页"
        "http://localhost/health,健康检查"
        "http://localhost:8404/stats,HAProxy统计"
        "http://localhost:9090/-/healthy,Prometheus"
        "http://localhost:3001/api/health,Grafana"
    )
    
    for service in "${services[@]}"; do
        local url=$(echo "$service" | cut -d',' -f1)
        local name=$(echo "$service" | cut -d',' -f2)
        local status_class="error"
        local status="❌ 不可用"
        local response_time="N/A"
        
        if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
            status_class="success"
            status="✅ 正常"
            response_time=$(curl -w "%{time_total}s" -s -o /dev/null --max-time 5 "$url" 2>/dev/null || echo "N/A")
        fi
        
        echo "            <tr class=\"$status_class\"><td>$name</td><td>$status</td><td>$response_time</td></tr>" >> "$summary_file"
    done
    
    cat << EOF >> "$summary_file"
        </table>
    </div>
    
    <div class="section">
        <h2>最近错误日志</h2>
        <pre>
EOF
    
    # 添加最近的错误日志
    echo "Docker容器错误日志:" >> "$summary_file"
    for container in $(docker ps --format "{{.Names}}" | head -5); do
        echo "--- $container ---" >> "$summary_file"
        docker logs --tail=5 "$container" 2>&1 | grep -i error | head -3 >> "$summary_file" 2>/dev/null || echo "无错误日志" >> "$summary_file"
        echo >> "$summary_file"
    done
    
    cat << EOF >> "$summary_file"
        </pre>
    </div>
    
    <div class="section info">
        <h2>建议操作</h2>
        <ul>
            <li>检查所有诊断文件：<code>ls -la $REPORT_DIR/</code></li>
            <li>查看详细日志：<code>docker logs [container_name]</code></li>
            <li>重启异常服务：<code>docker restart [container_name]</code></li>
            <li>查看资源使用：<code>docker stats</code></li>
            <li>更新配置后重载：<code>./deploy.sh</code></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>相关文件</h2>
        <ul>
EOF
    
    # 列出生成的诊断文件
    for file in "${REPORT_DIR}"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local filesize=$(du -h "$file" | cut -f1)
            echo "            <li><strong>$filename</strong> ($filesize)</li>" >> "$summary_file"
        fi
    done
    
    cat << 'EOF' >> "$summary_file"
        </ul>
    </div>
    
    <div class="section info">
        <h2>联系信息</h2>
        <p>如果问题持续存在，请联系系统管理员并提供以下信息：</p>
        <ul>
            <li>此诊断报告的所有文件</li>
            <li>问题出现的具体时间</li>
            <li>用户操作步骤</li>
            <li>错误截图（如有）</li>
        </ul>
    </div>
</body>
</html>
EOF
    
    log_success "综合诊断报告已生成: $summary_file"
    log_info "可以用浏览器打开查看: file://$summary_file"
}

# 快速诊断模式
quick_diagnosis() {
    log_info "执行快速诊断..."
    
    # 检查关键服务状态
    local issues=0
    
    # Docker服务
    if ! docker ps > /dev/null 2>&1; then
        log_error "Docker服务不可用"
        ((issues++))
    else
        log_success "Docker服务正常"
    fi
    
    # 主要容器
    local key_containers=("online-time-nginx" "online-time-haproxy")
    for container in "${key_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            log_success "容器 $container 运行正常"
        else
            log_error "容器 $container 未运行"
            ((issues++))
        fi
    done
    
    # 主要端点
    local key_endpoints=("http://localhost/" "http://localhost:8404/stats")
    for endpoint in "${key_endpoints[@]}"; do
        if curl -sf --max-time 5 "$endpoint" > /dev/null 2>&1; then
            log_success "端点 $endpoint 正常"
        else
            log_error "端点 $endpoint 不可访问"
            ((issues++))
        fi
    done
    
    # 系统资源检查
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
    
    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        log_warning "CPU使用率过高: ${cpu_usage}%"
        ((issues++))
    fi
    
    if [ "$mem_usage" -gt 90 ]; then
        log_warning "内存使用率过高: ${mem_usage}%"
        ((issues++))
    fi
    
    if [ "$disk_usage" -gt 95 ]; then
        log_error "磁盘空间严重不足: ${disk_usage}%"
        ((issues++))
    fi
    
    # 总结
    if [ $issues -eq 0 ]; then
        log_success "快速诊断完成，未发现严重问题"
        return 0
    else
        log_warning "快速诊断发现 $issues 个问题，建议运行完整诊断"
        return 1
    fi
}

# 主函数
main() {
    local mode=${1:-"full"}
    
    log_info "==================== 开始故障诊断 ===================="
    
    case $mode in
        "quick")
            quick_diagnosis
            ;;
        "system")
            collect_system_info
            ;;
        "docker")
            diagnose_docker_environment
            ;;
        "app")
            diagnose_application_services
            ;;
        "network")
            diagnose_network
            ;;
        "logs")
            diagnose_logs
            ;;
        "performance")
            diagnose_performance_bottlenecks
            ;;
        "config")
            diagnose_configuration
            ;;
        "full"|*)
            log_info "执行完整诊断..."
            collect_system_info
            diagnose_docker_environment
            diagnose_application_services
            diagnose_network
            diagnose_logs
            diagnose_performance_bottlenecks
            diagnose_configuration
            generate_diagnosis_summary
            log_info "完整诊断完成，所有报告保存在: $REPORT_DIR"
            ;;
    esac
    
    log_info "==================== 故障诊断完成 ===================="
}

# 使用说明
show_usage() {
    echo "用法: $0 [模式]"
    echo
    echo "诊断模式:"
    echo "  full        - 完整诊断 (默认)"
    echo "  quick       - 快速诊断"
    echo "  system      - 系统信息收集"
    echo "  docker      - Docker环境诊断"
    echo "  app         - 应用服务诊断"
    echo "  network     - 网络诊断"
    echo "  logs        - 日志分析"
    echo "  performance - 性能瓶颈诊断"
    echo "  config      - 配置文件诊断"
    echo
    echo "所有诊断报告将保存在: $REPORT_DIR"
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
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_usage
        exit 0
    fi
    
    check_dependencies
    main "$@"
fi