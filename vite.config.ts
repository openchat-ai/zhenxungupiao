import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Capacitor 从本地 file:// 加载资源，必须用相对路径
  base: './',
  server: {
    host: true,
    port: 5173,
  },
  build: {
    target: 'es2020',
  },
});
