#!/bin/bash
# =================================
# 在线时间工具 - 快速运维脚本
# =================================
# 提供快速的运维操作命令

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 显示标题
show_header() {
    echo -e "${CYAN}${BOLD}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│                    在线时间工具 - 快速运维                   │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
}

# 显示状态
show_status() {
    echo -e "${BLUE}${BOLD}==================== 服务状态 ====================${NC}"
    
    # 检查容器状态
    echo -e "${YELLOW}容器状态:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(online-time|nginx|haproxy|redis|prometheus|grafana)" > /dev/null 2>&1; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(online-time|nginx|haproxy|redis|prometheus|grafana)" | head -10
    else
        echo "  ❌ 未找到运行中的服务容器"
    fi
    echo
    
    # 检查服务可用性
    echo -e "${YELLOW}服务可用性:${NC}"
    local services=(
        "http://localhost/,主应用"
        "http://localhost:8404/stats,HAProxy统计"
        "http://localhost:9090,Prometheus"
        "http://localhost:3001,Grafana"
    )
    
    for service_info in "${services[@]}"; do
        local url=$(echo "$service_info" | cut -d',' -f1)
        local name=$(echo "$service_info" | cut -d',' -f2)
        
        if curl -sf --max-time 3 "$url" > /dev/null 2>&1; then
            echo -e "  ✅ ${name}: ${GREEN}可用${NC}"
        else
            echo -e "  ❌ ${name}: ${RED}不可用${NC}"
        fi
    done
    echo
    
    # 系统资源
    echo -e "${YELLOW}系统资源:${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
    
    printf "  CPU: %6.1f%% | 内存: %6.1f%% | 磁盘: %3d%%\n" "$cpu_usage" "$mem_usage" "$disk_usage"
    echo
}

# 快速日志查看
show_logs() {
    local service=${1:-""}
    local lines=${2:-50}
    
    echo -e "${BLUE}${BOLD}==================== 服务日志 ====================${NC}"
    
    if [ -n "$service" ]; then
        echo -e "${YELLOW}查看 $service 最近 $lines 行日志:${NC}"
        if docker ps --format "{{.Names}}" | grep -q "$service"; then
            docker logs --tail="$lines" "$service" 2>&1 | tail -20
        else
            echo "  ❌ 容器 $service 未运行"
        fi
    else
        echo -e "${YELLOW}主要服务日志概览:${NC}"
        local services=("online-time-nginx" "online-time-haproxy" "online-time-app-1")
        
        for svc in "${services[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "$svc"; then
                echo -e "\n${CYAN}--- $svc 最近5行日志 ---${NC}"
                docker logs --tail=5 "$svc" 2>&1 | grep -E "(ERROR|WARN|error|warn)" || echo "  无错误或警告日志"
            fi
        done
    fi
    echo
}

# 快速重启
quick_restart() {
    local service=${1:-"all"}
    
    echo -e "${BLUE}${BOLD}==================== 服务重启 ====================${NC}"
    
    case $service in
        "all")
            echo -e "${YELLOW}重启所有服务...${NC}"
            cd "$DEPLOY_DIR"
            docker-compose -f docker-compose.ha.yml restart
            echo -e "${GREEN}✅ 所有服务重启完成${NC}"
            ;;
        "app")
            echo -e "${YELLOW}重启应用服务...${NC}"
            docker restart online-time-app-1 online-time-app-2 online-time-app-3 2>/dev/null || true
            echo -e "${GREEN}✅ 应用服务重启完成${NC}"
            ;;
        "web")
            echo -e "${YELLOW}重启Web服务...${NC}"
            docker restart online-time-nginx online-time-haproxy 2>/dev/null || true
            echo -e "${GREEN}✅ Web服务重启完成${NC}"
            ;;
        "monitoring")
            echo -e "${YELLOW}重启监控服务...${NC}"
            docker restart online-time-prometheus online-time-grafana 2>/dev/null || true
            echo -e "${GREEN}✅ 监控服务重启完成${NC}"
            ;;
        *)
            if docker ps --format "{{.Names}}" | grep -q "$service"; then
                echo -e "${YELLOW}重启服务: $service${NC}"
                docker restart "$service"
                echo -e "${GREEN}✅ 服务 $service 重启完成${NC}"
            else
                echo -e "${RED}❌ 服务 $service 未找到${NC}"
                return 1
            fi
            ;;
    esac
}

