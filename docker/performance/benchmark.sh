#!/bin/bash

# 性能基准测试脚本
# 用于测试和验证性能优化效果

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
BASE_URL=${BASE_URL:-"http://localhost"}
CONCURRENT_USERS=${CONCURRENT_USERS:-100}
TEST_DURATION=${TEST_DURATION:-60}
REPORT_DIR="./performance-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建报告目录
mkdir -p $REPORT_DIR

# 打印标题
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Online Time Performance Benchmark Test    ${NC}"
echo -e "${BLUE}================================================${NC}"
echo

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local deps=("docker" "curl" "ab" "siege")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=($dep)
            echo -e "${RED}✗ $dep not found${NC}"
        else
            echo -e "${GREEN}✓ $dep found${NC}"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}Installing missing dependencies...${NC}"
        
        # 安装缺失的依赖
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            brew install apache-bench siege
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo apt-get update
            sudo apt-get install -y apache2-utils siege
        fi
    fi
    
    echo
}

# 启动服务
start_services() {
    echo -e "${YELLOW}Starting services...${NC}"
    
    # 构建优化镜像
    docker build -f performance/Dockerfile.optimized -t online-time:performance .
    
    # 启动服务
    docker-compose -f performance/docker-compose.performance.yml up -d
    
    # 等待服务就绪
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 10
    
    # 健康检查
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s $BASE_URL/health > /dev/null; then
            echo -e "${GREEN}✓ Services are ready${NC}"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}✗ Services failed to start${NC}"
        exit 1
    fi
    
    echo
}

