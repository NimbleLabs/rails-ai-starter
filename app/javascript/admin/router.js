import { createRouter, createWebHistory } from 'vue-router'
import AdminHome from './Home.vue'
import Users from "@/admin/views/Users.vue";
import UserDetails from "@/admin/views/UserDetails.vue";

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
    },
    {
      path: '/admin/user/:id',
      name: 'user-details',
      component: UserDetails
    }
  ]
})

export default router
