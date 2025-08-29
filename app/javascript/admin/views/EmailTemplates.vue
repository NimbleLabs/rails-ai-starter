<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Emails</h1>
      <router-link
          :to="{ name: 'new-email' }"
          class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg inline-flex items-center gap-2 transition duration-150"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
        </svg>
        New Email
      </router-link>
    </div>

    <div class="overflow-x-auto text-sm">
      <table class="min-w-full bg-white border border-gray-200">
        <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">List</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
        </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
        <tr v-for="emailTemplate in emailTemplates" :key="emailTemplate.id" class="hover:bg-gray-50">
          <td class="px-6 py-4 whitespace-nowrap">
            {{ emailTemplate.subject }}
          </td>
          <td class="px-6 py-4 whitespace-nowrap">
            {{ emailTemplate.send_group }}
          </td>
          <td class="px-6 py-4 whitespace-nowrap">
            {{ formatDate(emailTemplate.created_at) }}
          </td>
          <td class="px-6 py-4 flex whitespace-nowrap">
            <router-link
                :to="{ name: 'edit-email', params: { id: emailTemplate.id }}"
                class="text-purple-600 hover:text-purple-900 inline-flex items-center"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
              </svg>
              Edit
            </router-link>

            <button @click="onSendClicked(emailTemplate)"
                    class="cursor-pointer ml-2 text-purple-600 hover:text-purple-900 inline-flex items-center">
              Send
            </button>

          </td>
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
