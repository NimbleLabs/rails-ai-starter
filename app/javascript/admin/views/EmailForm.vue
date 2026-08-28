<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ isEditing ? 'Edit Email' : 'New Email' }}</h1>
        <p class="page-subtitle">Write the message, then send it to a list from the Emails page.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'email-templates' }" class="btn-secondary">
          Back to Emails
        </router-link>
      </div>
    </div>

    <form @submit.prevent="handleSubmit" class="max-w-4xl space-y-6">
      <div class="card">
        <!-- Subject Field -->
        <div class="mb-4">
          <label for="subject" class="form-label">Subject</label>
          <input
            id="subject"
            v-model="emailTemplate.subject"
            type="text"
            class="input-form-field"
            placeholder="Enter email subject"
            required
          >
        </div>

        <!-- Send Group Field -->
        <div class="mb-4">
          <label for="send_group" class="form-label">Send To</label>
          <select
            id="send_group"
            v-model="emailTemplate.send_group"
            class="input-form-field"
            required
          >
            <option value="" disabled>Select recipient group</option>
            <option value="Newsletter">Newsletter</option>
          </select>
          <p class="form-hint">The subscriber list this email will go to.</p>
        </div>

        <!-- Body Field with Trix -->
        <div>
          <label for="body" class="form-label">Body</label>
          <trix-editor
            ref="trixEditor"
            :input="trixInputId"
            class="trix-content min-h-[300px] max-w-none rounded-xl border border-line bg-surface px-4 py-2.5 text-ink focus:border-primary focus:outline-none"
            @trix-change="handleTrixChange"
          ></trix-editor>
          <input
            :id="trixInputId"
            type="hidden"
            :value="emailTemplate.body"
          >
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-3 justify-end">
        <router-link :to="{ name: 'email-templates' }" class="btn-secondary">
          Cancel
        </router-link>
        <button
          type="submit"
          class="btn-primary"
          :disabled="loading"
        >
          <svg
            v-if="loading"
            class="animate-spin -ml-1 h-4 w-4 text-white"
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
