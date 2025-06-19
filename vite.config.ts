import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  base: '/app/',
  plugins: [
    vue({
      template: {
        compilerOptions: {
          isCustomElement: tag => (tag.startsWith('ion-') || tag.startsWith('trix-')),
        }
      }
    }),
    RubyPlugin(),
  ],
})
