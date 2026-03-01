import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      // Allow Vite to resolve .js imports to .ts source files
    },
    extensions: ['.ts', '.js', '.mjs', '.json'],
  },
  test: {
    globals: true,
    include: ['tests/integration/**/*.test.ts'],
    testTimeout: 15000,
    hookTimeout: 15000,
    coverage: {
      provider: 'v8',
      include: ['src/modules/**', 'src/middleware/**'],
      reporter: ['text', 'text-summary'],
    },
  },
});
