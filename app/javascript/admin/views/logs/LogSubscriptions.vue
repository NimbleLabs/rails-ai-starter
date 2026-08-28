<template>
  <div class="p-6 lg:p-10 max-w-5xl mx-auto">
    <router-link :to="{ name: 'logs' }" class="text-sm text-ink-muted hover:text-primary">← Back to logs</router-link>

    <div class="page-header mt-4">
      <div>
        <h1 class="page-title">Log notifications</h1>
        <p class="page-subtitle">Who gets told when something lands in the log, and how.</p>
      </div>
      <button class="btn-primary" @click="startNew()">New notification</button>
    </div>

    <div v-if="flash.message" :class="flash.ok ? 'alert-success' : 'alert-error'" class="mb-6">{{ flash.message }}</div>

    <!-- Form -->
    <form v-if="editing" class="card mb-6" @submit.prevent="save()">
      <h2 class="section-title mb-4">{{ editing.id ? 'Edit notification' : 'New notification' }}</h2>

      <div v-if="errors.length" class="alert-error mb-4">
        <ul class="list-disc list-inside">
          <li v-for="(error, index) in errors" :key="index">{{ error }}</li>
        </ul>
      </div>

      <div class="grid gap-4 sm:grid-cols-2">
        <div>
          <label class="form-label" for="subName">Name</label>
          <input id="subName" type="text" class="input-form-field" v-model="editing.name" placeholder="Ops on-call">
          <p class="form-hint">Optional label so you can tell rules apart.</p>
        </div>

        <div>
          <label class="form-label" for="subChannel">Channel</label>
          <select id="subChannel" class="input-form-field" v-model="editing.channel">
            <option value="email">Email</option>
            <option value="slack">Slack</option>
          </select>
        </div>

        <div class="sm:col-span-2">
          <label class="form-label" for="subDestination">Destination</label>
          <input id="subDestination" type="text" class="input-form-field" v-model="editing.destination"
                 :placeholder="editing.channel === 'slack' ? 'https://hooks.slack.com/services/…' : 'ops@example.com'">
          <p class="form-hint">
            {{ editing.channel === 'slack' ? 'A Slack incoming-webhook URL.' : 'An email address. Requires outgoing mail to be configured.' }}
          </p>
        </div>

        <div>
          <label class="form-label" for="subLevel">Notify at or above</label>
          <select id="subLevel" class="input-form-field" v-model="editing.min_level">
            <option value="info">Info</option>
            <option value="warn">Warn</option>
            <option value="error">Error</option>
            <option value="fatal">Fatal</option>
          </select>
          <p class="form-hint">Error is the sensible default. Info will be noisy.</p>
        </div>

        <div>
          <label class="form-label" for="subThrottle">Throttle (minutes)</label>
          <input id="subThrottle" type="number" min="0" max="10080" class="input-form-field" v-model.number="editing.throttle_minutes">
          <p class="form-hint">Minimum gap before the same recurring problem notifies again.</p>
        </div>

        <div class="sm:col-span-2">
          <label class="flex items-center gap-2 text-sm">
            <input type="checkbox" class="form-checkbox" v-model="editing.active">
            Active
          </label>
        </div>
      </div>

      <div class="flex gap-3 justify-end mt-6">
        <button type="button" class="btn-secondary" @click="editing = null">Cancel</button>
        <button type="submit" class="btn-primary">Save</button>
      </div>
    </form>

    <!-- List -->
    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Channel</th>
            <th>Destination</th>
            <th>Level</th>
            <th>Throttle</th>
            <th>Status</th>
            <th><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="subscription in subscriptions" :key="subscription.id">
            <td>{{ subscription.name || '—' }}</td>
            <td><span class="badge-brand">{{ subscription.channel }}</span></td>
            <td class="break-all">{{ subscription.destination }}</td>
            <td><span class="badge-gray">{{ subscription.min_level }}+</span></td>
            <td>{{ subscription.throttle_minutes }}m</td>
            <td>
              <span :class="subscription.active ? 'badge-green' : 'badge-gray'">
                {{ subscription.active ? 'Active' : 'Paused' }}
              </span>
            </td>
            <td>
              <div class="flex justify-end gap-1">
                <button class="btn-ghost btn-sm" title="Send a test notification" @click="sendTest(subscription)">Test</button>
                <button class="btn-ghost btn-sm" @click="edit(subscription)">Edit</button>
                <button class="btn-ghost btn-sm" @click="confirmDelete = subscription">Delete</button>
              </div>
            </td>
          </tr>
          <tr v-if="!subscriptions.length">
            <td colspan="7" class="empty-state">
              No notifications yet. Add one so errors reach a human.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <confirm-modal
      v-if="confirmDelete"
      title="Delete this notification?"
      message="Nobody will be notified through this channel any more."
      confirm-text="Delete"
      confirm-style="danger"
      @confirm="destroy(confirmDelete)"
      @cancel="confirmDelete = null" />
  </div>
</template>

<script>
import RestService from '../../../services/RestService'
import ConfirmModal from '../../../components/ConfirmModal.vue'

const BLANK = {
  id: null, name: '', channel: 'email', destination: '',
  min_level: 'error', active: true, throttle_minutes: 60
}

export default {
  name: 'LogSubscriptions',
  components: { ConfirmModal },
  data () {
    return {
      model: starter.model,
      service: new RestService('log-subscriptions', '/'),
      subscriptions: [],
      editing: null,
      errors: [],
      flash: { message: '', ok: true },
      confirmDelete: null
    }
  },
  mounted () {
    this.load()
  },
  methods: {
    load () {
      this.model.loading = true
      this.service.list().then((response) => {
        this.subscriptions = response
        this.model.loading = false
      }).catch((message) => {
        console.log('error loading log subscriptions')
        console.log(message)
        this.model.loading = false
      })
    },

    startNew () {
      this.errors = []
      this.editing = Object.assign({}, BLANK)
    },

    edit (subscription) {
      this.errors = []
      this.editing = Object.assign({}, subscription)
    },

    save () {
      this.errors = []
      const payload = { log_subscription: this.editing }
      const request = this.editing.id
        ? this.service.update(this.editing.id, payload)
        : this.service.create(payload)

      request.then(() => {
        this.editing = null
        this.setFlash('Notification saved.', true)
        this.load()
      }).catch((response) => {
        this.errors = this.extractErrors(response)
      })
    },

    destroy (subscription) {
      this.confirmDelete = null
      this.service.remove(subscription.id).then(() => {
        this.setFlash('Notification deleted.', true)
        this.load()
      }).catch((message) => {
        console.log('error deleting log subscription')
        console.log(message)
      })
    },

    sendTest (subscription) {
      this.model.loading = true
      this.service.executeEmptyPost(`/log-subscriptions/${subscription.id}/test.json`).then((response) => {
        this.setFlash(response.message || 'Test notification sent.', true)
        this.model.loading = false
        this.load()
      }).catch((response) => {
        this.setFlash((response && response.error) || 'Test notification failed.', false)
        this.model.loading = false
      })
    },

    extractErrors (response) {
      const errors = response && response.errors
      if (!errors) return ['Could not save. Check the fields and try again.']
      if (Array.isArray(errors)) return errors
      return Object.entries(errors).map(([field, messages]) => {
        const text = Array.isArray(messages) ? messages.join(', ') : messages
        return `${field.replace(/_/g, ' ')} ${text}`
      })
    },

    setFlash (message, ok) {
      this.flash = { message, ok }
      setTimeout(() => { this.flash = { message: '', ok: true } }, 6000)
    }
  }
}
</script>
