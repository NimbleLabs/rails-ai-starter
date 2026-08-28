<template>
  <div class="p-6 lg:p-10 max-w-5xl mx-auto">
    <router-link :to="{ name: 'logs' }" class="text-sm text-ink-muted hover:text-primary">← Back to logs</router-link>

    <div v-if="log.id" class="page-header mt-4">
      <div class="min-w-0">
        <p class="eyebrow mb-2">
          <span :class="levelBadge">{{ log.level }}</span>
          <span class="badge-gray ml-1">{{ log.source }}</span>
        </p>
        <h1 class="page-title break-words">{{ log.title }}</h1>
        <p class="page-subtitle">
          Seen {{ log.occurrences }}&times; · last {{ formatDate(log.last_seen_at) }} · first {{ formatDate(log.created_at) }}
        </p>
      </div>
      <div class="flex gap-2 shrink-0">
        <button class="btn-secondary" @click="toggleResolved()">{{ log.resolved ? 'Reopen' : 'Resolve' }}</button>
        <button class="btn-danger" @click="confirmDelete = true">Delete</button>
      </div>
    </div>

    <div v-if="log.resolved" class="alert-success mb-6">
      Resolved {{ formatDate(log.resolved_at) }}<span v-if="log.context && log.context.resolved_by"> by {{ log.context.resolved_by }}</span>.
    </div>

    <div v-if="log.id" class="grid gap-6">
      <div class="card">
        <h2 class="section-title mb-4">Details</h2>
        <dl class="grid gap-x-6 gap-y-3 sm:grid-cols-2 text-sm">
          <div v-for="row in detailRows" :key="row.label">
            <dt class="text-ink-muted">{{ row.label }}</dt>
            <dd class="font-medium break-words">{{ row.value }}</dd>
          </div>
        </dl>
      </div>

      <div v-if="log.message" class="card">
        <h2 class="section-title mb-3">Message</h2>
        <pre class="panel-muted text-sm whitespace-pre-wrap break-words overflow-x-auto">{{ log.message }}</pre>
      </div>

      <div v-if="log.backtrace" class="card">
        <h2 class="section-title mb-3">Backtrace</h2>
        <pre class="panel-muted text-xs leading-relaxed whitespace-pre-wrap break-words overflow-x-auto">{{ log.backtrace }}</pre>
      </div>

      <div v-if="hasContext" class="card">
        <h2 class="section-title mb-3">Context</h2>
        <pre class="panel-muted text-xs leading-relaxed whitespace-pre-wrap break-words overflow-x-auto">{{ prettyContext }}</pre>
      </div>
    </div>

    <div v-else-if="loaded" class="card text-center py-12">
      <p class="text-ink-muted">That log no longer exists.</p>
    </div>

    <confirm-modal
      v-if="confirmDelete"
      title="Delete this log?"
      message="This permanently removes the log entry. This cannot be undone."
      confirm-text="Delete"
      confirm-style="danger"
      @confirm="destroy()"
      @cancel="confirmDelete = false" />
  </div>
</template>

<script>
import RestService from '../../../services/RestService'
import ConfirmModal from '../../../components/ConfirmModal.vue'

export default {
  name: 'LogDetails',
  components: { ConfirmModal },
  data () {
    return {
      model: starter.model,
      service: new RestService('logs', '/'),
      log: {},
      loaded: false,
      confirmDelete: false
    }
  },
  computed: {
    levelBadge () {
      return {
        fatal: 'badge-red',
        error: 'badge-red',
        warn: 'badge-amber',
        info: 'badge-blue'
      }[this.log.level] || 'badge-gray'
    },
    hasContext () {
      return this.log.context && Object.keys(this.log.context).length > 0
    },
    prettyContext () {
      try {
        return JSON.stringify(this.log.context, null, 2)
      } catch (e) {
        return String(this.log.context)
      }
    },
    detailRows () {
      const rows = [
        { label: 'Error class', value: this.log.error_class || '—' },
        { label: 'Source', value: this.log.source },
        { label: 'Occurrences', value: this.log.occurrences },
        { label: 'Path', value: this.log.path || '—' },
        { label: 'User', value: this.log.user ? `${this.log.user.name || this.log.user.email}` : 'Anonymous' },
        { label: 'Request ID', value: this.log.request_id || '—' },
        { label: 'Notified', value: this.log.notified_at ? this.formatDate(this.log.notified_at) : 'Not notified' },
        { label: 'Fingerprint', value: (this.log.fingerprint || '').slice(0, 12) }
      ]
      return rows
    }
  },
  mounted () {
    this.load()
  },
  methods: {
    load () {
      this.model.loading = true
      this.service.get(this.$route.params.id).then((response) => {
        this.log = response
        this.loaded = true
        this.model.loading = false
      }).catch((message) => {
        console.log('error loading log')
        console.log(message)
        this.loaded = true
        this.model.loading = false
      })
    },

    toggleResolved () {
      this.service.update(this.log.id, { log: { resolved: !this.log.resolved } }).then((response) => {
        this.log = response
      }).catch((message) => {
        console.log('error updating log')
        console.log(message)
      })
    },

    destroy () {
      this.confirmDelete = false
      this.service.remove(this.log.id).then(() => {
        this.$router.push({ name: 'logs' })
      }).catch((message) => {
        console.log('error deleting log')
        console.log(message)
      })
    },

    formatDate (value) {
      if (!value) return '—'
      return new Date(value).toLocaleString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit'
      })
    }
  }
}
</script>
