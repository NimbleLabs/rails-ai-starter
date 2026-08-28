<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Features</h1>
        <p class="page-subtitle">Roadmap items. Drag planned features to set their order.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'new-feature' }" class="btn-primary">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          New Feature
        </router-link>
      </div>
    </div>

    <!-- Filters -->
    <div class="card flex flex-wrap items-end gap-4 mb-6">
      <div>
        <label for="filterStatus" class="form-label">Status</label>
        <select id="filterStatus" v-model="filterStatus" class="input-form-field w-auto">
          <option value="">All Statuses</option>
          <option value="backlog">Backlog</option>
          <option value="planned">Planned</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>
      <div>
        <label for="filterPriority" class="form-label">Priority</label>
        <select id="filterPriority" v-model="filterPriority" class="input-form-field w-auto">
          <option value="">All Priorities</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
          <option value="critical">Critical</option>
        </select>
      </div>
      <button type="button" class="btn-ghost" @click="filterStatus = ''; filterPriority = ''">
        Clear
      </button>
    </div>

    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
          <tr>
            <th v-if="showingPlanned" class="w-8 !px-2"></th>
            <th v-if="showingPlanned" class="w-12 !px-3">#</th>
            <th>Title</th>
            <th>Status</th>
            <th>Priority</th>
            <th>Area</th>
            <th>Created</th>
            <th class="text-right">Actions</th>
          </tr>
        </thead>
        <tbody ref="tableBody">
          <tr
            v-for="feature in filteredFeatures"
            :key="feature.id"
            :data-id="feature.id"
            :class="{ 'cursor-grab active:cursor-grabbing': showingPlanned }"
          >
            <!-- Drag handle -->
            <td v-if="showingPlanned" class="!px-2 text-ink-muted/50 hover:text-ink-muted">
              <svg class="w-4 h-4 drag-handle cursor-grab" fill="currentColor" viewBox="0 0 24 24">
                <circle cx="9" cy="5" r="1.5"/>
                <circle cx="15" cy="5" r="1.5"/>
                <circle cx="9" cy="12" r="1.5"/>
                <circle cx="15" cy="12" r="1.5"/>
                <circle cx="9" cy="19" r="1.5"/>
                <circle cx="15" cy="19" r="1.5"/>
              </svg>
            </td>
            <!-- Position -->
            <td v-if="showingPlanned" class="!px-3">
              <span class="text-xs font-mono text-ink-muted">{{ feature.position }}</span>
            </td>
            <td>
              <router-link
                :to="{ name: 'feature-details', params: { id: feature.slug }}"
                class="table-link"
              >
                {{ feature.title }}
              </router-link>
              <div v-if="feature.description" class="text-ink-muted text-xs truncate max-w-xs">
                {{ feature.description }}
              </div>
            </td>
            <td class="whitespace-nowrap">
              <span :class="statusClass(feature.status)">
                {{ formatStatus(feature.status) }}
              </span>
            </td>
            <td class="whitespace-nowrap">
              <span :class="priorityClass(feature.priority)">
                {{ formatPriority(feature.priority) }}
              </span>
            </td>
            <td class="whitespace-nowrap text-ink-muted">{{ feature.area || '-' }}</td>
            <td class="whitespace-nowrap text-ink-muted">{{ formatDate(feature.created_at) }}</td>
            <td class="whitespace-nowrap">
              <div class="flex justify-end gap-1">
                <router-link
                  :to="{ name: 'feature-details', params: { id: feature.slug }}"
                  class="btn-ghost btn-sm"
                  title="View"
                >
                  View
                </router-link>
                <router-link
                  :to="{ name: 'edit-feature', params: { id: feature.slug }}"
                  class="btn-ghost btn-sm"
                  title="Edit"
                >
                  Edit
                </router-link>
                <button
                  type="button"
                  @click="onDeleteClick(feature)"
                  class="btn-ghost btn-sm text-red-600 hover:text-red-700 hover:bg-red-50"
                  title="Delete"
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredFeatures.length === 0">
            <td :colspan="showingPlanned ? 8 : 6" class="empty-state">
              No features found.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Reorder save indicator -->
    <div v-if="reorderPending" class="alert-warning inline-flex items-center gap-2 mt-4">
      <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
      </svg>
      Saving order...
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
import Sortable from 'sortablejs'
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
      filterPriority: '',
      sortableInstance: null,
      reorderPending: false
    }
  },
  computed: {
    showingPlanned() {
      return this.filterStatus === 'planned' || this.filterStatus === ''
    },
    filteredFeatures() {
      let filtered = this.features.filter(f => {
        if (this.filterStatus && f.status !== this.filterStatus) return false
        if (this.filterPriority && f.priority !== this.filterPriority) return false
        return true
      })

      // When viewing planned (or all), sort planned features by position first
      if (!this.filterStatus || this.filterStatus === 'planned') {
        filtered.sort((a, b) => {
          // Planned features with positions come first, sorted by position
          if (a.status === 'planned' && b.status === 'planned') {
            return (a.position || 9999) - (b.position || 9999)
          }
          // Planned features before others when viewing all
          if (a.status === 'planned') return -1
          if (b.status === 'planned') return 1
          return 0
        })
      }

      return filtered
    }
  },
  watch: {
    filterStatus() {
      this.$nextTick(() => this.initSortable())
    }
  },
  mounted() {
    this.fetchFeatures()
  },
  beforeUnmount() {
    this.destroySortable()
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
        this.$nextTick(() => this.initSortable())
      }
    },
    initSortable() {
      this.destroySortable()
      if (!this.$refs.tableBody) return

      // Only enable drag when viewing planned features
      const plannedIds = this.filteredFeatures
        .filter(f => f.status === 'planned')
        .map(f => String(f.id))

      if (plannedIds.length === 0) return

      this.sortableInstance = Sortable.create(this.$refs.tableBody, {
        animation: 150,
        handle: '.drag-handle',
        ghostClass: 'bg-primary/5',
        chosenClass: 'bg-primary/10',
        dragClass: 'opacity-50',
        filter: (evt, el) => {
          // Only allow dragging planned features
          const id = el.getAttribute('data-id')
          return !plannedIds.includes(id)
        },
        onEnd: (evt) => {
          if (evt.oldIndex === evt.newIndex) return
          this.onReorder()
        }
      })
    },
    destroySortable() {
      if (this.sortableInstance) {
        this.sortableInstance.destroy()
        this.sortableInstance = null
      }
    },
    async onReorder() {
      // Read new order from DOM
      const rows = this.$refs.tableBody.querySelectorAll('tr[data-id]')
      const positions = []
      let pos = 1

      rows.forEach(row => {
        const id = parseInt(row.getAttribute('data-id'))
        const feature = this.features.find(f => f.id === id)
        if (feature && feature.status === 'planned') {
          feature.position = pos
          positions.push({ id, position: pos })
          pos++
        }
      })

      // Save to backend
      this.reorderPending = true
      try {
        await this.service.executePut(
          '/features/reorder.json',
          { positions }
        )
      } catch (error) {
        console.error('Error saving order:', error)
      } finally {
        this.reorderPending = false
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
