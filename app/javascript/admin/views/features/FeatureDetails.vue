<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-5">Feature Details</h1>

    <div v-if="loading" class="text-gray-500">Loading...</div>
    <div v-else-if="error" class="text-red-600">{{ error }}</div>

    <template v-else>
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
          <span :class="statusClass(feature.status)" class="px-3 py-1 rounded-full text-sm font-medium">
            {{ formatStatus(feature.status) }}
          </span>
          <span :class="priorityClass(feature.priority)" class="px-3 py-1 rounded-full text-sm font-medium">
            {{ formatPriority(feature.priority) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <router-link
            :to="{ name: 'edit-feature', params: { id: feature.slug }}"
            class="btn btn-primary"
          >
            Edit
          </router-link>
          <router-link :to="{ name: 'features' }" class="btn btn-secondary">
            Back to Features
          </router-link>
        </div>
      </div>

      <div class="bg-white rounded-lg border border-gray-200 p-6 space-y-6">
        <!-- Title & Basic Info -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-2">{{ feature.title }}</h2>
          <div class="flex items-center gap-4 text-sm text-gray-500">
            <span v-if="feature.area" class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
              </svg>
              {{ feature.area }}
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              {{ feature.user?.name || 'Unknown' }}
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>
              </svg>
              {{ feature.slug }}
            </span>
          </div>
        </div>

        <!-- Description -->
        <div v-if="feature.description">
          <label class="block text-xs font-medium text-gray-500 uppercase mb-2">Description</label>
          <p class="text-gray-700 whitespace-pre-wrap">{{ feature.description }}</p>
        </div>

        <!-- Acceptance Criteria -->
        <div v-if="feature.acceptance_criteria">
          <label class="block text-xs font-medium text-gray-500 uppercase mb-2">Acceptance Criteria</label>
          <div class="bg-gray-50 rounded-lg p-4 text-gray-700 whitespace-pre-wrap text-sm font-mono">{{ feature.acceptance_criteria }}</div>
        </div>

        <!-- Plan -->
        <div v-if="feature.plan">
          <label class="block text-xs font-medium text-gray-500 uppercase mb-2">Plan</label>
          <div class="bg-gray-50 rounded-lg p-4 text-gray-700 whitespace-pre-wrap text-sm">{{ feature.plan }}</div>
        </div>

        <!-- Implementation Notes -->
        <div v-if="feature.implementation_notes">
          <label class="block text-xs font-medium text-gray-500 uppercase mb-2">Implementation Notes</label>
          <div class="bg-blue-50 rounded-lg p-4 text-gray-700 whitespace-pre-wrap text-sm">{{ feature.implementation_notes }}</div>
        </div>

        <!-- Dates -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 border-t border-gray-200">
          <div>
            <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Created</label>
            <div class="text-gray-900 text-sm">{{ formatDate(feature.created_at) }}</div>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Updated</label>
            <div class="text-gray-900 text-sm">{{ formatDate(feature.updated_at) }}</div>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Started</label>
            <div class="text-gray-900 text-sm">{{ formatDate(feature.started_at) || '-' }}</div>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Completed</label>
            <div class="text-gray-900 text-sm">{{ formatDate(feature.completed_at) || '-' }}</div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import RestService from '../../../services/RestService.js'

export default {
  name: 'FeatureDetails',
  data() {
    return {
      loading: true,
      error: null,
      feature: {
        id: null,
        slug: '',
        title: '',
        description: '',
        status: '',
        priority: '',
        area: '',
        acceptance_criteria: '',
        plan: '',
        implementation_notes: '',
        started_at: null,
        completed_at: null,
        created_at: null,
        updated_at: null,
        user: null
      }
    }
  },
  mounted() {
    this.loadFeature()
  },
  methods: {
    async loadFeature() {
      try {
        this.loading = true
        this.error = null
        const service = new RestService('features', '/')
        const response = await service.get(this.$route.params.id)
        this.feature = response
      } catch (err) {
        console.error('Error fetching feature:', err)
        this.error = 'Failed to load feature: ' + (err.message || err)
      } finally {
        this.loading = false
      }
    },
    formatDate(dateString) {
      if (!dateString) return null
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
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
    }
  }
}
</script>
