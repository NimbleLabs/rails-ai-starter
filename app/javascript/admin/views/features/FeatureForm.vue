<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ isEditing ? 'Edit Feature' : 'New Feature' }}</h1>
        <p class="page-subtitle">Describe the work, set its status and priority, and capture the plan.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'features' }" class="btn-secondary">
          Back to Features
        </router-link>
      </div>
    </div>

    <form @submit.prevent="handleSubmit" class="max-w-4xl space-y-6">
      <!-- Details -->
      <div class="card">
        <h2 class="section-title mb-4">Details</h2>

        <div class="mb-4">
          <label for="title" class="form-label">Title *</label>
          <input
            id="title"
            v-model="feature.title"
            type="text"
            class="input-form-field"
            placeholder="e.g., Add user authentication"
            required
          >
        </div>

        <div class="mb-4">
          <label for="description" class="form-label">Description</label>
          <textarea
            id="description"
            v-model="feature.description"
            class="input-form-field"
            rows="3"
            placeholder="Brief description of the feature"
          ></textarea>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label for="status" class="form-label">Status</label>
            <select
              id="status"
              v-model="feature.status"
              class="input-form-field"
            >
              <option value="backlog">Backlog</option>
              <option value="planned">Planned</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>

          <div>
            <label for="priority" class="form-label">Priority</label>
            <select
              id="priority"
              v-model="feature.priority"
              class="input-form-field"
            >
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="critical">Critical</option>
            </select>
          </div>
        </div>

        <div>
          <label for="area" class="form-label">Area</label>
          <input
            id="area"
            v-model="feature.area"
            type="text"
            class="input-form-field"
            placeholder="e.g., Backend, Frontend, API, Infrastructure"
          >
        </div>
      </div>

      <!-- Planning -->
      <div class="card">
        <h2 class="section-title mb-4">Planning</h2>

        <div class="mb-4">
          <label for="acceptance_criteria" class="form-label">Acceptance Criteria</label>
          <textarea
            id="acceptance_criteria"
            v-model="feature.acceptance_criteria"
            class="input-form-field"
            rows="4"
            placeholder="- Criteria 1&#10;- Criteria 2&#10;- Criteria 3"
          ></textarea>
        </div>

        <div class="mb-4">
          <label for="plan" class="form-label">Implementation Plan</label>
          <textarea
            id="plan"
            v-model="feature.plan"
            class="input-form-field"
            rows="4"
            placeholder="High-level plan for implementing this feature"
          ></textarea>
        </div>

        <div>
          <label for="implementation_notes" class="form-label">Implementation Notes</label>
          <textarea
            id="implementation_notes"
            v-model="feature.implementation_notes"
            class="input-form-field"
            rows="4"
            placeholder="Technical notes, decisions made, etc."
          ></textarea>
        </div>
      </div>

      <!-- Timeline -->
      <div class="card">
        <h2 class="section-title mb-4">Timeline</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label for="started_at" class="form-label">Started At</label>
            <input
              id="started_at"
              v-model="feature.started_at"
              type="datetime-local"
              class="input-form-field"
            >
          </div>

          <div>
            <label for="completed_at" class="form-label">Completed At</label>
            <input
              id="completed_at"
              v-model="feature.completed_at"
              type="datetime-local"
              class="input-form-field"
            >
          </div>
        </div>
      </div>

      <!-- Form Actions -->
      <div class="flex gap-3 justify-end">
        <router-link :to="{ name: 'features' }" class="btn-secondary">
          Cancel
        </router-link>
        <button
          type="submit"
          class="btn-primary"
          :disabled="loading"
        >
          {{ loading ? 'Saving...' : (isEditing ? 'Update Feature' : 'Create Feature') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import RestService from '../../../services/RestService.js'

export default {
  name: 'FeatureForm',
  data() {
    return {
      service: new RestService('features', '/'),
      feature: {
        id: null,
        title: '',
        description: '',
        status: 'backlog',
        priority: 'medium',
        area: '',
        acceptance_criteria: '',
        plan: '',
        implementation_notes: '',
        started_at: null,
        completed_at: null
      },
      loading: false
    }
  },
  computed: {
    isEditing() {
      return !!this.feature.id
    }
  },
  mounted() {
    if (this.$route.params.id) {
      this.loadFeature()
    }
  },
  methods: {
    async loadFeature() {
      try {
        const data = await this.service.get(this.$route.params.id)
        this.feature = {
          ...data,
          started_at: this.formatDateForInput(data.started_at),
          completed_at: this.formatDateForInput(data.completed_at)
        }
      } catch (error) {
        console.error('Error loading feature:', error)
      }
    },
    formatDateForInput(dateString) {
      if (!dateString) return null
      const date = new Date(dateString)
      return date.toISOString().slice(0, 16)
    },
    async handleSubmit() {
      try {
        this.loading = true
        const request = { feature: this.feature }

        if (this.isEditing) {
          await this.service.update(this.$route.params.id, request)
        } else {
          await this.service.create(request)
        }

        this.$router.push({ name: 'features' })
      } catch (error) {
        console.error('Error saving feature:', error)
      } finally {
        this.loading = false
      }
    }
  }
}
</script>
