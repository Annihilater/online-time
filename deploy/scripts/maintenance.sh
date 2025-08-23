#!/bin/bash
# =================================
# 在线时间工具 - 系统维护脚本
# =================================

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${DEPLOY_DIR}/logs/maintenance.log"
MAINTENANCE_LOCK="/tmp/online-time-maintenance.lock"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
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

# 创建维护锁
create_maintenance_lock() {
    if [ -f "$MAINTENANCE_LOCK" ]; then
        local lock_pid=$(cat "$MAINTENANCE_LOCK" 2>/dev/null || echo "")
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "维护任务已在运行 (PID: $lock_pid)"
            exit 1
        else
            log_warning "发现旧的维护锁文件，已清理"
            rm -f "$MAINTENANCE_LOCK"
        fi
    fi
    
    echo $$ > "$MAINTENANCE_LOCK"
    trap 'rm -f "$MAINTENANCE_LOCK"; exit' INT TERM EXIT
}

# 日常维护任务
daily_maintenance() {
    log_info "==================== 开始日常维护 ===================="
    
    # 清理临时文件
    cleanup_temp_files
    
    # Docker系统清理
    docker_system_cleanup
    
    # 日志文件整理
    organize_log_files
    
    # 检查磁盘空间
    check_disk_space
    
    # 验证服务状态
    verify_services_status
    
    # 更新运行统计
    update_runtime_stats
    
    log_info "==================== 日常维护完成 ===================="
}

# 周维护任务
weekly_maintenance() {
    log_info "==================== 开始周维护 ===================="
    
    # 执行日常维护
    daily_maintenance
    
    # 深度Docker清理
    docker_deep_cleanup
    
    # 压缩旧日志文件
    compress_old_logs
    
    # 系统性能分析
    analyze_system_performance
    
    # 安全检查
    security_health_check
    
    # 备份验证
    verify_backups
    
    # 生成周报
    generate_weekly_report
    
    log_info "==================== 周维护完成 ===================="
}

# 月维护任务
monthly_maintenance() {
    log_info "==================== 开始月维护 ===================="
    
    # 执行周维护
    weekly_maintenance
    
    # 系统更新检查
    check_system_updates
    
    # Docker镜像更新检查
    check_image_updates
    
    # 长期数据归档
    archive_old_data
    
    # 配置文件备份
    backup_configurations
    
    # 性能优化建议
    generate_optimization_recommendations
    
    # 生成月报
    generate_monthly_report
    
    log_info "==================== 月维护完成 ===================="
}

# 清理临时文件
cleanup_temp_files() {
    log_info "清理临时文件..."
    
    # 清理系统临时文件
    local temp_dirs=("/tmp" "/var/tmp")
    local files_cleaned=0
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [ -d "$temp_dir" ]; then
            # 清理在线时间工具相关临时文件
            find "$temp_dir" -name "online-time-*" -mtime +1 -delete 2>/dev/null && ((files_cleaned++)) || true
            find "$temp_dir" -name "*.tmp" -user "$(whoami)" -mtime +1 -delete 2>/dev/null && ((files_cleaned++)) || true
        fi
    done
    
    # 清理应用临时文件
    if [ -d "${DEPLOY_DIR}/tmp" ]; then
        find "${DEPLOY_DIR}/tmp" -type f -mtime +1 -delete 2>/dev/null && ((files_cleaned++)) || true
        log_info "清理应用临时目录"
    fi
    
    # 清理旧的诊断文件
    if [ -d "${DEPLOY_DIR}/logs/diagnose" ]; then
        find "${DEPLOY_DIR}/logs/diagnose" -name "*.txt" -mtime +7 -delete && ((files_cleaned++)) || true
        find "${DEPLOY_DIR}/logs/diagnose" -name "*.html" -mtime +7 -delete && ((files_cleaned++)) || true
    fi
    
    log_success "临时文件清理完成，处理了 $files_cleaned 个文件/目录"
}

# Docker系统清理
docker_system_cleanup() {
    log_info "执行Docker系统清理..."
    
    # 清理未使用的容器、网络、镜像和构建缓存
    local cleanup_output=$(docker system prune -f --volumes 2>&1)
    log_info "Docker清理结果: $cleanup_output"
    
    # 清理悬空镜像
    local dangling_images=$(docker images -f "dangling=true" -q | wc -l)
    if [ "$dangling_images" -gt 0 ]; then
        docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true
        log_info "清理了 $dangling_images 个悬空镜像"
    fi
    
    # 显示清理后的磁盘使用情况
    local disk_usage=$(docker system df)
    log_info "Docker磁盘使用情况:\n$disk_usage"
}

