<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ isEditing ? 'Edit Funnel' : 'New Funnel' }}</h1>
        <p class="page-subtitle">Name the funnel and toggle whether its pages are live.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'funnels' }" class="btn-secondary">
          Back to Funnels
        </router-link>
      </div>
    </div>

    <form @submit.prevent="handleSubmit" class="max-w-4xl space-y-6">
      <div class="card">
        <div class="mb-4">
          <label for="name" class="form-label">Name</label>
          <input
            id="name"
            v-model="funnel.name"
            type="text"
            class="input-form-field"
            placeholder="e.g., Summer Sale 2025"
            required
          >
        </div>

        <div class="mb-4">
          <label for="description" class="form-label">Description</label>
          <textarea
            id="description"
            v-model="funnel.description"
            class="input-form-field"
            rows="3"
            placeholder="Optional description for internal reference"
          ></textarea>
        </div>

        <label class="inline-flex items-center gap-2 text-sm text-ink">
          <input
            id="active"
            v-model="funnel.active"
            type="checkbox"
            class="form-checkbox"
          >
          <span class="font-medium">Active</span>
        </label>
        <p class="form-hint">Inactive funnels return a not-found page for visitors.</p>
      </div>

      <div v-if="funnel.slug" class="panel-muted">
        <p class="eyebrow mb-2">Landing page URLs</p>
        <ul class="text-sm font-mono space-y-1">
          <li><a :href="`/f/${funnel.slug}/lead`" target="_blank" class="table-link">/f/{{ funnel.slug }}/lead</a></li>
          <li><a :href="`/f/${funnel.slug}/book-call`" target="_blank" class="table-link">/f/{{ funnel.slug }}/book-call</a></li>
          <li><a :href="`/f/${funnel.slug}/order`" target="_blank" class="table-link">/f/{{ funnel.slug }}/order</a></li>
          <li><a :href="`/f/${funnel.slug}/order-completed`" target="_blank" class="table-link">/f/{{ funnel.slug }}/order-completed</a></li>
        </ul>
      </div>

      <div class="flex gap-3 justify-end">
        <router-link :to="{ name: 'funnels' }" class="btn-secondary">
          Cancel
        </router-link>
        <button
          type="submit"
          class="btn-primary"
          :disabled="loading"
        >
          {{ loading ? 'Saving...' : (isEditing ? 'Update Funnel' : 'Create Funnel') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import RestService from '../../../services/RestService.js'

export default {
  name: 'FunnelForm',
  data() {
    return {
      service: new RestService('funnels'),
      funnel: {
        id: null,
        name: '',
        description: '',
        active: true,
        slug: ''
      },
      loading: false
    }
  },
  computed: {
    isEditing() {
      return !!this.funnel.id
    }
  },
  mounted() {
    if (this.$route.params.id) {
      this.loadFunnel()
    }
  },
  methods: {
    async loadFunnel() {
      try {
        this.funnel = await this.service.get(this.$route.params.id)
      } catch (error) {
        console.error('Error loading funnel:', error)
      }
    },
    async handleSubmit() {
      try {
        this.loading = true
        const request = { funnel: this.funnel }

        if (this.isEditing) {
          await this.service.update(this.$route.params.id, request)
        } else {
          await this.service.create(request)
        }

        this.$router.push({ name: 'funnels' })
      } catch (error) {
        console.error('Error saving funnel:', error)
      } finally {
        this.loading = false
      }
    }
  }
}
</script>
