<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Users</h1>
        <p class="page-subtitle">Everyone with an account, including admins.</p>
      </div>
    </div>

    <!-- User Cards -->
    <div v-if="users && users.length > 0" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="user in users"
        :key="user.id"
        class="card flex items-center gap-4"
      >
        <!-- User Avatar/Initials -->
        <div class="w-12 h-12 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center">
          <span class="font-display font-bold text-lg">
            {{ getUserInitials(user.name) }}
          </span>
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="font-display text-base font-bold truncate">
            <router-link :to="{ name: 'user-details', params: { id: user.slug } }" class="table-link">
              {{ user.name }}
            </router-link>
          </h3>
          <p class="text-sm text-ink-muted truncate">
            {{ user.email }}
          </p>
        </div>
      </div>
    </div>

    <!-- Empty state when no users exist -->
    <div v-else-if="usersLoaded" class="card text-center py-12">
      <svg class="h-12 w-12 text-ink-muted mx-auto mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      <h3 class="section-title mb-2">No users found</h3>
      <p class="text-ink-muted max-w-md mx-auto">There are currently no users in this list. Users will appear here once they've been added to the system.</p>
    </div>
  </div>
</template>

<script>
import RestService from '../../services/RestService.js'

export default {
  name: 'Users',
  data () {
    return {
      users: [],
      usersLoaded: false,
      model: starter.model
    }
  },
  mounted () {
    this.loadUsers()
  },
  methods: {
    async loadUsers () {
      try {
        this.model.loading = true
        console.log('loading users')
        const service = new RestService('users')
        const response = await service.list()
        console.log('users loaded')
        console.log(response)
        this.users = response
        this.usersLoaded = true
        this.model.loading = false
      } catch (error) {
        console.error('Error fetching users:', error)
        this.model.loading = false
      }
    },

    formatDate(dateString) {
      if (!dateString) return 'Never';

      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      });
    },

    getUserInitials(name) {
      if (!name) return '?';

      const names = name.trim().split(' ');
      if (names.length === 1) {
        return names[0].charAt(0).toUpperCase();
      }

      return (names[0].charAt(0) + names[names.length - 1].charAt(0)).toUpperCase();
    }
  }
}
</script>
