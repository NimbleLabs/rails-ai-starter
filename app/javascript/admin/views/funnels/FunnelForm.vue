<template>
  <div class="max-w-4xl mx-auto p-6">
    <h1 class="text-2xl font-bold mb-6">{{ isEditing ? 'Edit Funnel' : 'New Funnel' }}</h1>

    <form @submit.prevent="handleSubmit" class="space-y-6">
      <div>
        <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
        <input
          id="name"
          v-model="funnel.name"
          type="text"
          class="input-form-field"
          placeholder="e.g., Summer Sale 2025"
          required
        >
      </div>

      <div>
        <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
        <textarea
          id="description"
          v-model="funnel.description"
          class="input-form-field"
          rows="3"
          placeholder="Optional description for internal reference"
        ></textarea>
      </div>

      <div class="flex items-center gap-2">
        <input
          id="active"
          v-model="funnel.active"
          type="checkbox"
          class="rounded border-gray-300 text-purple-600"
        >
        <label for="active" class="text-sm font-medium text-gray-700">Active</label>
      </div>

      <div v-if="funnel.slug" class="bg-gray-50 p-4 rounded-lg">
        <p class="text-sm text-gray-600 mb-2">Landing Page URLs:</p>
        <ul class="text-sm font-mono space-y-1">
          <li><a :href="`/f/${funnel.slug}/lead`" target="_blank" class="text-purple-600 hover:underline">/f/{{ funnel.slug }}/lead</a></li>
          <li><a :href="`/f/${funnel.slug}/book-call`" target="_blank" class="text-purple-600 hover:underline">/f/{{ funnel.slug }}/book-call</a></li>
          <li><a :href="`/f/${funnel.slug}/order`" target="_blank" class="text-purple-600 hover:underline">/f/{{ funnel.slug }}/order</a></li>
          <li><a :href="`/f/${funnel.slug}/order-completed`" target="_blank" class="text-purple-600 hover:underline">/f/{{ funnel.slug }}/order-completed</a></li>
        </ul>
      </div>

      <div class="flex justify-end gap-4">
        <router-link :to="{ name: 'funnels' }" class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50">
          Cancel
        </router-link>
        <button
          type="submit"
          class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md"
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
