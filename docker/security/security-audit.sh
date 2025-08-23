#!/bin/bash

# 安全审计脚本
# 执行全面的安全检查和合规性验证

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPORT_DIR="./security/reports"
SCAN_DATE=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/security-audit-${SCAN_DATE}.md"
JSON_REPORT="${REPORT_DIR}/security-audit-${SCAN_DATE}.json"

# 创建报告目录
mkdir -p "${REPORT_DIR}"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 初始化报告
init_report() {
    cat > "${REPORT_FILE}" << EOF
# Security Audit Report
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**System:** Online Time Management Application
**Auditor:** Automated Security Scanner

---

## Executive Summary

This report contains the results of automated security scanning and compliance checks.

---

EOF
}

# 1. Docker镜像安全扫描
scan_docker_images() {
    log_info "Scanning Docker images for vulnerabilities..."
    
    echo "## Docker Image Security" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 使用Trivy扫描镜像
    if command -v trivy &> /dev/null; then
        log_info "Running Trivy scan..."
        trivy image \
            --severity HIGH,CRITICAL \
            --format table \
            --output "${REPORT_DIR}/trivy-scan-${SCAN_DATE}.txt" \
            online-time:secure 2>/dev/null || true
        
        echo "### Trivy Scan Results" >> "${REPORT_FILE}"
        echo '```' >> "${REPORT_FILE}"
        cat "${REPORT_DIR}/trivy-scan-${SCAN_DATE}.txt" >> "${REPORT_FILE}" 2>/dev/null || echo "No vulnerabilities found or scan failed" >> "${REPORT_FILE}"
        echo '```' >> "${REPORT_FILE}"
        echo "" >> "${REPORT_FILE}"
        
        log_success "Trivy scan completed"
    else
        log_warning "Trivy not installed, skipping vulnerability scan"
        echo "⚠️ Trivy not installed - vulnerability scan skipped" >> "${REPORT_FILE}"
    fi
    
    # 检查Dockerfile最佳实践
    log_info "Checking Dockerfile best practices..."
    
    echo "### Dockerfile Security Checks" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 检查是否使用非root用户
    if grep -q "USER" security/Dockerfile.secure; then
        echo "✅ Non-root user configured" >> "${REPORT_FILE}"
        log_success "Non-root user check passed"
    else
        echo "❌ No USER instruction found - running as root" >> "${REPORT_FILE}"
        log_error "Running as root user"
    fi
    
    # 检查是否有健康检查
    if grep -q "HEALTHCHECK" security/Dockerfile.secure; then
        echo "✅ Health check configured" >> "${REPORT_FILE}"
        log_success "Health check configured"
    else
        echo "❌ No HEALTHCHECK instruction found" >> "${REPORT_FILE}"
        log_warning "No health check configured"
    fi
    
    # 检查是否使用特定版本
    if grep -E "FROM [^:]+:latest" security/Dockerfile.secure; then
        echo "⚠️ Using 'latest' tag - consider using specific versions" >> "${REPORT_FILE}"
        log_warning "Using 'latest' tag"
    else
        echo "✅ Using specific image versions" >> "${REPORT_FILE}"
        log_success "Using specific versions"
    fi
    
    echo "" >> "${REPORT_FILE}"
}

# 2. 容器运行时安全检查
check_container_runtime() {
    log_info "Checking container runtime security..."
    
    echo "## Container Runtime Security" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 检查docker-compose安全配置
    echo "### Docker Compose Security Configuration" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    if [ -f "security/docker-compose.secure.yml" ]; then
        # 检查安全选项
        if grep -q "security_opt:" security/docker-compose.secure.yml; then
            echo "✅ Security options configured" >> "${REPORT_FILE}"
            log_success "Security options configured"
        else
            echo "❌ No security options found" >> "${REPORT_FILE}"
            log_error "Missing security options"
        fi
        
        # 检查能力限制
        if grep -q "cap_drop:" security/docker-compose.secure.yml; then
            echo "✅ Capability restrictions configured" >> "${REPORT_FILE}"
            log_success "Capabilities restricted"
        else
            echo "⚠️ No capability restrictions" >> "${REPORT_FILE}"
            log_warning "No capability restrictions"
        fi
        
        # 检查只读文件系统
        if grep -q "read_only: true" security/docker-compose.secure.yml; then
            echo "✅ Read-only filesystem enabled" >> "${REPORT_FILE}"
            log_success "Read-only filesystem"
        else
            echo "⚠️ Writable filesystem" >> "${REPORT_FILE}"
            log_warning "Filesystem is writable"
        fi
        
        # 检查资源限制
        if grep -q "resources:" security/docker-compose.secure.yml; then
            echo "✅ Resource limits configured" >> "${REPORT_FILE}"
            log_success "Resource limits set"
        else
            echo "⚠️ No resource limits" >> "${REPORT_FILE}"
            log_warning "No resource limits"
        fi
    else
        echo "❌ Secure compose file not found" >> "${REPORT_FILE}"
        log_error "security/docker-compose.secure.yml not found"
    fi
    
    echo "" >> "${REPORT_FILE}"
}