# 快速扩容
quick_scale() {
    local replicas=${1:-3}
    
    echo -e "${BLUE}${BOLD}==================== 服务扩容 ====================${NC}"
    echo -e "${YELLOW}将应用扩容到 $replicas 个实例...${NC}"
    
    cd "$DEPLOY_DIR"
    
    # 检查当前实例数
    local current_instances=$(docker ps --format "{{.Names}}" | grep -c "online-time-app" || echo 0)
    echo -e "当前实例数: $current_instances"
    
    if [ "$replicas" -gt "$current_instances" ]; then
        echo -e "正在扩容到 $replicas 个实例..."
        # 这里需要根据实际的docker-compose配置进行调整
        docker-compose -f docker-compose.ha.yml up -d --scale app="$replicas"
        echo -e "${GREEN}✅ 扩容完成${NC}"
    elif [ "$replicas" -lt "$current_instances" ]; then
        echo -e "正在缩容到 $replicas 个实例..."
        docker-compose -f docker-compose.ha.yml up -d --scale app="$replicas"
        echo -e "${GREEN}✅ 缩容完成${NC}"
    else
        echo -e "${YELLOW}实例数量无变化${NC}"
    fi
}

# 快速清理
quick_cleanup() {
    local cleanup_type=${1:-"basic"}
    
    echo -e "${BLUE}${BOLD}==================== 系统清理 ====================${NC}"
    
    case $cleanup_type in
        "basic")
            echo -e "${YELLOW}执行基础清理...${NC}"
            docker system prune -f
            echo -e "${GREEN}✅ 基础清理完成${NC}"
            ;;
        "full")
            echo -e "${YELLOW}执行完整清理...${NC}"
            docker system prune -af --volumes
            find /tmp -name "online-time-*" -mtime +1 -delete 2>/dev/null || true
            echo -e "${GREEN}✅ 完整清理完成${NC}"
            ;;
        "logs")
            echo -e "${YELLOW}清理日志文件...${NC}"
            find "${DEPLOY_DIR}/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
            docker container prune -f
            echo -e "${GREEN}✅ 日志清理完成${NC}"
            ;;
        *)
            echo -e "${RED}❌ 未知的清理类型: $cleanup_type${NC}"
            echo "支持的清理类型: basic, full, logs"
            return 1
            ;;
    esac
}

# 快速健康检查
quick_health() {
    echo -e "${BLUE}${BOLD}==================== 健康检查 ====================${NC}"
    
    # 运行健康检查脚本
    if [ -x "${SCRIPT_DIR}/health-check.sh" ]; then
        echo -e "${YELLOW}执行健康检查...${NC}"
        "${SCRIPT_DIR}/health-check.sh" 2>/dev/null || echo -e "${RED}❌ 健康检查发现问题${NC}"
    else
        echo -e "${YELLOW}手动健康检查:${NC}"
        
        # 简单的健康检查
        local issues=0
        
        # 检查关键容器
        local critical_containers=("online-time-nginx" "online-time-haproxy")
        for container in "${critical_containers[@]}"; do
            if ! docker ps --format "{{.Names}}" | grep -q "$container"; then
                echo -e "  ❌ 关键容器 $container 未运行"
                ((issues++))
            fi
        done
        
        # 检查端点
        if ! curl -sf --max-time 3 "http://localhost/" > /dev/null 2>&1; then
            echo -e "  ❌ 主页无法访问"
            ((issues++))
        fi
        
        # 检查资源
        local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
        if [ "$disk_usage" -gt 90 ]; then
            echo -e "  ❌ 磁盘空间不足: ${disk_usage}%"
            ((issues++))
        fi
        
        if [ $issues -eq 0 ]; then
            echo -e "${GREEN}✅ 健康检查通过${NC}"
        else
            echo -e "${RED}❌ 发现 $issues 个问题${NC}"
        fi
    fi
}

# 快速备份
quick_backup() {
    echo -e "${BLUE}${BOLD}==================== 快速备份 ====================${NC}"
    
    if [ -x "${DEPLOY_DIR}/backup.sh" ]; then
        echo -e "${YELLOW}执行快速备份...${NC}"
        "${DEPLOY_DIR}/backup.sh" --quick
        echo -e "${GREEN}✅ 备份完成${NC}"
    else
        echo -e "${YELLOW}手动备份配置文件...${NC}"
        local backup_file="${DEPLOY_DIR}/data/manual-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        mkdir -p "$(dirname "$backup_file")"
        
        tar -czf "$backup_file" -C "$DEPLOY_DIR" \
            config/ \
            docker-compose*.yml \
            .env.* \
            scripts/ \
            2>/dev/null || true
            
        if [ -f "$backup_file" ]; then
            local size=$(du -sh "$backup_file" | cut -f1)
            echo -e "${GREEN}✅ 备份完成: $(basename "$backup_file") ($size)${NC}"
        else
            echo -e "${RED}❌ 备份失败${NC}"
        fi
    fi
}

