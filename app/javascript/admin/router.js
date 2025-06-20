import { createRouter, createWebHistory } from 'vue-router'
import AdminHome from './Home.vue'
import Users from "~/admin/Users.vue";

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
    },
    {
      path: '/admin/users',
      name: 'users',
      component: Users
    }
  ]
})

export default router
