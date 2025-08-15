import { createRouter, createWebHistory } from 'vue-router'
import Home from './Home.vue'

const router = createRouter({
  history: createWebHistory('/'),
  routes: [
    {
        path: '/app',
        redirect: '/app/home',
    },
    {
      path: '/app/home',
      name: 'home',
      component: Home
    }
  ]
})

export default router
