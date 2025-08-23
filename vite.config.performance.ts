import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// 性能优化的 Vite 配置
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
    // 启用代码分割
    rollupOptions: {
      output: {
        // 手动分包策略
        manualChunks: {
          // 将第三方库单独打包
          vendor: ['react', 'react-dom', 'react-router-dom'],
          ui: ['lucide-react', 'daisyui'],
          utils: ['date-fns', 'zustand'],
        }
      }
    },
    // 启用源码映射用于生产环境调试
    sourcemap: 'hidden',
    // 压缩配置
    minify: 'esbuild',
    // 资源内联阈值
    assetsInlineLimit: 4096,
    // 清理输出目录
    emptyOutDir: true,
    // 设置chunk大小警告阈值
    chunkSizeWarningLimit: 500,
  },
  // 优化预构建
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom', 'zustand', 'date-fns'],
    exclude: ['@vitejs/plugin-react']
  },
  // 启用 CSS 代码分割
  css: {
    devSourcemap: true
  }
})