# 深度Docker清理
docker_deep_cleanup() {
    log_info "执行深度Docker清理..."
    
    # 停止所有非关键容器进行清理
    log_warning "准备执行深度清理，某些服务可能短暂中断"
    
    # 清理所有停止的容器
    local stopped_containers=$(docker ps -aq -f status=exited | wc -l)
    if [ "$stopped_containers" -gt 0 ]; then
        docker rm $(docker ps -aq -f status=exited) 2>/dev/null || true
        log_info "清理了 $stopped_containers 个停止的容器"
    fi
    
    # 清理所有未使用的镜像
    docker image prune -a -f
    
    # 清理所有未使用的卷
    docker volume prune -f
    
    # 清理所有未使用的网络
    docker network prune -f
    
    log_success "深度Docker清理完成"
}

# 整理日志文件
organize_log_files() {
    log_info "整理日志文件..."
    
    local log_dirs=(
        "${DEPLOY_DIR}/logs"
        "${DEPLOY_DIR}/logs/cron"
        "${DEPLOY_DIR}/logs/diagnose"
        "${DEPLOY_DIR}/logs/reports"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # 创建按日期分类的目录结构
            local today=$(date +%Y-%m)
            local archive_dir="${log_dir}/archive/${today}"
            mkdir -p "$archive_dir"
            
            # 移动7天前的日志到归档目录
            find "$log_dir" -maxdepth 1 -name "*.log" -mtime +7 -exec mv {} "$archive_dir/" \; 2>/dev/null || true
            
            # 统计日志文件数量和大小
            local log_count=$(find "$log_dir" -name "*.log" | wc -l)
            local log_size=$(du -sh "$log_dir" 2>/dev/null | cut -f1)
            log_info "$log_dir: $log_count 个日志文件，总大小 $log_size"
        fi
    done
}

# 压缩旧日志文件
compress_old_logs() {
    log_info "压缩旧日志文件..."
    
    local compressed=0
    
    # 压缩7天前的日志文件
    find "${DEPLOY_DIR}/logs" -name "*.log" -mtime +7 -exec gzip {} \; && ((compressed++)) || true
    
    # 压缩归档目录中的文件
    find "${DEPLOY_DIR}/logs/archive" -name "*.log" -exec gzip {} \; 2>/dev/null && ((compressed++)) || true
    
    log_success "日志压缩完成，处理了 $compressed 个文件"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间使用情况..."
    
    # 检查根分区
    local root_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
    if [ "$root_usage" -gt 90 ]; then
        log_error "根分区磁盘空间严重不足: ${root_usage}%"
        # 尝试清理一些空间
        cleanup_emergency_space
    elif [ "$root_usage" -gt 80 ]; then
        log_warning "根分区磁盘使用率较高: ${root_usage}%"
    else
        log_success "根分区磁盘空间正常: ${root_usage}%"
    fi
    
    # 检查重要目录的磁盘使用情况
    local important_dirs=(
        "${DEPLOY_DIR}"
        "/var/log"
        "/tmp"
    )
    
    for dir in "${important_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local dir_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            log_info "目录 $dir 使用空间: $dir_size"
        fi
    done
}

# 紧急空间清理
cleanup_emergency_space() {
    log_warning "执行紧急空间清理..."
    
    # 清理APT缓存
    apt-get clean 2>/dev/null || yum clean all 2>/dev/null || true
    
    # 清理Docker日志
    truncate -s 0 $(docker inspect --format='{{.LogPath}}' $(docker ps -aq)) 2>/dev/null || true
    
    # 清理旧的内核
    apt-get autoremove -y 2>/dev/null || true
    
    # 清理用户缓存
    rm -rf ~/.cache/* 2>/dev/null || true
    
    log_info "紧急空间清理完成"
}

# 验证服务状态
verify_services_status() {
    log_info "验证服务状态..."
    
    # 检查关键容器
    local critical_containers=(
        "online-time-app-1"
        "online-time-nginx"
        "online-time-haproxy"
    )
    
    local failed_services=0
    
    for container in "${critical_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            if [ "$health" = "healthy" ] || [ "$health" = "no-healthcheck" ]; then
                log_success "容器 $container 运行正常"
            else
                log_error "容器 $container 健康检查失败"
                ((failed_services++))
            fi
        else
            log_error "容器 $container 未运行"
            ((failed_services++))
        fi
    done
    
    # 检查关键端点
    local endpoints=(
        "http://localhost/"
        "http://localhost:8404/stats"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -sf --max-time 5 "$endpoint" > /dev/null 2>&1; then
            log_success "端点 $endpoint 正常"
        else
            log_error "端点 $endpoint 无法访问"
            ((failed_services++))
        fi
    done
    
    if [ $failed_services -eq 0 ]; then
        log_success "所有关键服务运行正常"
    else
        log_warning "发现 $failed_services 个服务异常，建议执行诊断"
    fi
}

# 更新运行统计
update_runtime_stats() {
    log_info "更新运行统计信息..."
    
    local stats_file="${DEPLOY_DIR}/logs/runtime-stats.json"
    local uptime_seconds=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo "0")
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    
    cat << EOF > "$stats_file"
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "uptime_seconds": $uptime_seconds,
    "uptime_human": "$(uptime -p 2>/dev/null || echo 'unknown')",
    "load_average": "$load_avg",
    "running_containers": $(docker ps -q | wc -l),
    "docker_images": $(docker images -q | wc -l),
    "docker_volumes": $(docker volume ls -q | wc -l),
    "log_files_count": $(find "${DEPLOY_DIR}/logs" -name "*.log" | wc -l),
    "log_directory_size": "$(du -sh "${DEPLOY_DIR}/logs" | cut -f1)",
    "maintenance_last_run": "$(date -Iseconds)"
}
EOF
    
    log_success "运行统计已更新: $stats_file"
}

# 系统性能分析
analyze_system_performance() {
    log_info "分析系统性能..."
    
    local perf_report="${DEPLOY_DIR}/logs/reports/performance-analysis-$(date +%Y%m%d).txt"
    mkdir -p "$(dirname "$perf_report")"
    
    {
        echo "==================== 系统性能分析报告 ===================="
        echo "生成时间: $(date)"
        echo "主机名: $(hostname)"
        echo
        
        echo "CPU使用情况:"
        top -bn1 | head -20
        echo
        
        echo "内存使用情况:"
        free -h
        echo
        
        echo "磁盘I/O统计:"
        iostat -x 1 3 2>/dev/null | tail -10 || echo "iostat不可用"
        echo
        
        echo "网络连接统计:"
        ss -s 2>/dev/null || netstat -s 2>/dev/null | head -10 || echo "网络统计不可用"
        echo
        
        echo "进程资源使用TOP 10:"
        ps aux --sort=-%cpu | head -11
        echo
        
        echo "Docker容器资源使用:"
        docker stats --no-stream
        
    } > "$perf_report"
    
    log_success "性能分析报告已生成: $perf_report"
}

# 安全健康检查
security_health_check() {
    log_info "执行安全健康检查..."
    
    local security_report="${DEPLOY_DIR}/logs/reports/security-check-$(date +%Y%m%d).txt"
    mkdir -p "$(dirname "$security_report")"
    
    {
        echo "==================== 安全健康检查报告 ===================="
        echo "生成时间: $(date)"
        echo
        
        echo "开放端口检查:"
        ss -tuln | grep LISTEN || netstat -tuln | grep LISTEN
        echo
        
        echo "最近登录尝试:"
        last | head -10 2>/dev/null || echo "无法获取登录记录"
        echo
        
        echo "失败的认证尝试:"
        grep -i "failed" /var/log/auth.log 2>/dev/null | tail -5 || echo "无失败认证记录"
        echo
        
        echo "Docker安全检查:"
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedSince}}" | head -10
        echo
        
        echo "服务配置检查:"
        echo "服务仅支持HTTP访问，如需HTTPS请使用外部反向代理"
        
    } > "$security_report"
    
    log_success "安全检查报告已生成: $security_report"
}

# 验证备份
verify_backups() {
    log_info "验证备份完整性..."
    
    local backup_dir="${DEPLOY_DIR}/data/backups"
    if [ -d "$backup_dir" ]; then
        local backup_count=$(find "$backup_dir" -name "*.tar.gz" -mtime -7 | wc -l)
        local latest_backup=$(find "$backup_dir" -name "*.tar.gz" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ "$backup_count" -gt 0 ]; then
            log_success "发现 $backup_count 个最近7天的备份文件"
            if [ -n "$latest_backup" ]; then
                local backup_size=$(du -sh "$latest_backup" | cut -f1)
                log_info "最新备份: $(basename "$latest_backup") ($backup_size)"
                
                # 简单验证备份文件完整性
                if tar -tzf "$latest_backup" >/dev/null 2>&1; then
                    log_success "最新备份文件完整性验证通过"
                else
                    log_error "最新备份文件可能已损坏"
                fi
            fi
        else
            log_warning "未发现最近的备份文件"
        fi
    else
        log_warning "备份目录不存在: $backup_dir"
    fi
}

# 检查系统更新
check_system_updates() {
    log_info "检查系统更新..."
    
    local updates_available=0
    
    # 检查APT更新
    if command -v apt &> /dev/null; then
        apt update >/dev/null 2>&1 || true
        updates_available=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
        log_info "APT可用更新: $updates_available 个"
    fi
    
    # 检查YUM更新
    if command -v yum &> /dev/null; then
        updates_available=$(yum check-update 2>/dev/null | grep -c '^\w' || echo 0)
        log_info "YUM可用更新: $updates_available 个"
    fi
    
    # 检查Docker更新
    local current_docker=$(docker --version | awk '{print $3}' | sed 's/,//')
    log_info "当前Docker版本: $current_docker"
    
    if [ "$updates_available" -gt 0 ]; then
        log_warning "发现 $updates_available 个可用系统更新"
        log_info "建议在维护窗口期间执行更新: apt upgrade 或 yum update"
    else
        log_success "系统已是最新版本"
    fi
}

# 检查Docker镜像更新
check_image_updates() {
    log_info "检查Docker镜像更新..."
    
    local images_to_check=(
        "nginx:alpine"
        "haproxy:alpine"
        "redis:alpine"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
    )
    
    for image in "${images_to_check[@]}"; do
        log_info "检查镜像: $image"
        
        # 拉取最新镜像信息（不下载）
        local remote_digest=$(docker manifest inspect "$image" 2>/dev/null | jq -r '.config.digest' 2>/dev/null || echo "unknown")
        local local_digest=$(docker inspect "$image" --format='{{.Id}}' 2>/dev/null || echo "not-found")
        
        if [ "$local_digest" = "not-found" ]; then
            log_warning "镜像 $image 本地不存在"
        elif [ "$remote_digest" != "$local_digest" ] && [ "$remote_digest" != "unknown" ]; then
            log_warning "镜像 $image 有可用更新"
        else
            log_success "镜像 $image 已是最新版本"
        fi
    done
}

# 归档旧数据
archive_old_data() {
    log_info "归档旧数据..."
    
    local archive_dir="${DEPLOY_DIR}/data/archive/$(date +%Y-%m)"
    mkdir -p "$archive_dir"
    
    # 归档3个月前的日志
    find "${DEPLOY_DIR}/logs" -name "*.log.gz" -mtime +90 -exec mv {} "$archive_dir/" \; 2>/dev/null || true
    
    # 归档旧的诊断报告
    find "${DEPLOY_DIR}/logs/diagnose" -name "*.txt" -mtime +30 -exec mv {} "$archive_dir/" \; 2>/dev/null || true
    
    # 归档旧的性能报告
    find "${DEPLOY_DIR}/logs/reports" -name "*.json" -mtime +60 -exec mv {} "$archive_dir/" \; 2>/dev/null || true
    
    local archived_count=$(find "$archive_dir" -type f 2>/dev/null | wc -l)
    log_success "已归档 $archived_count 个文件到 $archive_dir"
}

# 备份配置文件
backup_configurations() {
    log_info "备份配置文件..."
    
    local config_backup="${DEPLOY_DIR}/data/config-backup-$(date +%Y%m%d).tar.gz"
    
    tar -czf "$config_backup" -C "$DEPLOY_DIR" \
        config/ \
        docker-compose*.yml \
        .env.* \
        scripts/ \
        2>/dev/null || true
    
    if [ -f "$config_backup" ]; then
        local backup_size=$(du -sh "$config_backup" | cut -f1)
        log_success "配置文件备份完成: $(basename "$config_backup") ($backup_size)"
    else
        log_error "配置文件备份失败"
    fi
}

# 生成优化建议
generate_optimization_recommendations() {
    log_info "生成性能优化建议..."
    
    local recommendations_file="${DEPLOY_DIR}/logs/reports/optimization-recommendations-$(date +%Y%m%d).md"
    
    {
        echo "# 在线时间工具 - 性能优化建议"
        echo "生成时间: $(date)"
        echo
        
        # CPU优化建议
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        if (( $(echo "$cpu_usage > 80" | bc -l) )); then
            echo "## CPU优化建议"
            echo "- 当前CPU使用率: ${cpu_usage}%"
            echo "- 建议增加应用实例数量"
            echo "- 考虑优化应用代码中的CPU密集型操作"
            echo
        fi
        
        # 内存优化建议
        local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
        if [ "$mem_usage" -gt 80 ]; then
            echo "## 内存优化建议"
            echo "- 当前内存使用率: ${mem_usage}%"
            echo "- 建议增加系统内存或优化应用内存使用"
            echo "- 考虑调整Redis内存配置"
            echo
        fi
        
        # 磁盘优化建议
        local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
        if [ "$disk_usage" -gt 80 ]; then
            echo "## 磁盘优化建议"
            echo "- 当前磁盘使用率: ${disk_usage}%"
            echo "- 建议清理旧日志文件和临时文件"
            echo "- 考虑增加磁盘空间或配置日志轮转"
            echo
        fi
        
        # Docker优化建议
        local image_count=$(docker images | wc -l)
        if [ "$image_count" -gt 20 ]; then
            echo "## Docker优化建议"
            echo "- 当前镜像数量: $image_count"
            echo "- 建议定期清理未使用的镜像"
            echo "- 考虑使用多阶段构建减小镜像大小"
            echo
        fi
        
        echo "## 一般优化建议"
        echo "- 定期执行系统维护脚本"
        echo "- 监控系统资源使用情况"
        echo "- 保持Docker和系统组件更新"
        echo "- 优化数据库查询和索引"
        echo "- 使用CDN加速静态资源"
        
    } > "$recommendations_file"
    
    log_success "优化建议已生成: $recommendations_file"
}

# 生成周报
generate_weekly_report() {
    log_info "生成周维护报告..."
    
    local report_file="${DEPLOY_DIR}/logs/reports/weekly-maintenance-$(date +%Y%m%d).md"
    
    {
        echo "# 在线时间工具 - 周维护报告"
        echo "报告期间: $(date -d '7 days ago' +%Y-%m-%d) 到 $(date +%Y-%m-%d)"
        echo "生成时间: $(date)"
        echo
        
        echo "## 系统状态"
        echo "- 主机名: $(hostname)"
        echo "- 运行时间: $(uptime -p)"
        echo "- 系统负载: $(uptime | awk -F'load average:' '{print $2}')"
        echo
        
        echo "## Docker状态"
        echo "- 运行容器数: $(docker ps -q | wc -l)"
        echo "- 镜像数量: $(docker images -q | wc -l)"
        echo "- 卷数量: $(docker volume ls -q | wc -l)"
        echo
        
        echo "## 磁盘使用"
        df -h | grep -vE '^Filesystem|tmpfs|udev'
        echo
        
        echo "## 日志统计"
        echo "- 日志文件数量: $(find "${DEPLOY_DIR}/logs" -name "*.log" | wc -l)"
        echo "- 日志目录大小: $(du -sh "${DEPLOY_DIR}/logs" | cut -f1)"
        echo
        
        echo "## 最近错误"
        echo "最近7天的主要错误日志:"
        find "${DEPLOY_DIR}/logs" -name "*.log" -mtime -7 -exec grep -l "ERROR\|CRITICAL" {} \; 2>/dev/null | head -5 | while read logfile; do
            echo "- $(basename "$logfile"): $(grep -c "ERROR\|CRITICAL" "$logfile" 2>/dev/null) 个错误"
        done
        echo
        
        echo "## 维护活动"
        echo "- 清理临时文件"
        echo "- Docker系统清理"  
        echo "- 日志文件整理和压缩"
        echo "- 系统性能分析"
        echo "- 安全健康检查"
        echo "- 备份验证"
        
    } > "$report_file"
    
    log_success "周维护报告已生成: $report_file"
}

# 生成月报
generate_monthly_report() {
    log_info "生成月维护报告..."
    
    local report_file="${DEPLOY_DIR}/logs/reports/monthly-maintenance-$(date +%Y%m).md"
    
    {
        echo "# 在线时间工具 - 月维护报告"
        echo "报告月份: $(date +%Y年%m月)"
        echo "生成时间: $(date)"
        echo
        
        echo "## 月度总结"
        echo "### 系统稳定性"
        local uptime_days=$(uptime -p | grep -o '[0-9]\+ days' | grep -o '[0-9]\+' || echo "0")
        echo "- 系统连续运行: ${uptime_days} 天"
        echo "- 主要服务可用性: $(docker ps | grep -c "Up")/$(docker ps -a | wc -l) 容器正常运行"
        echo
        
        echo "### 资源使用趋势"
        echo "- 平均CPU使用率: 需要长期监控数据"
        echo "- 平均内存使用率: 需要长期监控数据"  
        echo "- 磁盘增长趋势: $(du -sh "${DEPLOY_DIR}" | cut -f1) 总使用空间"
        echo
        
        echo "### 维护活动汇总"
        echo "- 执行了 $(find "${DEPLOY_DIR}/logs/cron" -name "maintenance*.log" -mtime -30 | wc -l) 次自动维护"
        echo "- 清理了临时文件和旧日志"
        echo "- 执行了系统更新检查"
        echo "- 进行了安全扫描和备份验证"
        echo
        
        echo "### 问题和解决方案"
        echo "本月主要问题:"
        find "${DEPLOY_DIR}/logs" -name "*.log" -mtime -30 -exec grep -l "ERROR\|CRITICAL" {} \; 2>/dev/null | head -3 | while read logfile; do
            local error_count=$(grep -c "ERROR\|CRITICAL" "$logfile" 2>/dev/null)
            echo "- $(basename "$logfile"): $error_count 个错误记录"
        done
        echo
        
        echo "### 下月计划"
        echo "- 继续监控系统性能"
        echo "- 计划的系统更新"
        echo "- 配置优化"
        echo "- 容量规划评估"
        
    } > "$report_file"
    
    log_success "月维护报告已生成: $report_file"
}

# 主函数
main() {
    local maintenance_type=${1:-"daily"}
    
    create_maintenance_lock
    
    log_info "开始执行 $maintenance_type 维护任务..."
    
    case $maintenance_type in
        "daily")
            daily_maintenance
            ;;
        "weekly")
            weekly_maintenance
            ;;
        "monthly")
            monthly_maintenance
            ;;
        "emergency")
            log_warning "执行紧急维护..."
            cleanup_temp_files
            docker_system_cleanup
            cleanup_emergency_space
            verify_services_status
            log_info "紧急维护完成"
            ;;
        "custom")
            log_info "执行自定义维护任务..."
            shift
            for task in "$@"; do
                case $task in
                    "cleanup") cleanup_temp_files ;;
                    "docker") docker_system_cleanup ;;
                    "logs") organize_log_files ;;
                    "compress") compress_old_logs ;;
                    "check") verify_services_status ;;
                    "perf") analyze_system_performance ;;
                    "security") security_health_check ;;
                    "backup") backup_configurations ;;
                    *) log_warning "未知的自定义任务: $task" ;;
                esac
            done
            ;;
        *)
            echo "用法: $0 [daily|weekly|monthly|emergency|custom] [自定义任务...]"
            echo
            echo "维护类型:"
            echo "  daily    - 日常维护 (默认)"
            echo "  weekly   - 周维护"
            echo "  monthly  - 月维护"
            echo "  emergency- 紧急维护"
            echo "  custom   - 自定义维护任务"
            echo
            echo "自定义任务选项:"
            echo "  cleanup  - 清理临时文件"
            echo "  docker   - Docker系统清理"
            echo "  logs     - 日志文件整理"
            echo "  compress - 压缩旧日志"
            echo "  check    - 验证服务状态"
            echo "  perf     - 性能分析"
            echo "  security - 安全检查"
            echo "  backup   - 备份配置"
            exit 1
            ;;
    esac
    
    log_success "维护任务执行完成"
}

# 检查依赖
check_dependencies() {
    local deps=("docker" "curl" "bc" "tar" "gzip")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少依赖工具: ${missing_deps[*]}"
        exit 1
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # 创建日志目录
    mkdir -p "${DEPLOY_DIR}/logs/reports"
    
    check_dependencies
    main "$@"
fi