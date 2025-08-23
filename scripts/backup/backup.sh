#!/bin/bash
# 备份脚本

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")")
BACKUP_DIR="$PROJECT_ROOT/data/backups"
LOG_FILE="$PROJECT_ROOT/logs/backup.log"
RETENTION_DAYS=30
COMPRESSION_LEVEL=6

# 创建目录
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 错误处理
handle_error() {
    log "ERROR: Backup failed at line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 创建备份文件名
generate_backup_name() {
    local service="$1"
    local timestamp="$(date +%Y%m%d_%H%M%S)"
    echo "${service}_backup_${timestamp}.tar.gz"
}

# 备份Docker容器数据
backup_container_data() {
    local container_name="$1"
    local data_path="$2"
    local backup_name="$(generate_backup_name "$container_name")"
    local backup_file="$BACKUP_DIR/$backup_name"
    
    log "Backing up container data: $container_name"
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        # 容器运行中，使用docker cp
        local temp_dir="/tmp/backup_${container_name}_$$"
        mkdir -p "$temp_dir"
        
        docker cp "${container_name}:${data_path}" "$temp_dir/" || {
            log "WARNING: Failed to backup from running container $container_name"
            rm -rf "$temp_dir"
            return 1
        }
        
        tar -czf "$backup_file" -C "$temp_dir" . || {
            log "ERROR: Failed to create backup archive"
            rm -rf "$temp_dir"
            return 1
        }
        
        rm -rf "$temp_dir"
    else
        # 容器停止，直接备份数据卷
        if docker volume inspect "${container_name}-data" >/dev/null 2>&1; then
            docker run --rm -v "${container_name}-data:/data" -v "$BACKUP_DIR:/backup" alpine \
                tar -czf "/backup/$backup_name" -C /data . || {
                log "ERROR: Failed to backup volume data"
                return 1
            }
        else
            log "WARNING: No data volume found for $container_name"
            return 1
        fi
    fi
    
    local backup_size="$(du -h "$backup_file" | cut -f1)"
    log "Backup created: $backup_name ($backup_size)"
    return 0
}

# 备份应用配置
backup_config() {
    local backup_name="$(generate_backup_name "config")"
    local backup_file="$BACKUP_DIR/$backup_name"
    
    log "Backing up application configuration"
    
    local config_files=(
        "$PROJECT_ROOT/docker-compose*.yml"
        "$PROJECT_ROOT/Dockerfile*"
        "$PROJECT_ROOT/nginx*.conf"
        "$PROJECT_ROOT/config/"
        "$PROJECT_ROOT/monitoring/"
        "$PROJECT_ROOT/.env*"
    )
    
    tar -czf "$backup_file" -C "$PROJECT_ROOT" \
        --exclude="node_modules" \
        --exclude=".git" \
        --exclude="dist" \
        --exclude="logs" \
        --exclude="data/backups" \
        $(printf "%s " "${config_files[@]}" | sed "s|$PROJECT_ROOT/||g") 2>/dev/null || {
        log "WARNING: Some config files may not have been backed up"
    }
    
    local backup_size="$(du -h "$backup_file" | cut -f1)"
    log "Config backup created: $backup_name ($backup_size)"
}

# 备份Redis数据
backup_redis() {
    local container_name="online-time-redis"
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        log "Backing up Redis data"
        
        # 触发Redis保存
        docker exec "$container_name" redis-cli BGSAVE || {
            log "WARNING: Failed to trigger Redis BGSAVE"
        }
        
        # 等待保存完成
        sleep 5
        
        # 备份数据文件
        backup_container_data "$container_name" "/data"
    else
        log "Redis container is not running, skipping backup"
    fi
}

# 备份监控数据
backup_monitoring() {
    local services=("prometheus" "grafana" "loki")
    
    for service in "${services[@]}"; do
        local container_name="online-time-$service"
        if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
            log "Backing up $service data"
            
            case "$service" in
                "prometheus")
                    backup_container_data "$container_name" "/prometheus"
                    ;;
                "grafana")
                    backup_container_data "$container_name" "/var/lib/grafana"
                    ;;
                "loki")
                    backup_container_data "$container_name" "/loki"
                    ;;
            esac
        else
            log "$service container is not running, skipping backup"
        fi
    done
}

# 清理过期备份
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"
    
    local deleted_count=0
    
    # 查找并删除过期文件
    while IFS= read -r -d '' file; do
        rm "$file"
        log "Deleted old backup: $(basename "$file")"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -print0 2>/dev/null || true)
    
    log "Cleaned up $deleted_count old backup files"
}

# 验证备份文件
validate_backup() {
    local backup_file="$1"
    
    if [[ -f "$backup_file" ]]; then
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            log "Backup validation successful: $(basename "$backup_file")"
            return 0
        else
            log "ERROR: Backup validation failed: $(basename "$backup_file")"
            return 1
        fi
    else
        log "ERROR: Backup file not found: $(basename "$backup_file")"
        return 1
    fi
}

# 生成备份报告
generate_backup_report() {
    local report_file="$BACKUP_DIR/backup_report_$(date +%Y%m%d).txt"
    
    {
        echo "=== Backup Report - $(date) ==="
        echo "Backup Directory: $BACKUP_DIR"
        echo "Retention Policy: $RETENTION_DAYS days"
        echo ""
        echo "Current Backup Files:"
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backup files found"
        echo ""
        echo "Disk Usage:"
        du -sh "$BACKUP_DIR"
    } > "$report_file"
    
    log "Backup report generated: $report_file"
}

# 主备份流程
main() {
    local backup_type="${1:-full}"
    
    log "=== Backup Started ($backup_type) ==="
    
    case "$backup_type" in
        "config")
            backup_config
            ;;
        "data")
            backup_redis
            backup_monitoring
            ;;
        "full"|*)
            backup_config
            backup_redis
            backup_monitoring
            ;;
    esac
    
    # 清理过期备份
    cleanup_old_backups
    
    # 生成报告
    generate_backup_report
    
    log "=== Backup Completed ==="
}

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi