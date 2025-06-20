<template>
  <div class="w-52 h-full bg-white border-r border-gray-200 flex flex-col">
    <!-- Logo/Brand Area -->
    <div class="px-3 pt-4 pb-2">
      <h1 class="text-2xl font-extrabold tracking-tight text-sky-900 text-center">Starter</h1>
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
