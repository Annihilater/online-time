#!/bin/bash
# 恢复脚本

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")")
BACKUP_DIR="$PROJECT_ROOT/data/backups"
LOG_FILE="$PROJECT_ROOT/logs/restore.log"

# 创建目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 错误处理
handle_error() {
    log "ERROR: Restore failed at line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 显示可用备份
list_backups() {
    local service="$1"
    
    log "Available backups for $service:"
    
    if [[ -n "$service" ]]; then
        ls -lht "$BACKUP_DIR/${service}_backup_"*.tar.gz 2>/dev/null || {
            log "No backups found for service: $service"
            return 1
        }
    else
        ls -lht "$BACKUP_DIR/"*.tar.gz 2>/dev/null || {
            log "No backup files found"
            return 1
        }
    fi
}

# 验证备份文件
validate_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log "ERROR: Backup file not found: $backup_file"
        return 1
    fi
    
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        log "ERROR: Backup file is corrupted: $backup_file"
        return 1
    fi
    
    log "Backup file validation successful: $(basename "$backup_file")"
    return 0
}

# 停止服务
stop_service() {
    local service="$1"
    
    log "Stopping service: $service"
    
    if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
        docker stop "$service" || {
            log "WARNING: Failed to gracefully stop $service"
            docker kill "$service" 2>/dev/null || true
        }
        log "Service stopped: $service"
    else
        log "Service is not running: $service"
    fi
}

# 启动服务
start_service() {
    local service="$1"
    
    log "Starting service: $service"
    
    if docker ps -a --filter "name=$service" | grep -q "$service"; then
        docker start "$service" || {
            log "ERROR: Failed to start service: $service"
            return 1
        }
        
        # 等待服务健康
        local retries=30
        while [[ $retries -gt 0 ]]; do
            if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
                local health_status
                health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
                
                if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "none" ]]; then
                    log "Service started successfully: $service"
                    return 0
                fi
            fi
            
            log "Waiting for service to become healthy: $service ($retries retries left)"
            sleep 2
            ((retries--))
        done
        
        log "WARNING: Service may not be fully healthy: $service"
        return 1
    else
        log "ERROR: Service container not found: $service"
        return 1
    fi
}

# 恢复容器数据
restore_container_data() {
    local container_name="$1"
    local backup_file="$2"
    local data_path="${3:-/data}"
    
    log "Restoring container data: $container_name from $(basename "$backup_file")"
    
    # 验证备份文件
    validate_backup "$backup_file" || return 1
    
    # 停止容器
    stop_service "$container_name"
    
    # 恢复数据
    if docker volume inspect "${container_name}-data" >/dev/null 2>&1; then
        # 恢复到数据卷
        log "Restoring to data volume: ${container_name}-data"
        docker run --rm -v "${container_name}-data:/data" -v "$BACKUP_DIR:/backup" alpine \
            tar -xzf "/backup/$(basename "$backup_file")" -C /data || {
            log "ERROR: Failed to restore data to volume"
            return 1
        }
    else
        log "WARNING: Data volume not found: ${container_name}-data"
        return 1
    fi
    
    # 启动容器
    start_service "$container_name"
    
    log "Data restore completed for: $container_name"
}

# 恢复配置文件
restore_config() {
    local backup_file="$1"
    local restore_dir="${2:-$PROJECT_ROOT}"
    
    log "Restoring configuration from $(basename "$backup_file")"
    
    # 验证备份文件
    validate_backup "$backup_file" || return 1
    
    # 创建备份
    local current_backup="$restore_dir/config_backup_before_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$current_backup" -C "$restore_dir" \
        docker-compose*.yml Dockerfile* nginx*.conf config/ monitoring/ .env* 2>/dev/null || {
        log "WARNING: Failed to backup current configuration"
    }
    
    # 恢复配置
    tar -xzf "$backup_file" -C "$restore_dir" || {
        log "ERROR: Failed to restore configuration"
        return 1
    }
    
    log "Configuration restore completed"
    log "Previous configuration backed up to: $(basename "$current_backup")"
}

# 恢复Redis数据
restore_redis() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        # 查找最新的Redis备份
        backup_file=$(ls -t "$BACKUP_DIR/online-time-redis_backup_"*.tar.gz 2>/dev/null | head -n 1)
        
        if [[ -z "$backup_file" ]]; then
            log "ERROR: No Redis backup found"
            return 1
        fi
    fi
    
    restore_container_data "online-time-redis" "$backup_file" "/data"
}

# 恢复监控数据
restore_monitoring() {
    local service="$1"
    local backup_file="$2"
    
    case "$service" in
        "prometheus")
            restore_container_data "online-time-prometheus" "$backup_file" "/prometheus"
            ;;
        "grafana")
            restore_container_data "online-time-grafana" "$backup_file" "/var/lib/grafana"
            ;;
        "loki")
            restore_container_data "online-time-loki" "$backup_file" "/loki"
            ;;
        *)
            log "ERROR: Unknown monitoring service: $service"
            return 1
            ;;
    esac
}

# 显示帮助
show_help() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    list [service]                  - List available backups
    config <backup_file>           - Restore configuration
    redis [backup_file]            - Restore Redis data
    monitoring <service> <backup_file> - Restore monitoring service data
    validate <backup_file>         - Validate backup file

Services:
    prometheus, grafana, loki

Examples:
    $0 list
    $0 list redis
    $0 config config_backup_20231201_120000.tar.gz
    $0 redis redis_backup_20231201_120000.tar.gz
    $0 monitoring prometheus prometheus_backup_20231201_120000.tar.gz

EOF
}

# 主函数
main() {
    local command="$1"
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    log "=== Restore Started ($command) ==="
    
    case "$command" in
        "list")
            list_backups "$2"
            ;;
        "config")
            if [[ -z "$2" ]]; then
                log "ERROR: Backup file required for config restore"
                exit 1
            fi
            restore_config "$BACKUP_DIR/$2"
            ;;
        "redis")
            restore_redis "${2:+$BACKUP_DIR/$2}"
            ;;
        "monitoring")
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                log "ERROR: Service and backup file required for monitoring restore"
                exit 1
            fi
            restore_monitoring "$2" "$BACKUP_DIR/$3"
            ;;
        "validate")
            if [[ -z "$2" ]]; then
                log "ERROR: Backup file required for validation"
                exit 1
            fi
            validate_backup "$BACKUP_DIR/$2"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log "ERROR: Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
    
    log "=== Restore Completed ==="
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi