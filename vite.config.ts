import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: 3000,
    open: true,
  },
  build: {
    // 启用代码分割和优化
    rollupOptions: {
      output: {
        // 手动分包策略 - 将大型依赖库分离
        manualChunks: (id) => {
          // 第三方库
          if (id.includes('node_modules')) {
            // 将React相关库打包到一起
            if (id.includes('react') || id.includes('react-dom')) {
              return 'react'
            }
            // 将路由相关库打包到一起
            if (id.includes('react-router-dom')) {
              return 'router'
            }
            // UI 相关库
            if (id.includes('lucide-react') || id.includes('daisyui')) {
              return 'ui'
            }
            // 工具库
            if (id.includes('date-fns') || id.includes('zustand')) {
              return 'utils'
            }
            // 其他第三方库
            return 'vendor'
          }
          // 应用代码按模块分离
          if (id.includes('/pages/')) {
            return 'pages'
          }
          if (id.includes('/shared/')) {
            return 'shared'
          }
        }
      },
      // 启用tree shaking
      treeshake: {
        preset: 'recommended',
        moduleSideEffects: false
      }
    },
    // 压缩配置
    minify: 'esbuild',
    // 资源内联阈值 (4KB以下内联)
    assetsInlineLimit: 4096,
    // 清理输出目录
    emptyOutDir: true,
    // 设置chunk大小警告阈值 (500KB)
    chunkSizeWarningLimit: 500
  },
  // 优化预构建
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom', 'zustand', 'date-fns', 'lucide-react'],
    exclude: ['@vitejs/plugin-react']
  },
  // CSS优化
  css: {
    devSourcemap: true
  }
})