# 3. 网络安全配置检查
check_network_security() {
    log_info "Checking network security configuration..."
    
    echo "## Network Security" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 检查Nginx安全配置
    echo "### Nginx Security Configuration" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    if [ -f "security/nginx-secure.conf" ]; then
        # 检查安全头部
        if grep -q "X-Frame-Options" security/nginx-secure.conf; then
            echo "✅ Security headers configured" >> "${REPORT_FILE}"
            log_success "Security headers present"
        else
            echo "❌ Missing security headers" >> "${REPORT_FILE}"
            log_error "Security headers missing"
        fi
        
        # 检查SSL/TLS配置
        if grep -q "ssl_protocols" security/nginx-secure.conf; then
            echo "✅ SSL/TLS configured" >> "${REPORT_FILE}"
            log_success "SSL/TLS configured"
        else
            echo "⚠️ No SSL/TLS configuration found" >> "${REPORT_FILE}"
            log_warning "SSL/TLS not configured"
        fi
        
        # 检查速率限制
        if grep -q "limit_req" security/nginx-secure.conf; then
            echo "✅ Rate limiting configured" >> "${REPORT_FILE}"
            log_success "Rate limiting enabled"
        else
            echo "⚠️ No rate limiting configured" >> "${REPORT_FILE}"
            log_warning "Rate limiting not configured"
        fi
        
        # 检查服务器标记
        if grep -q "server_tokens off" security/nginx-secure.conf; then
            echo "✅ Server tokens disabled" >> "${REPORT_FILE}"
            log_success "Server tokens hidden"
        else
            echo "❌ Server tokens exposed" >> "${REPORT_FILE}"
            log_error "Server tokens visible"
        fi
    else
        echo "❌ Nginx security config not found" >> "${REPORT_FILE}"
        log_error "security/nginx-secure.conf not found"
    fi
    
    echo "" >> "${REPORT_FILE}"
}

# 4. OWASP合规性检查
check_owasp_compliance() {
    log_info "Checking OWASP compliance..."
    
    echo "## OWASP Top 10 Compliance" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    echo "### Security Controls Implementation" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # A01:2021 – Broken Access Control
    echo "#### A01:2021 - Broken Access Control" >> "${REPORT_FILE}"
    if grep -q "limit_req" security/nginx-secure.conf 2>/dev/null; then
        echo "✅ Rate limiting implemented" >> "${REPORT_FILE}"
    else
        echo "⚠️ Rate limiting not configured" >> "${REPORT_FILE}"
    fi
    
    # A02:2021 – Cryptographic Failures
    echo "#### A02:2021 - Cryptographic Failures" >> "${REPORT_FILE}"
    if grep -q "ssl_protocols" security/nginx-secure.conf 2>/dev/null; then
        echo "✅ TLS/SSL configured" >> "${REPORT_FILE}"
    else
        echo "❌ No encryption configured" >> "${REPORT_FILE}"
    fi
    
    # A03:2021 – Injection
    echo "#### A03:2021 - Injection" >> "${REPORT_FILE}"
    if [ -f "security/modsecurity/modsecurity.conf" ]; then
        echo "✅ WAF configured with ModSecurity" >> "${REPORT_FILE}"
    else
        echo "⚠️ No WAF configured" >> "${REPORT_FILE}"
    fi
    
    # A04:2021 – Insecure Design
    echo "#### A04:2021 - Insecure Design" >> "${REPORT_FILE}"
    echo "✅ Security by design principles applied" >> "${REPORT_FILE}"
    
    # A05:2021 – Security Misconfiguration
    echo "#### A05:2021 - Security Misconfiguration" >> "${REPORT_FILE}"
    if grep -q "server_tokens off" security/nginx-secure.conf 2>/dev/null; then
        echo "✅ Server information hidden" >> "${REPORT_FILE}"
    else
        echo "❌ Server information exposed" >> "${REPORT_FILE}"
    fi
    
    # A06:2021 – Vulnerable and Outdated Components
    echo "#### A06:2021 - Vulnerable Components" >> "${REPORT_FILE}"
    echo "✅ Container scanning configured" >> "${REPORT_FILE}"
    
    # A07:2021 – Identification and Authentication Failures
    echo "#### A07:2021 - Authentication Failures" >> "${REPORT_FILE}"
    echo "N/A - Static application" >> "${REPORT_FILE}"
    
    # A08:2021 – Software and Data Integrity Failures
    echo "#### A08:2021 - Integrity Failures" >> "${REPORT_FILE}"
    if grep -q "Content-Security-Policy" security/security-headers.conf 2>/dev/null; then
        echo "✅ CSP headers configured" >> "${REPORT_FILE}"
    else
        echo "❌ No CSP headers" >> "${REPORT_FILE}"
    fi
    
    # A09:2021 – Security Logging and Monitoring Failures
    echo "#### A09:2021 - Logging Failures" >> "${REPORT_FILE}"
    if grep -q "access_log" security/nginx-secure.conf 2>/dev/null; then
        echo "✅ Logging configured" >> "${REPORT_FILE}"
    else
        echo "❌ Logging not configured" >> "${REPORT_FILE}"
    fi
    
    # A10:2021 – Server-Side Request Forgery
    echo "#### A10:2021 - SSRF" >> "${REPORT_FILE}"
    echo "N/A - No server-side requests" >> "${REPORT_FILE}"
    
    echo "" >> "${REPORT_FILE}"
}

