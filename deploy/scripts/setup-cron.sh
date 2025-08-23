#!/bin/bash
# =================================
# 在线时间工具 - 定时任务设置脚本
# =================================

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
CRON_CONFIG_DIR="${DEPLOY_DIR}/config/cron"
LOG_FILE="${DEPLOY_DIR}/logs/cron-setup.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 创建必要目录
mkdir -p "$CRON_CONFIG_DIR" "${DEPLOY_DIR}/logs/cron"

# 创建健康检查定时任务
setup_health_check_cron() {
    log_info "设置健康检查定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/health-check.cron"
    
    cat << EOF > "$cron_file"
# 在线时间工具 - 健康检查定时任务
# 每5分钟执行一次健康检查
*/5 * * * * ${SCRIPT_DIR}/health-check.sh >> ${DEPLOY_DIR}/logs/cron/health-check-cron.log 2>&1

# 每小时生成详细健康报告
0 * * * * ${SCRIPT_DIR}/health-check.sh --detailed >> ${DEPLOY_DIR}/logs/cron/health-check-hourly.log 2>&1
EOF
    
    log_success "健康检查定时任务配置已创建: $cron_file"
}

# 创建性能监控定时任务
setup_monitoring_cron() {
    log_info "设置性能监控定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/monitoring.cron"
    
    cat << EOF > "$cron_file"
# 在线时间工具 - 性能监控定时任务
# 每15分钟收集性能指标
*/15 * * * * ${SCRIPT_DIR}/monitor.sh report >> ${DEPLOY_DIR}/logs/cron/monitoring.log 2>&1

# 每小时运行性能基准测试
0 * * * * ${SCRIPT_DIR}/monitor.sh benchmark >> ${DEPLOY_DIR}/logs/cron/benchmark.log 2>&1

# 每天凌晨2点生成详细性能报告
0 2 * * * ${SCRIPT_DIR}/monitor.sh full-report >> ${DEPLOY_DIR}/logs/cron/daily-performance.log 2>&1
EOF
    
    log_success "性能监控定时任务配置已创建: $cron_file"
}

# 创建备份定时任务
setup_backup_cron() {
    log_info "设置备份定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/backup.cron"
    
    cat << EOF > "$cron_file"
# 在线时间工具 - 备份定时任务
# 每天凌晨3点执行完整备份
0 3 * * * ${DEPLOY_DIR}/backup.sh --auto >> ${DEPLOY_DIR}/logs/cron/backup.log 2>&1

# 每12小时执行增量备份
0 */12 * * * ${DEPLOY_DIR}/backup.sh --incremental >> ${DEPLOY_DIR}/logs/cron/backup-incremental.log 2>&1

# 每周日凌晨4点清理旧备份文件
0 4 * * 0 ${DEPLOY_DIR}/backup.sh --cleanup >> ${DEPLOY_DIR}/logs/cron/backup-cleanup.log 2>&1
EOF
    
    log_success "备份定时任务配置已创建: $cron_file"
}

# 创建日志清理定时任务
setup_log_cleanup_cron() {
    log_info "设置日志清理定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/log-cleanup.cron"
    
    cat << 'EOF' > "$cron_file"
# 在线时间工具 - 日志清理定时任务
# 每天凌晨1点清理超过30天的日志文件
0 1 * * * find DEPLOY_DIR/logs -name "*.log" -mtime +30 -delete >> DEPLOY_DIR/logs/cron/log-cleanup.log 2>&1

# 每周清理Docker日志（保留最近1000行）
0 2 * * 1 docker ps -q | xargs -I {} docker logs --tail=1000 {} > /tmp/{}.log 2>/dev/null && docker logs --tail=0 {} >> DEPLOY_DIR/logs/cron/docker-log-cleanup.log 2>&1

# 每月清理诊断报告文件（保留最近90天）
0 3 1 * * find DEPLOY_DIR/logs/diagnose -name "*.txt" -mtime +90 -delete >> DEPLOY_DIR/logs/cron/diagnose-cleanup.log 2>&1
0 3 1 * * find DEPLOY_DIR/logs/reports -name "*.json" -mtime +90 -delete >> DEPLOY_DIR/logs/cron/reports-cleanup.log 2>&1

# 每天检查并轮转大日志文件（超过100MB）
0 4 * * * find DEPLOY_DIR/logs -name "*.log" -size +100M -exec logrotate -f DEPLOY_DIR/config/logrotate.conf {} \; >> DEPLOY_DIR/logs/cron/log-rotate.log 2>&1
EOF
    
    # 替换路径占位符
    sed -i "s|DEPLOY_DIR|${DEPLOY_DIR}|g" "$cron_file"
    
    log_success "日志清理定时任务配置已创建: $cron_file"
}