# 快速监控
quick_monitor() {
    local duration=${1:-10}
    
    echo -e "${BLUE}${BOLD}==================== 实时监控 ====================${NC}"
    echo -e "${YELLOW}实时监控 ${duration} 秒 (按Ctrl+C停止)${NC}"
    echo
    
    # 设置信号处理
    trap 'echo -e "\n${GREEN}监控结束${NC}"; exit 0' INT
    
    for ((i=1; i<=duration; i++)); do
        # 清屏并显示当前时间
        clear
        echo -e "${CYAN}${BOLD}实时监控 - $(date) - 第 $i/$duration 次${NC}"
        echo
        
        # 系统资源
        echo -e "${YELLOW}系统资源:${NC}"
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local disk_usage=$(df / | grep -vE '^Filesystem' | awk '{print $5}' | sed 's/%//g')
        
        printf "CPU: %6.1f%% | 内存: %6.1f%% | 磁盘: %3d%%\n" "$cpu_usage" "$mem_usage" "$disk_usage"
        echo
        
        # 容器状态
        echo -e "${YELLOW}容器状态:${NC}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6
        echo
        
        # 服务响应时间
        echo -e "${YELLOW}服务响应:${NC}"
        local response_time=$(curl -w "%{time_total}s" -s -o /dev/null --max-time 3 "http://localhost/" 2>/dev/null || echo "timeout")
        echo "主页响应时间: $response_time"
        
        # 等待1秒
        sleep 1
    done
    
    echo -e "${GREEN}✅ 监控完成${NC}"
}

# 显示快捷命令菜单
show_menu() {
    echo -e "${CYAN}${BOLD}==================== 快捷命令菜单 ====================${NC}"
    echo -e "${YELLOW}基础操作:${NC}"
    echo "  status              - 显示服务状态"
    echo "  logs [service] [lines] - 查看日志"
    echo "  restart [service]   - 重启服务"
    echo "  health              - 快速健康检查"
    echo "  monitor [seconds]   - 实时监控"
    echo
    echo -e "${YELLOW}维护操作:${NC}"
    echo "  cleanup [type]      - 系统清理 (basic/full/logs)"
    echo "  backup              - 快速备份"
    echo "  scale [replicas]    - 扩容/缩容应用"
    echo
    echo -e "${YELLOW}高级操作:${NC}"
    echo "  diagnose            - 完整诊断"
    echo "  update              - 更新部署"
    echo "  maintenance         - 系统维护"
    echo
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 status"
    echo "  $0 logs nginx 100"
    echo "  $0 restart app"
    echo "  $0 cleanup full"
    echo "  $0 monitor 30"
    echo
}

# 主函数
main() {
    local command=${1:-"menu"}
    shift || true
    
    show_header
    
    case $command in
        "status"|"st")
            show_status
            ;;
        "logs"|"log")
            show_logs "$@"
            ;;
        "restart"|"rs")
            quick_restart "$@"
            ;;
        "scale"|"sc")
            quick_scale "$@"
            ;;
        "cleanup"|"clean")
            quick_cleanup "$@"
            ;;
        "health"|"check")
            quick_health
            ;;
        "backup"|"bk")
            quick_backup
            ;;
        "monitor"|"mon")
            quick_monitor "$@"
            ;;
        "diagnose"|"diag")
            echo -e "${YELLOW}运行完整诊断...${NC}"
            if [ -x "${SCRIPT_DIR}/diagnose.sh" ]; then
                "${SCRIPT_DIR}/diagnose.sh" quick
            else
                echo -e "${RED}❌ 诊断脚本不存在${NC}"
            fi
            ;;
        "update"|"up")
            echo -e "${YELLOW}更新部署...${NC}"
            if [ -x "${DEPLOY_DIR}/update.sh" ]; then
                "${DEPLOY_DIR}/update.sh"
            else
                echo -e "${RED}❌ 更新脚本不存在${NC}"
            fi
            ;;
        "maintenance"|"maint")
            echo -e "${YELLOW}执行系统维护...${NC}"
            if [ -x "${SCRIPT_DIR}/maintenance.sh" ]; then
                "${SCRIPT_DIR}/maintenance.sh" daily
            else
                echo -e "${RED}❌ 维护脚本不存在${NC}"
            fi
            ;;
        "menu"|"help"|"-h"|"--help")
            show_menu
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $command${NC}"
            echo
            show_menu
            exit 1
            ;;
    esac
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi