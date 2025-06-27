<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-6">Users</h1>
    <!-- User Cards -->
    <div v-if="users && users.length > 0" class="flex flex-wrap gap-4 sm:gap-6">
      <div 
        v-for="user in users" 
        :key="user.id" 
        class="p-2 w-full card my-1 flex-shrink-0"
      >
        <!-- User Avatar/Initials -->
        <div class="flex items-center space-x-4">
          <div class="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center">
            <span class="text-slate-600 font-semibold text-lg">
              {{ getUserInitials(user.name) }}
            </span>
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-lg font-medium text-gray-900 truncate">

              <router-link :to="{ name: 'user-details', params: { id: user.slug } }" class="pointer">
                {{ user.name }}
              </router-link>
            </h3>
            <p class="text-sm text-gray-500 truncate">
              {{ user.email }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state when no users exist -->
    <div v-else class="bg-white border border-gray-200 rounded-lg shadow-sm p-8 text-center">
      <div class="mx-auto max-w-md">
        <svg class="h-12 w-12 text-gray-400 mx-auto mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No users found</h3>
        <p class="text-gray-500 mb-6">There are currently no users in this list. Users will appear here once they've been added to the system.</p>
      </div>
    </div>
  </div>
</template>

<script>
import RestService from '../../services/RestService.js'

export default {
  name: 'Users',
  data () {
    return {
      users: []
    }
  },
  mounted () {
    this.loadUsers()
  },
  methods: {
    async loadUsers () {
      try {
        console.log('loading users')
        const service = new RestService('users')
        const response = await service.list()
        console.log('users loaded')
        console.log(response)
        this.users = response
      } catch (error) {
        console.error('Error fetching users:', error)
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
