import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: '../dist',
    emptyOutDir: true,
  },
  server: {
    host: true,
    proxy: {
      '/api': process.env.API_PROXY_TARGET || 'http://localhost:8080',
    },
    watch: {
      usePolling: true,
      interval: 5000,
    },
  },
})
