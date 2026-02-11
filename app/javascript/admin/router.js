import { createRouter, createWebHistory } from 'vue-router'
import AdminHome from './Home.vue'
import Users from "@/admin/views/Users.vue";
import UserDetails from "@/admin/views/UserDetails.vue";
import EmailTemplates from "@/admin/views/EmailTemplates.vue";
import EmailForm from "@/admin/views/EmailForm.vue";
import Contacts from "@/admin/views/Contacts.vue";
import PostForm from "@/admin/views/articles/PostForm.vue";
import PostsList from "@/admin/views/articles/PostsList.vue";
import PostDetails from "@/admin/views/articles/PostDetails.vue";
import FunnelsList from "@/admin/views/funnels/FunnelsList.vue";
import FunnelForm from "@/admin/views/funnels/FunnelForm.vue";
import FunnelMetrics from "@/admin/views/funnels/FunnelMetrics.vue";
import FeaturesList from "@/admin/views/features/FeaturesList.vue";
import FeatureForm from "@/admin/views/features/FeatureForm.vue";

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
    },
    {
      path: '/admin/posts',
      name: 'posts',
      component: PostsList
    },
    {
      path: '/admin/new-post',
      name: 'new-post',
      component: PostForm
    },
    {
      path: '/admin/edit-post/:id',
      name: 'edit-post',
      component: PostForm
    },
    {
      path: '/admin/post-details/:id',
      name: 'post-details',
      component: PostDetails
    },
    {
      path: '/admin/funnels',
      name: 'funnels',
      component: FunnelsList
    },
    {
      path: '/admin/new-funnel',
      name: 'new-funnel',
      component: FunnelForm
    },
    {
      path: '/admin/edit-funnel/:id',
      name: 'edit-funnel',
      component: FunnelForm
    },
    {
      path: '/admin/funnel-metrics',
      name: 'funnel-metrics',
      component: FunnelMetrics
    },
    {
      path: '/admin/features',
      name: 'features',
      component: FeaturesList
    },
    {
      path: '/admin/new-feature',
      name: 'new-feature',
      component: FeatureForm
    },
    {
      path: '/admin/edit-feature/:id',
      name: 'edit-feature',
      component: FeatureForm
    }
  ]
})

export default router
