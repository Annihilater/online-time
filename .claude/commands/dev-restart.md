---
description: "重启开发服务器并进行基础检查"
allowed-tools: "Bash(*)"
---

重启开发环境：

🔄 **开发环境重启流程**

1. **停止现有进程**
!pkill -f "npm run dev" || true

2. **等待进程完全停止**
!sleep 2

3. **快速检查代码规范**
!npm run lint

4. **启动开发服务器**
!npm run dev

🚀 **开发环境已重启！**

浏览器将自动打开 http://localhost:3001