<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Features</h1>
      <router-link
        :to="{ name: 'new-feature' }"
        class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg inline-flex items-center gap-2"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
        </svg>
        New Feature
      </router-link>
    </div>

    <!-- Filters -->
    <div class="mb-4 flex gap-4">
      <select v-model="filterStatus" class="px-3 py-2 border border-gray-300 rounded-lg text-sm">
        <option value="">All Statuses</option>
        <option value="backlog">Backlog</option>
        <option value="planned">Planned</option>
        <option value="in_progress">In Progress</option>
        <option value="completed">Completed</option>
        <option value="cancelled">Cancelled</option>
      </select>
      <select v-model="filterPriority" class="px-3 py-2 border border-gray-300 rounded-lg text-sm">
        <option value="">All Priorities</option>
        <option value="low">Low</option>
        <option value="medium">Medium</option>
        <option value="high">High</option>
        <option value="critical">Critical</option>
      </select>
    </div>

    <div class="overflow-x-auto text-sm">
      <table class="min-w-full bg-white border border-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Priority</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Area</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <tr v-for="feature in filteredFeatures" :key="feature.id" class="hover:bg-gray-50">
            <td class="px-6 py-4">
              <div class="font-medium text-gray-900">{{ feature.title }}</div>
              <div v-if="feature.description" class="text-gray-500 text-xs truncate max-w-xs">
                {{ feature.description }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span :class="statusClass(feature.status)" class="px-2 py-1 rounded-full text-xs">
                {{ formatStatus(feature.status) }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span :class="priorityClass(feature.priority)" class="px-2 py-1 rounded-full text-xs">
                {{ formatPriority(feature.priority) }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-gray-500">{{ feature.area || '-' }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-gray-500">{{ formatDate(feature.created_at) }}</td>
            <td class="px-6 py-4 flex whitespace-nowrap gap-3">
              <router-link
                :to="{ name: 'edit-feature', params: { id: feature.slug }}"
                class="text-purple-600 hover:text-purple-900 inline-flex items-center"
              >
                Edit
              </router-link>
              <button @click="onDeleteClick(feature)" class="text-red-600 hover:text-red-900 cursor-pointer">
                Delete
              </button>
            </td>
          </tr>
          <tr v-if="filteredFeatures.length === 0">
            <td colspan="6" class="px-6 py-8 text-center text-gray-500">
              No features found.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <confirm-modal
      v-if="showDeleteModal"
      title="Delete Feature"
      :message="`Are you sure you want to delete '${featureToDelete?.title}'?`"
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
  name: 'FeaturesList',
  components: { ConfirmModal },
  data() {
    return {
      model: starter.model,
      features: [],
      service: new RestService('features', '/'),
      showDeleteModal: false,
      featureToDelete: null,
      filterStatus: '',
      filterPriority: ''
    }
  },
  computed: {
    filteredFeatures() {
      return this.features.filter(f => {
        if (this.filterStatus && f.status !== this.filterStatus) return false
        if (this.filterPriority && f.priority !== this.filterPriority) return false
        return true
      })
    }
  },
  mounted() {
    this.fetchFeatures()
  },
  methods: {
    async fetchFeatures() {
      try {
        this.model.loading = true
        this.features = await this.service.list()
      } catch (error) {
        console.error('Error fetching features:', error)
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
    formatStatus(status) {
      const statusMap = {
        backlog: 'Backlog',
        planned: 'Planned',
        in_progress: 'In Progress',
        completed: 'Completed',
        cancelled: 'Cancelled'
      }
      return statusMap[status] || status || 'Backlog'
    },
    formatPriority(priority) {
      const priorityMap = {
        low: 'Low',
        medium: 'Medium',
        high: 'High',
        critical: 'Critical'
      }
      return priorityMap[priority] || priority || 'Medium'
    },
    statusClass(status) {
      const classes = {
        backlog: 'bg-gray-100 text-gray-800',
        planned: 'bg-blue-100 text-blue-800',
        in_progress: 'bg-yellow-100 text-yellow-800',
        completed: 'bg-green-100 text-green-800',
        cancelled: 'bg-red-100 text-red-800'
      }
      return classes[status] || 'bg-gray-100 text-gray-800'
    },
    priorityClass(priority) {
      const classes = {
        low: 'bg-gray-100 text-gray-600',
        medium: 'bg-blue-100 text-blue-700',
        high: 'bg-orange-100 text-orange-700',
        critical: 'bg-red-100 text-red-700'
      }
      return classes[priority] || 'bg-gray-100 text-gray-600'
    },
    onDeleteClick(feature) {
      this.featureToDelete = feature
      this.showDeleteModal = true
    },
    async onDeleteConfirmed() {
      try {
        await this.service.remove(this.featureToDelete.slug)
        this.features = this.features.filter(f => f.id !== this.featureToDelete.id)
        this.showDeleteModal = false
      } catch (error) {
        console.error('Error deleting feature:', error)
      }
    }
  }
}
</script>
