<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Contacts</h1>
        <p class="page-subtitle">Leads and newsletter sign-ups captured from the site.</p>
      </div>
    </div>

    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
        <tr>
          <th>Name</th>
          <th>Email</th>
          <th>Created</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="contact in contacts" :key="contact.id">
          <td class="whitespace-nowrap font-medium">{{ contact.name }}</td>
          <td class="whitespace-nowrap">{{ contact.email }}</td>
          <td class="whitespace-nowrap text-ink-muted">{{ formatDate(contact.created_at) }}</td>
        </tr>
        <tr v-if="contacts.length === 0">
          <td colspan="3" class="empty-state">No contacts yet.</td>
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
