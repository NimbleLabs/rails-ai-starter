<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">User Details</h1>
        <p class="page-subtitle">{{ user.name || 'Account information and API access.' }}</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'users' }" class="btn-secondary">
          Back to Users
        </router-link>
      </div>
    </div>

    <div class="card space-y-6">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Name</p>
          <div class="text-ink">{{ user.name || '-' }}</div>
        </div>

        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Email</p>
          <div class="text-ink">{{ user.email || '-' }}</div>
        </div>

        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Role</p>
          <span :class="user.role === 'admin' ? 'badge-brand' : 'badge-gray'">
            {{ user.role || 'user' }}
          </span>
        </div>

        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Created</p>
          <div class="text-ink">{{ formatDate(user.created_at) }}</div>
        </div>
      </div>

      <!-- API Token Section -->
      <div class="pt-6 border-t border-line">
        <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-2">API Token</p>
        <div class="flex items-center gap-2">
          <code class="flex-1 min-w-0 truncate bg-surface-muted px-3 py-2 rounded-xl text-sm font-mono text-ink select-all">
            {{ user.auth_token || 'No token generated' }}
          </code>
          <button
            v-if="user.auth_token"
            type="button"
            @click="copyToken"
            class="btn-secondary btn-sm shrink-0"
          >
            <svg v-if="!copied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <svg v-else class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ copied ? 'Copied!' : 'Copy' }}
          </button>
        </div>
        <p class="form-hint mt-2">
          Use this token in the <code class="bg-surface-muted px-1 py-0.5 rounded font-mono">x-api-token</code> header for API authentication.
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
