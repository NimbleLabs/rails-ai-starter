<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Emails</h1>
        <p class="page-subtitle">Templates you can send to a subscriber list.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'new-email' }" class="btn-primary">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          New Email
        </router-link>
      </div>
    </div>

    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
        <tr>
          <th>Subject</th>
          <th>List</th>
          <th>Created</th>
          <th class="text-right">Actions</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="emailTemplate in emailTemplates" :key="emailTemplate.id">
          <td class="whitespace-nowrap font-medium">
            {{ emailTemplate.subject }}
          </td>
          <td class="whitespace-nowrap">
            <span class="badge-brand">{{ emailTemplate.send_group }}</span>
          </td>
          <td class="whitespace-nowrap text-ink-muted">
            {{ formatDate(emailTemplate.created_at) }}
          </td>
          <td class="whitespace-nowrap">
            <div class="flex justify-end gap-1">
              <router-link
                  :to="{ name: 'edit-email', params: { id: emailTemplate.id }}"
                  class="btn-ghost btn-sm"
                  title="Edit"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                </svg>
                Edit
              </router-link>

              <button type="button" @click="onSendClicked(emailTemplate)" class="btn-ghost btn-sm" title="Send">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                </svg>
                Send
              </button>
            </div>
          </td>
        </tr>
        <tr v-if="emailTemplates.length === 0">
          <td colspan="4" class="empty-state">No emails yet.</td>
        </tr>
        </tbody>
      </table>
    </div>

    <!-- Confirmation Modal -->
    <confirm-modal
        v-if="showSendModal"
        title="Send Email"
        :message="`Are you sure you want to send this email to ${emailTemplateToSend.send_group}?`"
        confirm-text="Send"
        confirm-style="danger"
        @confirm="onSendConfirmed"
        @cancel="showSendModal = false"
    />

  </div>
</template>

<script>
import RestService from '../../services/RestService'
import ConfirmModal from "../../components/ConfirmModal.vue";

export default {
  name: 'EmailTemplates',
  components: {ConfirmModal},
  data() {
    return {
      model: starter.model,
      emailTemplates: [],
      showSendModal: false,
      emailTemplateToSend: null
    }
  },
  mounted() {
    this.fetchEmailTemplates()
  },
  methods: {
    onSendConfirmed() {
      this.model.loading = true
      this.showSendModal = false
      const service = new RestService('email-templates', '/')
      const url = `/email-templates/${this.emailTemplateToSend.slug}/send`

      service.executeEmptyPost(url).then((response) => {
        this.model.loading = false
        this.$toast?.open({
          message: response.message,
          type: 'success',
          duration: 3000
        });
      }).catch((message) => {
        this.$toast?.open({
          message: 'Failed to send email',
          type: 'error',
          duration: 3000
        });
        console.log(message)
        this.model.loading = false
      })
    },
    onSendClicked(emailTemplate) {
      this.emailTemplateToSend = emailTemplate
      this.showSendModal = true
    },
    async fetchEmailTemplates() {
      try {
        console.log('loading emailTemplates')
        const service = new RestService('email-templates', '/')
        const response = await service.list()
        console.log('emailTemplates loaded')
        console.log(response)
        this.emailTemplates = response
      } catch (error) {
        console.error('Error fetching emailTemplates:', error)
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-'
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      })
    }
  }
}
</script>