# 创建系统维护定时任务
setup_maintenance_cron() {
    log_info "设置系统维护定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/maintenance.cron"
    
    cat << EOF > "$cron_file"
# 在线时间工具 - 系统维护定时任务
# 每天凌晨5点执行系统维护
0 5 * * * ${SCRIPT_DIR}/maintenance.sh --daily >> ${DEPLOY_DIR}/logs/cron/maintenance.log 2>&1

# 每周日凌晨6点执行周维护
0 6 * * 0 ${SCRIPT_DIR}/maintenance.sh --weekly >> ${DEPLOY_DIR}/logs/cron/maintenance-weekly.log 2>&1

# 每月1号凌晨7点执行月维护
0 7 1 * * ${SCRIPT_DIR}/maintenance.sh --monthly >> ${DEPLOY_DIR}/logs/cron/maintenance-monthly.log 2>&1

# 每小时检查并清理Docker资源
0 * * * * docker system prune -f --volumes >> ${DEPLOY_DIR}/logs/cron/docker-cleanup.log 2>&1
EOF
    
    log_success "系统维护定时任务配置已创建: $cron_file"
}

# 创建安全检查定时任务
setup_security_cron() {
    log_info "设置安全检查定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/security.cron"
    
    cat << 'EOF' > "$cron_file"
# 在线时间工具 - 安全检查定时任务
# 每6小时检查异常访问日志
0 */6 * * * grep -E "(404|403|500)" /var/log/nginx/access.log | tail -100 >> DEPLOY_DIR/logs/cron/security-access.log 2>&1

# 每天检查失败的登录尝试
0 6 * * * grep -i "failed" /var/log/auth.log | tail -50 >> DEPLOY_DIR/logs/cron/security-auth.log 2>&1 || true

# 每12小时检查系统资源使用情况
0 */12 * * * df -h > DEPLOY_DIR/logs/cron/disk-usage.log 2>&1 && free -h >> DEPLOY_DIR/logs/cron/memory-usage.log 2>&1

# 每周扫描开放端口
0 3 * * 1 nmap -sT localhost >> DEPLOY_DIR/logs/cron/port-scan.log 2>&1 || netstat -tuln >> DEPLOY_DIR/logs/cron/port-scan.log 2>&1

# 每天检查Docker镜像安全更新
0 4 * * * docker images --format "table {{.Repository}}:{{.Tag}}" | grep -v "REPOSITORY" >> DEPLOY_DIR/logs/cron/image-versions.log 2>&1
EOF
    
    # 替换路径占位符
    sed -i "s|DEPLOY_DIR|${DEPLOY_DIR}|g" "$cron_file"
    
    log_success "安全检查定时任务配置已创建: $cron_file"
}

# 创建报告生成定时任务
setup_reporting_cron() {
    log_info "设置报告生成定时任务..."
    
    local cron_file="${CRON_CONFIG_DIR}/reporting.cron"
    
    cat << EOF > "$cron_file"
# 在线时间工具 - 报告生成定时任务
# 每天早上8点生成日报
0 8 * * * ${SCRIPT_DIR}/generate-report.sh --daily >> ${DEPLOY_DIR}/logs/cron/daily-report.log 2>&1

# 每周一早上9点生成周报
0 9 * * 1 ${SCRIPT_DIR}/generate-report.sh --weekly >> ${DEPLOY_DIR}/logs/cron/weekly-report.log 2>&1

# 每月1号早上10点生成月报
0 10 1 * * ${SCRIPT_DIR}/generate-report.sh --monthly >> ${DEPLOY_DIR}/logs/cron/monthly-report.log 2>&1

# 每小时更新实时统计
*/30 * * * * ${SCRIPT_DIR}/update-metrics.sh >> ${DEPLOY_DIR}/logs/cron/metrics-update.log 2>&1
EOF
    
    log_success "报告生成定时任务配置已创建: $cron_file"
}

# 创建Logrotate配置文件
create_logrotate_config() {
    log_info "创建日志轮转配置..."
    
    local logrotate_config="${DEPLOY_DIR}/config/logrotate.conf"
    
    cat << EOF > "$logrotate_config"
# 在线时间工具 - 日志轮转配置

# 应用日志
${DEPLOY_DIR}/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 644 root root
    postrotate
        echo "Application logs rotated at \$(date)" >> ${DEPLOY_DIR}/logs/logrotate.log
    endscript
}

# 监控日志
${DEPLOY_DIR}/logs/cron/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 644 root root
}

