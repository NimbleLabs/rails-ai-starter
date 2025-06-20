<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-6">Users</h1>
    <div class="overflow-x-auto text-sm">
      <!-- Table with users when they exist -->
      <table v-if="users && users.length > 0" class="min-w-full bg-white border border-gray-200">
        <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
        </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
        <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
          <td class="px-6 py-4 whitespace-nowrap">{{ user.name }}</td>
          <td class="px-6 py-4 whitespace-nowrap">{{ user.email }}</td>
        </tr>
        </tbody>
      </table>

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
  </div>
</template>

<script>
import RestService from '../services/RestService'

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
    }
  }
}
</script>
