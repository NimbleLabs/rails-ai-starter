<template>
  <div class="w-56 h-full bg-surface border-r border-line flex flex-col">
    <!-- Brand -->
    <div class="px-4 pt-5 pb-4">
      <a href="/" class="flex items-center gap-2">
        <span class="brand-mark w-8 h-8 text-xs">ST</span>
        <span class="font-display text-lg font-extrabold tracking-tight text-ink">Starter</span>
      </a>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 px-2 space-y-1 overflow-y-auto pb-4">
      <router-link
        v-for="item in navItems"
        :key="item.route"
        @click="onRouteClick()"
        :to="{ name: item.route }"
        class="nav-link"
        :class="{ 'nav-link-active': isCurrentRoute(item.route, item.also) }">
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" :d="item.icon" />
        </svg>
        {{ item.label }}
      </router-link>
    </nav>

    <!-- Footer -->
    <div class="px-2 py-3 border-t border-line">
      <a href="/app" class="nav-link">
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 15 3 9m0 0 6-6M3 9h12a6 6 0 0 1 0 12h-3" />
        </svg>
        Back to app
      </a>
    </div>
  </div>
</template>

<script>
const ICONS = {
  home: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',
  users: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
  contacts: 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
  email: 'M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75',
  articles: 'M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m0 0h2a2 2 0 012 2v9a2 2 0 01-2 2h-2m0-13v13M7 8h6M7 12h6M7 16h4',
  funnels: 'M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z',
  metrics: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
  features: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
  logs: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z'
}

export default {
  name: 'Sidebar',
  props: ['viewModel'],
  data () {
    return {
      navItems: [
        { route: 'home', label: 'Dashboard', icon: ICONS.home },
        { route: 'users', label: 'Users', icon: ICONS.users, also: ['user-details'] },
        { route: 'contacts', label: 'Contacts', icon: ICONS.contacts },
        { route: 'email-templates', label: 'Email', icon: ICONS.email, also: ['new-email', 'edit-email'] },
        { route: 'posts', label: 'Articles', icon: ICONS.articles, also: ['new-post', 'edit-post', 'post-details'] },
        { route: 'funnels', label: 'Funnels', icon: ICONS.funnels, also: ['new-funnel', 'edit-funnel'] },
        { route: 'funnel-metrics', label: 'Metrics', icon: ICONS.metrics },
        { route: 'features', label: 'Features', icon: ICONS.features, also: ['new-feature', 'edit-feature', 'feature-details'] },
        { route: 'logs', label: 'Logs', icon: ICONS.logs, also: ['log-details', 'log-subscriptions'] }
      ]
    }
  },
  methods: {
    isCurrentRoute (name, also) {
      if (this.$route.name === name) return true
      return Array.isArray(also) && also.includes(this.$route.name)
    },
    onRouteClick () {
      if (this.viewModel) {
        this.viewModel.menuOpen = false
      }
    }
  }
}
</script>
