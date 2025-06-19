import { createRouter, createWebHistory } from 'vue-router'
import AdminHome from './Home.vue'

const router = createRouter({
  history: createWebHistory('/'),
  routes: [
    {
        path: '/admin',
        redirect: '/admin/home',
    },
    {
      path: '/admin/home',
      name: 'home',
      component: AdminHome
    }
  ]
})

export default router
