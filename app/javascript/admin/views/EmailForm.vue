<template>
  <div class="max-w-4xl mx-auto p-6">
    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Subject Field -->
      <div>
        <label for="subject" class="block text-sm font-medium text-gray-700">
          Subject
        </label>
        <input
          id="subject"
          v-model="emailTemplate.subject"
          type="text"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-purple-500 focus:outline-none focus:ring-0 sm:text-sm"
          placeholder="Enter email subject"
          required
        >
      </div>

      <!-- Send Group Field -->
      <div>
        <label for="send_group" class="block text-sm font-medium text-gray-700">
          Send To
        </label>
        <select
          id="send_group"
          v-model="emailTemplate.send_group"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-purple-500 focus:outline-none focus:ring-0 sm:text-sm"
          required
        >
          <option value="" disabled>Select recipient group</option>
          <option value="Users">Users</option>
          <option value="Equipment Finance">Equipment Finance</option>
        </select>
      </div>

      <!-- Body Field with Trix -->
      <div>
        <label for="body" class="block text-sm font-medium text-gray-700">
          Body
        </label>
        <div class="mt-1">
          <trix-editor
            ref="trixEditor"
            :input="trixInputId"
            class="trix-content min-h-[300px] prose max-w-none rounded-md border-gray-300 shadow-sm focus:border-purple-500 focus:outline-none focus:ring-0"
            @trix-change="handleTrixChange"
          ></trix-editor>
          <input
            :id="trixInputId"
            type="hidden"
            :value="emailTemplate.body"
          >
        </div>
      </div>

      <!-- Submit Button -->
      <div class="flex justify-end">
        <button
          type="submit"
          class="inline-flex justify-center rounded-md border border-transparent bg-purple-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-purple-700 focus:outline-none focus:ring-0 disabled:opacity-50"
          :disabled="loading"
        >
          <svg
            v-if="loading"
            class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          {{ submitButtonText }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import Trix from 'trix'
import 'trix/dist/trix.css'
import RestService from '../../services/RestService.js'

export default {
  name: 'EmailForm',
  data() {
    return {
      service: new RestService('email-templates', '/'),
      emailTemplate: {
        id: null,
        subject: '',
        body: '',
        send_group: ''
      },
      loading: false,
      trixInputId: `trix-input-${Math.random().toString(36).substr(2, 9)}`
    }
  },

  computed: {
    submitButtonText() {
      if (this.loading) return 'Saving...'
      return this.emailTemplate.id ? 'Update Email Template' : 'Create Email Template'
    },

    isEditing() {
      return !!this.emailTemplate.id
    }
  },

  mounted() {
    if (this.$route.params.id) {
      this.loadEmailTemplate()
    }
  },

  methods: {
    loadEmailTemplate() {
      this.service.get(this.$route.params.id).then(response => {
        this.emailTemplate = response

        if (this.isEditing && this.$refs.trixEditor) {
          this.$refs.trixEditor.editor.loadHTML(this.emailTemplate.body)
        }

      }).catch(error => {
        console.error('Error fetching user:', error)
      })
    },
    handleTrixChange(e) {
      this.emailTemplate.body = e.target.innerHTML
    },

    async handleSubmit() {
      try {
        this.loading = true

        const request = {
          email_template: this.emailTemplate
        }

        if (this.isEditing ) {
          await this.service.update(this.$route.params.id, request)
        } else {
          await this.service.create(request)
        }

        this.$router.push({name: 'email-templates'})

      } catch (error) {
        console.error('Error saving template:', error)
        // You might want to add proper error handling/display here
      } finally {
        this.loading = false
      }
    }
  }
}
</script>
