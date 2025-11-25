import vue from '@vitejs/plugin-vue'
import react from '@vitejs/plugin-react'
import {defineConfig} from 'vite'
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
        react({
            jsxRuntime: 'classic',
            babel: {
                plugins: [
                    ['@babel/plugin-transform-react-jsx']
                ]
            }
        }),
    ],
})
