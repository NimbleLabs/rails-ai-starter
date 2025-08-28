import { createRouter, createWebHistory } from 'vue-router'
import AdminHome from './Home.vue'
import Users from "@/admin/views/Users.vue";
import UserDetails from "@/admin/views/UserDetails.vue";
import EmailTemplates from "@/admin/views/EmailTemplates.vue";
import EmailForm from "@/admin/views/EmailForm.vue";
import Contacts from "@/admin/views/Contacts.vue";

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
    },
    {
      path: '/admin/contacts',
      name: 'contacts',
      component: Contacts
    },
    {
      path: '/admin/email-templates',
      name: 'email-templates',
      component: EmailTemplates
    },
    {
      path: '/admin/new-email',
      name: 'new-email',
      component: EmailForm
    },
    {
      path: '/admin/edit-email/:id',
      name: 'edit-email',
      component: EmailForm
    }
  ]
})

export default router
