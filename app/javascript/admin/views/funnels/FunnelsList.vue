<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Funnels</h1>
        <p class="page-subtitle">Landing-page sequences that turn visitors into orders.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'funnel-metrics' }" class="btn-secondary">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
          </svg>
          View Metrics
        </router-link>
        <router-link :to="{ name: 'new-funnel' }" class="btn-primary">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          New Funnel
        </router-link>
      </div>
    </div>

    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Slug</th>
            <th>Status</th>
            <th>Created</th>
            <th class="text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="funnel in funnels" :key="funnel.id">
            <td class="whitespace-nowrap">
              <router-link :to="{ name: 'edit-funnel', params: { id: funnel.slug }}" class="table-link">
                {{ funnel.name }}
              </router-link>
            </td>
            <td class="whitespace-nowrap font-mono text-xs text-ink-muted">{{ funnel.slug }}</td>
            <td class="whitespace-nowrap">
              <span :class="funnel.active ? 'badge-green' : 'badge-gray'">
                {{ funnel.active ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td class="whitespace-nowrap text-ink-muted">{{ formatDate(funnel.created_at) }}</td>
            <td class="whitespace-nowrap">
              <div class="flex justify-end gap-1">
                <router-link
                  :to="{ name: 'edit-funnel', params: { id: funnel.slug }}"
                  class="btn-ghost btn-sm"
                  title="Edit"
                >
                  Edit
                </router-link>
                <a :href="`/f/${funnel.slug}/lead`" target="_blank" class="btn-ghost btn-sm" title="Preview landing page">
                  Preview
                </a>
                <button
                  type="button"
                  @click="onDeleteClick(funnel)"
                  class="btn-ghost btn-sm text-red-600 hover:text-red-700 hover:bg-red-50"
                  title="Delete"
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="funnels.length === 0">
            <td colspan="5" class="empty-state">No funnels yet.</td>
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
