<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Funnels</h1>
      <div class="flex gap-4">
        <router-link
          :to="{ name: 'funnel-metrics' }"
          class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg inline-flex items-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
          </svg>
          View Metrics
        </router-link>
        <router-link
          :to="{ name: 'new-funnel' }"
          class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg inline-flex items-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          New Funnel
        </router-link>
      </div>
    </div>

    <div class="overflow-x-auto text-sm">
      <table class="min-w-full bg-white border border-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Slug</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <tr v-for="funnel in funnels" :key="funnel.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">{{ funnel.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap font-mono text-sm text-gray-500">{{ funnel.slug }}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span :class="funnel.active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                    class="px-2 py-1 rounded-full text-xs">
                {{ funnel.active ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">{{ formatDate(funnel.created_at) }}</td>
            <td class="px-6 py-4 flex whitespace-nowrap gap-3">
              <router-link
                :to="{ name: 'edit-funnel', params: { id: funnel.slug }}"
                class="text-purple-600 hover:text-purple-900 inline-flex items-center"
              >
                Edit
              </router-link>
              <a :href="`/f/${funnel.slug}/lead`" target="_blank" class="text-blue-600 hover:text-blue-900">
                Preview
              </a>
              <button @click="onDeleteClick(funnel)" class="text-red-600 hover:text-red-900">
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <confirm-modal
      v-if="showDeleteModal"
      title="Delete Funnel"
      :message="`Are you sure you want to delete '${funnelToDelete?.name}'?`"
      confirm-text="Delete"
      confirm-style="danger"
      @confirm="onDeleteConfirmed"
      @cancel="showDeleteModal = false"
    />
  </div>
</template>

<script>
import RestService from '../../../services/RestService.js'
import ConfirmModal from "../../../components/ConfirmModal.vue"

export default {
  name: 'FunnelsList',
  components: { ConfirmModal },
  data() {
    return {
      model: starter.model,
      funnels: [],
      service: new RestService('funnels'),
      showDeleteModal: false,
      funnelToDelete: null
    }
  },
  mounted() {
    this.fetchFunnels()
  },
  methods: {
    async fetchFunnels() {
      try {
        this.model.loading = true
        this.funnels = await this.service.list()
      } catch (error) {
        console.error('Error fetching funnels:', error)
      } finally {
        this.model.loading = false
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-'
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric'
      })
    },
    onDeleteClick(funnel) {
      this.funnelToDelete = funnel
      this.showDeleteModal = true
    },
    async onDeleteConfirmed() {
      try {
        await this.service.remove(this.funnelToDelete.slug)
        this.funnels = this.funnels.filter(f => f.id !== this.funnelToDelete.id)
        this.showDeleteModal = false
      } catch (error) {
        console.error('Error deleting funnel:', error)
      }
    }
  }
}
</script>
