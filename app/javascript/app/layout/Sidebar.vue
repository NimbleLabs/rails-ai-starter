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
        @click="onRouteClick()"
        :to="{ name: 'home' }"
        class="nav-link"
        :class="{ 'nav-link-active': isCurrentRoute('home') }">
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
        Home
      </router-link>
    </nav>

    <!-- Footer -->
    <div class="px-2 py-3 border-t border-line">
      <a href="/" class="nav-link">
        <svg class="h-4 w-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 15 3 9m0 0 6-6M3 9h12a6 6 0 0 1 0 12h-3" />
        </svg>
        Back to site
      </a>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Sidebar',
  props: ['viewModel'],
  methods: {
    isCurrentRoute (name) {
      return this.$route.name === name
    },
    onRouteClick () {
      if (this.viewModel) {
        this.viewModel.menuOpen = false
      }
    }
  }
}
</script>
