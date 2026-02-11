<template>
  <div class="max-w-4xl mx-auto p-6">
    <h1 class="text-2xl font-bold mb-6">{{ isEditing ? 'Edit Feature' : 'New Feature' }}</h1>

    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Title -->
      <div>
        <label for="title" class="block text-sm font-medium text-gray-700">Title *</label>
        <input
          id="title"
          v-model="feature.title"
          type="text"
          class="input-form-field"
          placeholder="e.g., Add user authentication"
          required
        >
      </div>

      <!-- Description -->
      <div>
        <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
        <textarea
          id="description"
          v-model="feature.description"
          class="input-form-field"
          rows="3"
          placeholder="Brief description of the feature"
        ></textarea>
      </div>

      <!-- Status and Priority Row -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label for="status" class="block text-sm font-medium text-gray-700">Status</label>
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
          <label for="priority" class="block text-sm font-medium text-gray-700">Priority</label>
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

      <!-- Area -->
      <div>
        <label for="area" class="block text-sm font-medium text-gray-700">Area</label>
        <input
          id="area"
          v-model="feature.area"
          type="text"
          class="input-form-field"
          placeholder="e.g., Backend, Frontend, API, Infrastructure"
        >
      </div>

      <!-- Acceptance Criteria -->
      <div>
        <label for="acceptance_criteria" class="block text-sm font-medium text-gray-700">Acceptance Criteria</label>
        <textarea
          id="acceptance_criteria"
          v-model="feature.acceptance_criteria"
          class="input-form-field"
          rows="4"
          placeholder="- Criteria 1&#10;- Criteria 2&#10;- Criteria 3"
        ></textarea>
      </div>

      <!-- Plan -->
      <div>
        <label for="plan" class="block text-sm font-medium text-gray-700">Implementation Plan</label>
        <textarea
          id="plan"
          v-model="feature.plan"
          class="input-form-field"
          rows="4"
          placeholder="High-level plan for implementing this feature"
        ></textarea>
      </div>

      <!-- Implementation Notes -->
      <div>
        <label for="implementation_notes" class="block text-sm font-medium text-gray-700">Implementation Notes</label>
        <textarea
          id="implementation_notes"
          v-model="feature.implementation_notes"
          class="input-form-field"
          rows="4"
          placeholder="Technical notes, decisions made, etc."
        ></textarea>
      </div>

      <!-- Dates Row -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label for="started_at" class="block text-sm font-medium text-gray-700">Started At</label>
          <input
            id="started_at"
            v-model="feature.started_at"
            type="datetime-local"
            class="input-form-field"
          >
        </div>

        <div>
          <label for="completed_at" class="block text-sm font-medium text-gray-700">Completed At</label>
          <input
            id="completed_at"
            v-model="feature.completed_at"
            type="datetime-local"
            class="input-form-field"
          >
        </div>
      </div>

      <!-- Form Actions -->
      <div class="flex justify-end gap-4 pt-4 border-t">
        <router-link :to="{ name: 'features' }" class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50">
          Cancel
        </router-link>
        <button
          type="submit"
          class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md cursor-pointer"
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
