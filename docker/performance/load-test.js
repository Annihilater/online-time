// k6 性能测试脚本
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const homePageDuration = new Trend('home_page_duration');
const staticResourceDuration = new Trend('static_resource_duration');
const apiDuration = new Trend('api_duration');

// 测试配置
export const options = {
  // 测试阶段
  stages: [
    { duration: '2m', target: 100 },  // 逐步增加到100个用户
    { duration: '5m', target: 100 },  // 保持100个用户5分钟
    { duration: '2m', target: 200 },  // 增加到200个用户
    { duration: '5m', target: 200 },  // 保持200个用户5分钟
    { duration: '2m', target: 300 },  // 增加到300个用户
    { duration: '5m', target: 300 },  // 保持300个用户5分钟
    { duration: '5m', target: 0 },    // 逐步减少到0
  ],
  
  // 阈值设置
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95%请求<500ms, 99%<1s
    errors: ['rate<0.01'],                           // 错误率<1%
    home_page_duration: ['p(95)<300'],               // 首页加载95%<300ms
    static_resource_duration: ['p(95)<100'],         // 静态资源95%<100ms
    api_duration: ['p(95)<200'],                     // API调用95%<200ms
  },
  
  // 其他选项
  noConnectionReuse: false,
  userAgent: 'K6 Performance Test',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost';

// 测试场景
export default function () {
  // 场景1: 访问首页
  let homeResponse = http.get(`${BASE_URL}/`, {
    tags: { name: 'HomePage' },
  });
  
  check(homeResponse, {
    'Home page status is 200': (r) => r.status === 200,
    'Home page load time < 500ms': (r) => r.timings.duration < 500,
  });
  
  homePageDuration.add(homeResponse.timings.duration);
  errorRate.add(homeResponse.status !== 200);
  
  sleep(1);
  
  // 场景2: 加载静态资源
  const resources = [
    '/js/react-core.js',
    '/js/router.js',
    '/js/ui-kit.js',
    '/css/index.css',
    '/images/logo.png',
  ];
  
  const responses = http.batch(
    resources.map(resource => ({
      method: 'GET',
      url: `${BASE_URL}${resource}`,
      params: {
        tags: { name: 'StaticResource' },
      },
    }))
  );
  
  responses.forEach(response => {
    check(response, {
      'Static resource status is 200': (r) => r.status === 200,
      'Static resource cached': (r) => r.headers['Cache-Control'] && r.headers['Cache-Control'].includes('immutable'),
    });
    staticResourceDuration.add(response.timings.duration);
    errorRate.add(response.status !== 200);
  });
  
  sleep(1);
  
  // 场景3: 导航到不同页面
  const pages = [
    '/clock',
    '/timer',
    '/stopwatch',
    '/world-clock',
    '/date-calculator',
  ];
  
  const randomPage = pages[Math.floor(Math.random() * pages.length)];
  let pageResponse = http.get(`${BASE_URL}${randomPage}`, {
    tags: { name: 'PageNavigation' },
  });
  
  check(pageResponse, {
    'Page status is 200': (r) => r.status === 200,
    'Page load time < 300ms': (r) => r.timings.duration < 300,
  });
  
  errorRate.add(pageResponse.status !== 200);
  
  sleep(2);
  
  // 场景4: API调用模拟（如果有后端）
  if (__ENV.TEST_API === 'true') {
    let apiResponse = http.get(`${BASE_URL}/api/health`, {
      tags: { name: 'APICall' },
    });
    
    check(apiResponse, {
      'API status is 200': (r) => r.status === 200,
      'API response time < 200ms': (r) => r.timings.duration < 200,
    });
    
    apiDuration.add(apiResponse.timings.duration);
    errorRate.add(apiResponse.status !== 200);
  }
  
  sleep(Math.random() * 3 + 1); // 随机等待1-4秒
}

// 生命周期钩子
export function setup() {
  console.log('Performance test starting...');
  console.log(`Testing URL: ${BASE_URL}`);
  
  // 预热请求
  let warmupResponse = http.get(`${BASE_URL}/`);
  if (warmupResponse.status !== 200) {
    throw new Error(`Target ${BASE_URL} is not accessible`);
  }
  
  return { startTime: new Date().toISOString() };
}

export function teardown(data) {
  console.log('Performance test completed.');
  console.log(`Started at: ${data.startTime}`);
  console.log(`Ended at: ${new Date().toISOString()}`);
}

// 自定义摘要处理
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'performance-report.json': JSON.stringify(data, null, 2),
    'performance-report.html': htmlReport(data),
  };
}

// HTML报告生成函数
function htmlReport(data) {
  const metrics = data.metrics;
  return `
<!DOCTYPE html>
<html>
<head>
    <title>Performance Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .metric { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
        th { background: #4CAF50; color: white; }
    </style>
</head>
<body>
    <h1>Performance Test Report</h1>
    <p>Test completed at: ${new Date().toISOString()}</p>
    
    <h2>Key Metrics</h2>
    <div class="metric">
        <strong>Total Requests:</strong> ${metrics.http_reqs.values.count}
    </div>
    <div class="metric">
        <strong>Request Duration (p95):</strong> ${metrics.http_req_duration.values['p(95)']}ms
    </div>
    <div class="metric">
        <strong>Error Rate:</strong> ${(metrics.errors.values.rate * 100).toFixed(2)}%
    </div>
    
    <h2>Detailed Results</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
            <th>Threshold</th>
            <th>Status</th>
        </tr>
        ${Object.entries(metrics).map(([key, value]) => `
        <tr>
            <td>${key}</td>
            <td>${JSON.stringify(value.values)}</td>
            <td>${value.thresholds ? JSON.stringify(value.thresholds) : 'N/A'}</td>
            <td class="${value.thresholds?.passes ? 'pass' : 'fail'}">
                ${value.thresholds?.passes ? 'PASS' : 'FAIL'}
            </td>
        </tr>
        `).join('')}
    </table>
</body>
</html>
  `;
}