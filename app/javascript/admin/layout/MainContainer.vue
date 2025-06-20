<template>
  <div class="h-full">
    <!-- Mobile menu button -->
    <div class="fixed top-4 right-4 lg:hidden">
      <button
        type="button"
        class="p-2 text-gray-600 hover:text-primary focus:outline-none"
        @click="viewModel.menuOpen = true"
      >
        <span class="sr-only">Open sidebar</span>
        <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
        </svg>
      </button>
    </div>

    <!-- Mobile sidebar -->
    <div
      v-if="viewModel.menuOpen"
      class="relative z-50 lg:hidden"
      role="dialog"
      aria-modal="true"
    >
      <!-- Backdrop -->
      <div
        class="fixed inset-0 bg-gray-900/80"
        @click="viewModel.menuOpen = false"
      ></div>

      <!-- Sliding sidebar -->
      <div class="fixed inset-0 flex">
        <div class="relative mr-8 flex w-full max-w-xs flex-1">
          <!-- Close button -->
          <div class="absolute top-0 right-0 pt-2">
            <button
              type="button"
              class="p-2 text-zinc-800 hover:text-primary-light"
              @click="viewModel.menuOpen = false"
            >
              <span class="sr-only">Close sidebar</span>
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Sidebar component -->
          <Sidebar :view-model="viewModel" class="flex grow flex-col gap-y-5 overflow-y-auto bg-white" />
        </div>
      </div>
    </div>

    <!-- Desktop sidebar -->
    <Sidebar class="hidden lg:fixed lg:inset-y-0 lg:flex lg:flex-col" />

    <!-- Main content -->
    <main class="lg:pl-52">
      <router-view></router-view>
    </main>
  </div>
</template>

<script>
import Sidebar from './Sidebar.vue'

export default {
  name: 'MainContainer',
  components: {
    Sidebar
  },
  data () {
    return {
      viewModel: {
        menuOpen: false
      }
    }
  }
}
</script>