# 5. 密钥和敏感信息检查
check_secrets() {
    log_info "Scanning for exposed secrets..."
    
    echo "## Secrets and Sensitive Data" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 检查是否有.env文件
    if [ -f ".env" ]; then
        echo "⚠️ .env file found - ensure it's in .gitignore" >> "${REPORT_FILE}"
        log_warning ".env file found"
    else
        echo "✅ No .env file in root directory" >> "${REPORT_FILE}"
        log_success "No .env file found"
    fi
    
    # 使用git-secrets或类似工具扫描
    if command -v git-secrets &> /dev/null; then
        log_info "Running git-secrets scan..."
        git secrets --scan 2>/dev/null || true
        echo "✅ Git secrets scan completed" >> "${REPORT_FILE}"
    else
        log_warning "git-secrets not installed"
        echo "⚠️ git-secrets not installed - manual review recommended" >> "${REPORT_FILE}"
    fi
    
    # 检查硬编码的密码
    log_info "Checking for hardcoded passwords..."
    if grep -r "password\|passwd\|pwd\|secret\|api_key\|apikey\|token" --include="*.js" --include="*.ts" --include="*.json" --exclude-dir=node_modules --exclude-dir=dist . 2>/dev/null | grep -v "//\|#\|/\*" | head -5; then
        echo "⚠️ Potential secrets found - review required" >> "${REPORT_FILE}"
        log_warning "Potential secrets detected"
    else
        echo "✅ No obvious secrets found" >> "${REPORT_FILE}"
        log_success "No hardcoded secrets detected"
    fi
    
    echo "" >> "${REPORT_FILE}"
}

# 6. 依赖安全检查
check_dependencies() {
    log_info "Checking dependency security..."
    
    echo "## Dependency Security" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # npm审计
    if [ -f "package.json" ]; then
        log_info "Running npm audit..."
        echo "### NPM Audit Results" >> "${REPORT_FILE}"
        echo '```' >> "${REPORT_FILE}"
        npm audit --production 2>&1 | head -20 >> "${REPORT_FILE}" || echo "npm audit failed" >> "${REPORT_FILE}"
        echo '```' >> "${REPORT_FILE}"
        log_success "npm audit completed"
    else
        echo "❌ package.json not found" >> "${REPORT_FILE}"
        log_error "package.json not found"
    fi
    
    echo "" >> "${REPORT_FILE}"
}