# 运行Apache Bench测试
run_ab_test() {
    echo -e "${BLUE}Running Apache Bench test...${NC}"
    
    local endpoints=(
        "/"
        "/clock"
        "/timer"
        "/stopwatch"
    )
    
    for endpoint in "${endpoints[@]}"; do
        echo -e "${YELLOW}Testing $endpoint...${NC}"
        
        ab -n 1000 -c $CONCURRENT_USERS \
           -g $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.tsv \
           -e $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.csv \
           $BASE_URL$endpoint > $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.txt
        
        # 提取关键指标
        local rps=$(grep "Requests per second" $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.txt | awk '{print $4}')
        local p50=$(grep "50%" $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.txt | awk '{print $2}')
        local p99=$(grep "99%" $REPORT_DIR/ab_${endpoint//\//_}_$TIMESTAMP.txt | awk '{print $2}')
        
        echo -e "${GREEN}  RPS: $rps req/s${NC}"
        echo -e "${GREEN}  P50: ${p50}ms${NC}"
        echo -e "${GREEN}  P99: ${p99}ms${NC}"
        echo
    done
}

# 运行Siege测试
run_siege_test() {
    echo -e "${BLUE}Running Siege test...${NC}"
    
    # 创建URL文件
    cat > $REPORT_DIR/urls.txt << EOF
$BASE_URL/
$BASE_URL/clock
$BASE_URL/timer
$BASE_URL/stopwatch
$BASE_URL/world-clock
$BASE_URL/date-calculator
EOF
    
    # 运行测试
    siege -c $CONCURRENT_USERS \
          -t ${TEST_DURATION}s \
          -f $REPORT_DIR/urls.txt \
          -l $REPORT_DIR/siege_$TIMESTAMP.log \
          --mark="Performance Test $TIMESTAMP" \
          > $REPORT_DIR/siege_$TIMESTAMP.txt 2>&1
    
    # 提取结果
    echo -e "${GREEN}Siege test completed. Results saved to $REPORT_DIR/siege_$TIMESTAMP.txt${NC}"
    echo
}

# 运行k6测试
run_k6_test() {
    echo -e "${BLUE}Running k6 test...${NC}"
    
    # 运行k6测试
    docker run --rm \
           --network performance_app-network \
           -v $PWD/performance:/scripts \
           -e BASE_URL=http://app \
           grafana/k6 run /scripts/load-test.js \
           --out json=$REPORT_DIR/k6_$TIMESTAMP.json \
           > $REPORT_DIR/k6_$TIMESTAMP.txt
    
    echo -e "${GREEN}k6 test completed. Results saved to $REPORT_DIR/k6_$TIMESTAMP.txt${NC}"
    echo
}

# 测试静态资源
test_static_resources() {
    echo -e "${BLUE}Testing static resource performance...${NC}"
    
    local resources=(
        "/js/react-core.js"
        "/css/index.css"
        "/images/logo.png"
    )
    
    for resource in "${resources[@]}"; do
        echo -e "${YELLOW}Testing $resource...${NC}"
        
        # 第一次请求（冷缓存）
        local cold_time=$(curl -o /dev/null -s -w '%{time_total}' $BASE_URL$resource)
        echo -e "${GREEN}  Cold cache: ${cold_time}s${NC}"
        
        # 第二次请求（热缓存）
        local hot_time=$(curl -o /dev/null -s -w '%{time_total}' $BASE_URL$resource)
        echo -e "${GREEN}  Hot cache: ${hot_time}s${NC}"
        
        # 检查缓存头
        local cache_control=$(curl -s -I $BASE_URL$resource | grep -i cache-control)
        echo -e "${GREEN}  Cache-Control: $cache_control${NC}"
        echo
    done
}

# 测试压缩
test_compression() {
    echo -e "${BLUE}Testing compression...${NC}"
    
    local test_files=(
        "/js/react-core.js"
        "/css/index.css"
    )
    
    for file in "${test_files[@]}"; do
        echo -e "${YELLOW}Testing $file...${NC}"
        
        # 无压缩
        local size_uncompressed=$(curl -s $BASE_URL$file | wc -c)
        
        # Gzip压缩
        local size_gzip=$(curl -s -H "Accept-Encoding: gzip" $BASE_URL$file | wc -c)
        
        # Brotli压缩
        local size_brotli=$(curl -s -H "Accept-Encoding: br" $BASE_URL$file | wc -c)
        
        echo -e "${GREEN}  Uncompressed: $size_uncompressed bytes${NC}"
        echo -e "${GREEN}  Gzip: $size_gzip bytes ($(echo "scale=2; $size_gzip * 100 / $size_uncompressed" | bc)%)${NC}"
        echo -e "${GREEN}  Brotli: $size_brotli bytes ($(echo "scale=2; $size_brotli * 100 / $size_uncompressed" | bc)%)${NC}"
        echo
    done
}

# 测试并发连接
test_concurrent_connections() {
    echo -e "${BLUE}Testing concurrent connections...${NC}"
    
    local connections=(10 50 100 200 500)
    
    for conn in "${connections[@]}"; do
        echo -e "${YELLOW}Testing with $conn concurrent connections...${NC}"
        
        ab -n 1000 -c $conn -q $BASE_URL/ > $REPORT_DIR/concurrent_${conn}_$TIMESTAMP.txt 2>&1
        
        local rps=$(grep "Requests per second" $REPORT_DIR/concurrent_${conn}_$TIMESTAMP.txt | awk '{print $4}')
        local failed=$(grep "Failed requests" $REPORT_DIR/concurrent_${conn}_$TIMESTAMP.txt | awk '{print $3}')
        
        echo -e "${GREEN}  RPS: $rps req/s${NC}"
        echo -e "${GREEN}  Failed: $failed${NC}"
        echo
    done
}

# 生成HTML报告
generate_html_report() {
    echo -e "${BLUE}Generating HTML report...${NC}"
    
    cat > $REPORT_DIR/report_$TIMESTAMP.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Performance Test Report - $TIMESTAMP</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }
        h2 {
            color: #666;
            margin-top: 30px;
        }
        .metric {
            display: inline-block;
            margin: 10px;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 5px;
            border-left: 4px solid #4CAF50;
        }
        .metric-label {
            color: #666;
            font-size: 12px;
            text-transform: uppercase;
        }
        .metric-value {
            color: #333;
            font-size: 24px;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #4CAF50;
            color: white;
        }
        .success { color: #4CAF50; }
        .warning { color: #FFC107; }
        .error { color: #F44336; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Performance Test Report</h1>
        <p>Generated: $(date)</p>
        <p>Base URL: $BASE_URL</p>
        
        <h2>Test Configuration</h2>
        <div class="metric">
            <div class="metric-label">Concurrent Users</div>
            <div class="metric-value">$CONCURRENT_USERS</div>
        </div>
        <div class="metric">
            <div class="metric-label">Test Duration</div>
            <div class="metric-value">${TEST_DURATION}s</div>
        </div>
        
        <h2>Test Results</h2>
        <p>Detailed results are available in the following files:</p>
        <ul>
            <li>Apache Bench: ab_*_$TIMESTAMP.txt</li>
            <li>Siege: siege_$TIMESTAMP.txt</li>
            <li>k6: k6_$TIMESTAMP.txt</li>
        </ul>
        
        <h2>Recommendations</h2>
        <ul>
            <li>Monitor response times regularly</li>
            <li>Implement caching strategies</li>
            <li>Optimize static resource delivery</li>
            <li>Use CDN for global distribution</li>
            <li>Enable HTTP/2 for better performance</li>
        </ul>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}✓ HTML report generated: $REPORT_DIR/report_$TIMESTAMP.html${NC}"
    echo
}

# 清理
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker-compose -f performance/docker-compose.performance.yml down
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    
    # 启动服务
    start_services
    
    # 运行测试
    run_ab_test
    test_static_resources
    test_compression
    test_concurrent_connections
    
    # 可选测试
    if command -v siege &> /dev/null; then
        run_siege_test
    fi
    
    if command -v docker &> /dev/null; then
        run_k6_test
    fi
    
    # 生成报告
    generate_html_report
    
    # 清理
    cleanup
    
    # 完成
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}     Performance test completed successfully!   ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}Reports saved to: $REPORT_DIR${NC}"
}

# 捕获中断信号
trap cleanup EXIT INT TERM

# 运行主函数
main