# 诊断报告（按大小轮转）
${DEPLOY_DIR}/logs/diagnose/*.txt {
    size 50M
    rotate 5
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 644 root root
}

# Nginx日志（如果存在）
/var/log/nginx/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        # 重新加载Nginx
        docker exec online-time-nginx nginx -s reload 2>/dev/null || true
    endscript
}
EOF
    
    log_success "日志轮转配置已创建: $logrotate_config"
}

# 安装定时任务到系统
install_cron_jobs() {
    log_info "安装定时任务到系统..."
    
    # 备份现有crontab
    local backup_file="${DEPLOY_DIR}/logs/crontab-backup-$(date +%Y%m%d-%H%M%S).txt"
    crontab -l > "$backup_file" 2>/dev/null || echo "# 无现有crontab" > "$backup_file"
    log_info "现有crontab已备份到: $backup_file"
    
    # 创建临时crontab文件
    local temp_cron_file="/tmp/online-time-crontab-$(date +%s)"
    
    # 保留现有crontab（除了之前安装的在线时间工具任务）
    crontab -l 2>/dev/null | grep -v "# 在线时间工具" | grep -v "${SCRIPT_DIR}" | grep -v "${DEPLOY_DIR}" > "$temp_cron_file" || true
    
    # 添加新的定时任务
    echo "" >> "$temp_cron_file"
    echo "# ==================== 在线时间工具定时任务 ====================" >> "$temp_cron_file"
    
    # 合并所有cron配置文件
    for cron_file in "$CRON_CONFIG_DIR"/*.cron; do
        if [ -f "$cron_file" ]; then
            echo "# $(basename "$cron_file")" >> "$temp_cron_file"
            cat "$cron_file" >> "$temp_cron_file"
            echo "" >> "$temp_cron_file"
        fi
    done
    
    echo "# ==================== 在线时间工具定时任务结束 ====================" >> "$temp_cron_file"
    
    # 安装新的crontab
    if crontab "$temp_cron_file"; then
        log_success "定时任务安装成功"
        log_info "当前定时任务列表:"
        crontab -l | grep -A 20 -B 5 "在线时间工具" || log_warning "无法显示定时任务列表"
    else
        log_error "定时任务安装失败"
        return 1
    fi
    
    # 清理临时文件
    rm -f "$temp_cron_file"
}

# 卸载定时任务
uninstall_cron_jobs() {
    log_info "卸载在线时间工具定时任务..."
    
    # 备份现有crontab
    local backup_file="${DEPLOY_DIR}/logs/crontab-backup-uninstall-$(date +%Y%m%d-%H%M%S).txt"
    crontab -l > "$backup_file" 2>/dev/null || echo "# 无现有crontab" > "$backup_file"
    log_info "现有crontab已备份到: $backup_file"
    
    # 创建临时crontab文件（移除在线时间工具相关任务）
    local temp_cron_file="/tmp/online-time-crontab-clean-$(date +%s)"
    crontab -l 2>/dev/null | grep -v "# 在线时间工具" | grep -v "${SCRIPT_DIR}" | grep -v "${DEPLOY_DIR}" | grep -v "==================== 在线时间工具" > "$temp_cron_file" || true
    
    # 安装清理后的crontab
    if crontab "$temp_cron_file"; then
        log_success "定时任务卸载成功"
    else
        log_error "定时任务卸载失败"
        return 1
    fi
    
    # 清理临时文件
    rm -f "$temp_cron_file"
}

# 验证定时任务
verify_cron_jobs() {
    log_info "验证定时任务配置..."
    
    local errors=0
    
    # 检查crontab语法
    if ! crontab -l > /dev/null 2>&1; then
        log_error "Crontab语法错误"
        ((errors++))
    fi
    
    # 检查脚本文件存在性和可执行性
    local scripts=(
        "${SCRIPT_DIR}/health-check.sh"
        "${SCRIPT_DIR}/monitor.sh"
        "${SCRIPT_DIR}/diagnose.sh"
        "${DEPLOY_DIR}/backup.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ ! -f "$script" ]; then
            log_error "脚本文件不存在: $script"
            ((errors++))
        elif [ ! -x "$script" ]; then
            log_error "脚本文件不可执行: $script"
            ((errors++))
        else
            log_success "脚本文件检查通过: $script"
        fi
    done
    
    # 检查日志目录
    local log_dirs=(
        "${DEPLOY_DIR}/logs/cron"
        "${DEPLOY_DIR}/logs/diagnose"
        "${DEPLOY_DIR}/logs/reports"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [ ! -d "$log_dir" ]; then
            mkdir -p "$log_dir"
            log_info "创建日志目录: $log_dir"
        else
            log_success "日志目录存在: $log_dir"
        fi
    done
    
    # 检查cron服务状态
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        log_success "Cron服务运行正常"
    else
        log_warning "Cron服务状态未知或未运行"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "定时任务验证通过"
        return 0
    else
        log_error "定时任务验证失败，发现 $errors 个错误"
        return 1
    fi
}

# 显示定时任务状态
show_cron_status() {
    log_info "显示定时任务状态..."
    
    echo -e "\n${BLUE}==================== 当前定时任务 ====================${NC}"
    crontab -l | grep -A 100 "在线时间工具" 2>/dev/null || log_warning "未找到在线时间工具定时任务"
    
    echo -e "\n${BLUE}==================== 最近日志文件 ====================${NC}"
    if [ -d "${DEPLOY_DIR}/logs/cron" ]; then
        ls -la "${DEPLOY_DIR}/logs/cron" | head -10
    else
        log_warning "定时任务日志目录不存在"
    fi
    
    echo -e "\n${BLUE}==================== Cron服务状态 ====================${NC}"
    systemctl status cron --no-pager -l 2>/dev/null || systemctl status crond --no-pager -l 2>/dev/null || log_warning "无法获取Cron服务状态"
}

# 创建维护脚本模板
create_maintenance_script() {
    log_info "创建维护脚本模板..."
    
    local maintenance_script="${SCRIPT_DIR}/maintenance.sh"
    
    if [ ! -f "$maintenance_script" ]; then
        cat << 'EOF' > "$maintenance_script"
#!/bin/bash
# 在线时间工具 - 系统维护脚本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

case "${1:-daily}" in
    "daily")
        echo "执行日常维护..."
        # 清理临时文件
        find /tmp -name "online-time-*" -mtime +1 -delete 2>/dev/null || true
        # Docker资源清理
        docker system prune -f --volumes
        ;;
    "weekly")
        echo "执行周维护..."
        # 清理旧的Docker镜像
        docker image prune -a -f
        # 压缩旧日志
        find "${DEPLOY_DIR}/logs" -name "*.log" -mtime +7 -exec gzip {} \;
        ;;
    "monthly")
        echo "执行月维护..."
        # 系统更新检查
        apt list --upgradable 2>/dev/null || yum check-update 2>/dev/null || true
        # 生成月度统计报告
        echo "月度维护完成: $(date)" >> "${DEPLOY_DIR}/logs/maintenance-monthly.log"
        ;;
esac
EOF
        chmod +x "$maintenance_script"
        log_success "维护脚本已创建: $maintenance_script"
    else
        log_info "维护脚本已存在: $maintenance_script"
    fi
}

# 主函数
main() {
    local action=${1:-"setup"}
    
    log_info "==================== 定时任务管理 ===================="
    
    case $action in
        "setup"|"install")
            setup_health_check_cron
            setup_monitoring_cron
            setup_backup_cron
            setup_log_cleanup_cron
            setup_maintenance_cron
            setup_security_cron
            setup_reporting_cron
            create_logrotate_config
            create_maintenance_script
            install_cron_jobs
            verify_cron_jobs
            log_success "定时任务设置完成"
            ;;
        "uninstall"|"remove")
            uninstall_cron_jobs
            log_success "定时任务已卸载"
            ;;
        "verify"|"check")
            verify_cron_jobs
            ;;
        "status"|"list")
            show_cron_status
            ;;
        "config-only")
            setup_health_check_cron
            setup_monitoring_cron
            setup_backup_cron
            setup_log_cleanup_cron
            setup_maintenance_cron
            setup_security_cron
            setup_reporting_cron
            create_logrotate_config
            create_maintenance_script
            log_success "定时任务配置文件创建完成，使用 '$0 install' 安装到系统"
            ;;
        *)
            echo "用法: $0 [setup|uninstall|verify|status|config-only]"
            echo "  setup/install  - 设置并安装定时任务 (默认)"
            echo "  uninstall      - 卸载定时任务"
            echo "  verify/check   - 验证定时任务配置"
            echo "  status/list    - 显示定时任务状态"
            echo "  config-only    - 仅创建配置文件，不安装"
            exit 1
            ;;
    esac
    
    log_info "==================== 定时任务管理完成 ===================="
}

# 检查权限
check_permissions() {
    if [ "$EUID" -eq 0 ]; then
        log_warning "正在以root用户运行，请确认这是必要的"
    fi
    
    # 检查是否可以访问crontab
    if ! crontab -l >/dev/null 2>&1 && [ "$?" -ne 1 ]; then
        log_error "无法访问crontab，可能需要不同的用户权限"
        exit 1
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    check_permissions
    main "$@"
fi