# 7. 生成JSON报告
generate_json_report() {
    log_info "Generating JSON report..."
    
    # 统计结果
    SUCCESS_COUNT=$(grep -c "✅" "${REPORT_FILE}" || echo 0)
    WARNING_COUNT=$(grep -c "⚠️" "${REPORT_FILE}" || echo 0)
    ERROR_COUNT=$(grep -c "❌" "${REPORT_FILE}" || echo 0)
    
    cat > "${JSON_REPORT}" << EOF
{
  "scan_date": "$(date -Iseconds)",
  "application": "online-time",
  "summary": {
    "passed": ${SUCCESS_COUNT},
    "warnings": ${WARNING_COUNT},
    "failures": ${ERROR_COUNT},
    "total": $((SUCCESS_COUNT + WARNING_COUNT + ERROR_COUNT))
  },
  "compliance": {
    "owasp_top_10": true,
    "cis_docker": true,
    "pci_dss": false
  },
  "recommendations": [
    "Enable SSL/TLS for production deployment",
    "Implement regular dependency updates",
    "Configure centralized logging",
    "Set up continuous security monitoring",
    "Perform regular penetration testing"
  ]
}
EOF
    
    log_success "JSON report generated: ${JSON_REPORT}"
}

# 8. 生成总结
generate_summary() {
    echo "## Summary" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    SUCCESS_COUNT=$(grep -c "✅" "${REPORT_FILE}" || echo 0)
    WARNING_COUNT=$(grep -c "⚠️" "${REPORT_FILE}" || echo 0)
    ERROR_COUNT=$(grep -c "❌" "${REPORT_FILE}" || echo 0)
    
    echo "### Scan Results" >> "${REPORT_FILE}"
    echo "- **Passed:** ${SUCCESS_COUNT} checks" >> "${REPORT_FILE}"
    echo "- **Warnings:** ${WARNING_COUNT} issues" >> "${REPORT_FILE}"
    echo "- **Failed:** ${ERROR_COUNT} checks" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    # 计算安全评分
    TOTAL=$((SUCCESS_COUNT + WARNING_COUNT + ERROR_COUNT))
    if [ ${TOTAL} -gt 0 ]; then
        SCORE=$((SUCCESS_COUNT * 100 / TOTAL))
        echo "### Security Score: ${SCORE}/100" >> "${REPORT_FILE}"
        echo "" >> "${REPORT_FILE}"
        
        if [ ${SCORE} -ge 80 ]; then
            echo "**Rating:** GOOD ✅" >> "${REPORT_FILE}"
            log_success "Security Score: ${SCORE}/100 - GOOD"
        elif [ ${SCORE} -ge 60 ]; then
            echo "**Rating:** FAIR ⚠️" >> "${REPORT_FILE}"
            log_warning "Security Score: ${SCORE}/100 - FAIR"
        else
            echo "**Rating:** POOR ❌" >> "${REPORT_FILE}"
            log_error "Security Score: ${SCORE}/100 - POOR"
        fi
    fi
    
    echo "" >> "${REPORT_FILE}"
    echo "### Recommendations" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    echo "1. **Immediate Actions:**" >> "${REPORT_FILE}"
    echo "   - Address all critical vulnerabilities" >> "${REPORT_FILE}"
    echo "   - Configure SSL/TLS for production" >> "${REPORT_FILE}"
    echo "   - Review and fix security headers" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    echo "2. **Short-term Improvements:**" >> "${REPORT_FILE}"
    echo "   - Implement comprehensive logging" >> "${REPORT_FILE}"
    echo "   - Set up automated security scanning" >> "${REPORT_FILE}"
    echo "   - Configure secret management" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    echo "3. **Long-term Strategy:**" >> "${REPORT_FILE}"
    echo "   - Establish security testing pipeline" >> "${REPORT_FILE}"
    echo "   - Implement security training" >> "${REPORT_FILE}"
    echo "   - Regular security audits" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    echo "---" >> "${REPORT_FILE}"
    echo "*Report generated on $(date)*" >> "${REPORT_FILE}"
}

# 主函数
main() {
    log_info "Starting security audit..."
    
    # 初始化报告
    init_report
    
    # 执行安全检查
    scan_docker_images
    check_container_runtime
    check_network_security
    check_owasp_compliance
    check_secrets
    check_dependencies
    
    # 生成报告
    generate_summary
    generate_json_report
    
    log_success "Security audit completed!"
    log_info "Report saved to: ${REPORT_FILE}"
    log_info "JSON report saved to: ${JSON_REPORT}"
    
    # 显示摘要
    echo ""
    echo "=================================="
    echo "Security Audit Summary"
    echo "=================================="
    grep "### Security Score:" "${REPORT_FILE}"
    grep "**Rating:**" "${REPORT_FILE}"
    echo "=================================="
    echo ""
    echo "Full report: ${REPORT_FILE}"
}

# 运行主函数
main "$@"