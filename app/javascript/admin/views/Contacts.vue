<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-6">Contacts/Leads</h1>

    <div class="overflow-x-auto text-sm">
      <table class="min-w-full bg-white border border-gray-200">
        <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
        </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
        <tr v-for="contact in contacts" :key="contact.id" class="hover:bg-gray-50">
          <td class="px-6 py-4 whitespace-nowrap">
              {{ contact.name }}
          </td>
          <td class="px-6 py-4 whitespace-nowrap">{{ contact.email }}</td>
          <td class="px-6 py-4 whitespace-nowrap">{{ formatDate(contact.created_at) }}</td>
        </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import RestService from '../../services/RestService'

export default {
  name: 'Contacts',
  data () {
    return {
      contacts: []
    }
  },
  mounted () {
    this.fetchUsers()
  },
  methods: {
    async fetchUsers() {
      try {
        console.log('loading contacts')
        const service = new RestService('contacts', '/')
        const response = await service.list()
        console.log('contacts loaded')
        console.log(response)
        this.contacts = response
      } catch (error) {
        console.error('Error fetching contacts:', error)
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-'
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      })
    }
  }
}
</script>
