<template>
  <div class="p-6">

    <h1 class="text-2xl font-bold mb-5">User Details</h1>

    <div class="flex items-center justify-end mb-3">
      <div>
        <router-link :to="{ name: 'users' }" class="btn btn-secondary">
          Back to Users
        </router-link>
      </div>
    </div>

    <div class="bg-white rounded-lg border border-gray-200 p-6 space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Name</label>
          <div class="text-gray-900">{{ user.name || '-' }}</div>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Email</label>
          <div class="text-gray-900">{{ user.email || '-' }}</div>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Role</label>
          <span :class="user.role === 'admin' ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-800'"
                class="px-2 py-1 rounded-full text-xs font-medium">
            {{ user.role || 'user' }}
          </span>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Created</label>
          <div class="text-gray-900">{{ formatDate(user.created_at) }}</div>
        </div>
      </div>

      <!-- API Token Section -->
      <div class="pt-4 border-t border-gray-200">
        <label class="block text-xs font-medium text-gray-500 uppercase mb-2">API Token</label>
        <div class="flex items-center gap-2">
          <code class="flex-1 bg-gray-100 px-3 py-2 rounded-lg text-sm font-mono text-gray-800 select-all">
            {{ user.auth_token || 'No token generated' }}
          </code>
          <button
            v-if="user.auth_token"
            @click="copyToken"
            class="px-3 py-2 bg-gray-900 text-white text-sm font-medium rounded-lg hover:bg-gray-800 transition-colors cursor-pointer flex items-center gap-1.5"
          >
            <svg v-if="!copied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <svg v-else class="w-4 h-4 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ copied ? 'Copied!' : 'Copy' }}
          </button>
        </div>
        <p class="mt-2 text-xs text-gray-500">
          Use this token in the <code class="bg-gray-100 px-1 py-0.5 rounded">x-api-token</code> header for API authentication.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import RestService from "@/services/RestService.js";

export default {
  name: 'UserDetails',
  data() {
    return {
      user: {
        id: null,
        name: '',
        email: '',
        role: '',
        auth_token: '',
        created_at: null,
        updated_at: null,
      },
      copied: false
    }
  },
  mounted() {
    this.loadUser()
  },
  methods: {
    async loadUser() {
      try {
        const service = new RestService('users')
        const response = await service.get(this.$route.params.id)
        this.user = response
      } catch (error) {
        console.error('Error fetching user:', error)
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-'
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
      })
    },
    async copyToken() {
      if (!this.user.auth_token) return
      try {
        await navigator.clipboard.writeText(this.user.auth_token)
        this.copied = true
        setTimeout(() => { this.copied = false }, 2000)
      } catch (error) {
        console.error('Failed to copy token:', error)
      }
    }
  }
}
</script>
