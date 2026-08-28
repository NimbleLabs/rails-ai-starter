<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Feature Details</h1>
        <p class="page-subtitle">{{ feature.title || 'Roadmap item' }}</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'features' }" class="btn-secondary">
          Back to Features
        </router-link>
        <router-link
          :to="{ name: 'edit-feature', params: { id: feature.slug }}"
          class="btn-primary"
        >
          Edit
        </router-link>
      </div>
    </div>

    <div v-if="loading" class="card text-center py-12">
      <p class="text-ink-muted">Loading...</p>
    </div>
    <div v-else-if="error" class="alert-error">{{ error }}</div>

    <div v-else class="card space-y-6">
      <!-- Title & Basic Info -->
      <div>
        <div class="flex flex-wrap items-center gap-2 mb-3">
          <span :class="statusClass(feature.status)">
            {{ formatStatus(feature.status) }}
          </span>
          <span :class="priorityClass(feature.priority)">
            {{ formatPriority(feature.priority) }}
          </span>
        </div>
        <h2 class="section-title mb-2">{{ feature.title }}</h2>
        <div class="flex flex-wrap items-center gap-4 text-sm text-ink-muted">
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
          <span class="flex items-center gap-1 font-mono text-xs">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>
            </svg>
            {{ feature.slug }}
          </span>
        </div>
      </div>

      <!-- Description -->
      <div v-if="feature.description">
        <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-2">Description</p>
        <p class="text-ink whitespace-pre-wrap">{{ feature.description }}</p>
      </div>

      <!-- Acceptance Criteria -->
      <div v-if="feature.acceptance_criteria">
        <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-2">Acceptance Criteria</p>
        <div class="panel-muted text-ink whitespace-pre-wrap text-sm font-mono">{{ feature.acceptance_criteria }}</div>
      </div>

      <!-- Plan -->
      <div v-if="feature.plan">
        <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-2">Plan</p>
        <div class="panel-muted text-ink whitespace-pre-wrap text-sm">{{ feature.plan }}</div>
      </div>

      <!-- Implementation Notes -->
      <div v-if="feature.implementation_notes">
        <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-2">Implementation Notes</p>
        <div class="panel-muted border border-primary/20 text-ink whitespace-pre-wrap text-sm">{{ feature.implementation_notes }}</div>
      </div>

      <!-- Dates -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 pt-6 border-t border-line">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Created</p>
          <div class="text-ink text-sm">{{ formatDate(feature.created_at) }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Updated</p>
          <div class="text-ink text-sm">{{ formatDate(feature.updated_at) }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Started</p>
          <div class="text-ink text-sm">{{ formatDate(feature.started_at) || '-' }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Completed</p>
          <div class="text-ink text-sm">{{ formatDate(feature.completed_at) || '-' }}</div>
        </div>
      </div>
    </div>
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
        backlog: 'badge-gray',
        planned: 'badge-blue',
        in_progress: 'badge-amber',
        completed: 'badge-green',
        cancelled: 'badge-red'
      }
      return classes[status] || 'badge-gray'
    },
    priorityClass(priority) {
      const classes = {
        low: 'badge-gray',
        medium: 'badge-blue',
        high: 'badge-amber',
        critical: 'badge-red'
      }
      return classes[priority] || 'badge-gray'
    }
  }
}
</script>
