<template>
  <div class="w-52 h-full bg-white border-r border-gray-200 flex flex-col">
    <!-- Logo/Brand Area -->
    <div class="px-3 pt-4 pb-2">
      <a href="/" class="inline-block w-full text-2xl font-extrabold tracking-tight text-sky-900 text-center">
        Starter
      </a>
    </div>

    <!-- Navigation Links -->
    <nav class="flex-1 px-2 space-y-0.5">
      <router-link
          @click="onRouteClick()"
        :to="{ name: 'home' }"
        class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
        :class="{ 'bg-primary-light text-primary': isCurrentRoute('home')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
        Home
      </router-link>

      <router-link
          @click="onRouteClick()"
        :to="{ name: 'users' }"
        class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
        :class="{ 'bg-primary-light text-primary': isCurrentRoute('users')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        Users
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'contacts' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('contacts')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        Contacts
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'email-templates' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('email-templates')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        Email
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'posts' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('posts')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        Articles
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'funnels' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('funnels')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
        </svg>
        Funnels
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'funnel-metrics' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('funnel-metrics')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Metrics
      </router-link>

      <router-link
          @click="onRouteClick()"
          :to="{ name: 'features' }"
          class="flex items-center px-2 py-1.5 text-sm font-medium rounded-md hover:bg-gray-50 hover:text-primary"
          :class="{ 'bg-primary-light text-primary': isCurrentRoute('features')}">
        <svg class="mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
        Features
      </router-link>

    </nav>
  </div>
</template>

<script>
export default {
  name: 'Sidebar',
  props: ['viewModel'],
  methods: {
    isCurrentRoute(name) {
      return this.$route.name === name;
    },
    onRouteClick() {
      console.log('route clicked')

      if(this.viewModel) {
        this.viewModel.menuOpen = false;
      }
    }
  }
}
</script>
