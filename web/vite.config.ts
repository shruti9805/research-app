/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// GitHub Pages serves this repo at /research-app/, so the app must know its
// own base path — see PLAN.md DR-009 ("Deployment mechanism, decided").
export default defineConfig({
  base: '/research-app/',
  plugins: [react()],
  test: {
    // Default environment is plain Node (no jsdom) so the OCR/Excel checks
    // prove they run outside a browser — see PLAN.md DR-009's testability note.
    environment: 'node',
  },
})
