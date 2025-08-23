import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// 高性能Vite配置
export default defineConfig({
  plugins: [
    react({
      // 使用SWC加速编译
      babel: {
        plugins: [
          ['@babel/plugin-transform-runtime', {
            regenerator: false,
            useESModules: true
          }]
        ]
      }
    })
  ],
  
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "../src"),
    },
  },
  
  server: {
    port: 3000,
    open: true,
    // 预加载
    warmup: {
      clientFiles: ['./src/main.tsx', './src/App.tsx']
    }
  },
  
  build: {
    // 目标浏览器
    target: 'es2015',
    
    // CSS代码分割
    cssCodeSplit: true,
    
    // 源码映射
    sourcemap: false,
    
    // Rollup选项
    rollupOptions: {
      output: {
        // 高级分包策略
        manualChunks: (id) => {
          // 核心React运行时
          if (id.includes('react') || id.includes('react-dom')) {
            return 'react-core'
          }
          // 路由
          if (id.includes('react-router')) {
            return 'router'
          }
          // UI组件库
          if (id.includes('lucide-react') || id.includes('daisyui')) {
            return 'ui-kit'
          }
          // 工具库
          if (id.includes('date-fns')) {
            return 'date-utils'
          }
          if (id.includes('zustand')) {
            return 'state'
          }
          // 其他第三方
          if (id.includes('node_modules')) {
            return 'vendor'
          }
          // 页面组件
          if (id.includes('/pages/')) {
            const page = id.split('/pages/')[1].split('/')[0]
            return `page-${page}`
          }
          // 共享组件
          if (id.includes('/shared/')) {
            return 'shared'
          }
        },
        
        // 文件命名策略
        chunkFileNames: (chunkInfo) => {
          const facadeModuleId = chunkInfo.facadeModuleId ? chunkInfo.facadeModuleId.split('/').pop() : 'chunk'
          return `js/[name]-${facadeModuleId}-[hash].js`
        },
        entryFileNames: 'js/[name]-[hash].js',
        assetFileNames: (assetInfo) => {
          const info = assetInfo.name.split('.')
          const ext = info[info.length - 1]
          if (/png|jpe?g|svg|gif|tiff|bmp|ico/i.test(ext)) {
            return `images/[name]-[hash][extname]`
          } else if (/woff|woff2|eot|ttf|otf/i.test(ext)) {
            return `fonts/[name]-[hash][extname]`
          } else if (/css/i.test(ext)) {
            return `css/[name]-[hash][extname]`
          }
          return `assets/[name]-[hash][extname]`
        }
      },
      
      // Tree shaking
      treeshake: {
        preset: 'recommended',
        moduleSideEffects: false,
        propertyReadSideEffects: false,
        tryCatchDeoptimization: false
      }
    },
    
    // 压缩选项
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.info'],
        passes: 2
      },
      mangle: {
        safari10: true
      },
      format: {
        comments: false
      }
    },
    
    // 资源内联阈值
    assetsInlineLimit: 4096,
    
    // Chunk大小警告
    chunkSizeWarningLimit: 500,
    
    // 报告压缩大小
    reportCompressedSize: false
  },
  
  // 依赖优化
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router-dom',
      'zustand',
      'date-fns',
      'lucide-react'
    ],
    exclude: ['@vitejs/plugin-react'],
    esbuildOptions: {
      target: 'es2015',
      define: {
        global: 'globalThis'
      }
    }
  },
  
  // CSS配置
  css: {
    modules: {
      localsConvention: 'camelCase',
      generateScopedName: '[name]__[local]__[hash:base64:5]'
    }
  }
})