# Vault配置文件
# 用于管理应用程序的敏感信息和密钥

# 存储配置
storage "file" {
  path = "/vault/data"
}

# 监听配置
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 0
  
  # TLS配置
  tls_cert_file = "/vault/config/cert.pem"
  tls_key_file  = "/vault/config/key.pem"
  
  # 最小TLS版本
  tls_min_version = "tls12"
  
  # 加密套件
  tls_cipher_suites = [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
  ]
  
  # 客户端证书验证
  tls_require_and_verify_client_cert = false
}

# API配置
api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"

# UI配置
ui = true

# 日志级别
log_level = "info"

# 最大租约时间
max_lease_ttl = "768h"
default_lease_ttl = "768h"

# 审计设备
# audit {
#   type = "file"
#   options = {
#     file_path = "/vault/logs/audit.log"
#   }
# }

# 性能配置
disable_mlock = true
disable_cache = false

# 遥测配置
telemetry {
  prometheus_retention_time = "0s"
  disable_hostname = false
}