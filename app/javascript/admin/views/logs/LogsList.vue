<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Logs</h1>
        <p class="page-subtitle">Exceptions and errors from the app, jobs and mobile clients.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'log-subscriptions' }" class="btn-secondary">Notifications</router-link>
        <button class="btn-secondary" @click="load()">Refresh</button>
      </div>
    </div>

    <!-- Summary -->
    <div class="grid gap-4 sm:grid-cols-3 mb-6">
      <div class="stat-tile">
        <p class="stat-label">Unresolved</p>
        <p class="stat-value">{{ counts.unresolved ?? '—' }}</p>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Errors (last 24h)</p>
        <p class="stat-value">{{ counts.errors_24h ?? '—' }}</p>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Active notifications</p>
        <p class="stat-value">{{ counts.subscriptions ?? '—' }}</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="card flex flex-wrap items-end gap-4 mb-6">
      <div>
        <label class="form-label" for="statusFilter">Status</label>
        <select id="statusFilter" class="input-form-field w-auto" v-model="filter.status" @change="load(1)">
          <option value="unresolved">Unresolved</option>
          <option value="resolved">Resolved</option>
          <option value="all">All</option>
        </select>
      </div>
      <div>
        <label class="form-label" for="levelFilter">Min level</label>
        <select id="levelFilter" class="input-form-field w-auto" v-model="filter.level" @change="load(1)">
          <option value="">Any</option>
          <option value="info">Info+</option>
          <option value="warn">Warn+</option>
          <option value="error">Error+</option>
          <option value="fatal">Fatal</option>
        </select>
      </div>
      <div>
        <label class="form-label" for="sourceFilter">Source</label>
        <select id="sourceFilter" class="input-form-field w-auto" v-model="filter.source" @change="load(1)">
          <option value="">Any</option>
          <option value="web">Web</option>
          <option value="job">Job</option>
          <option value="mobile">Mobile</option>
          <option value="console">Console</option>
          <option value="app">App</option>
        </select>
      </div>
      <div class="flex-1 min-w-48">
        <label class="form-label" for="qFilter">Search</label>
        <input id="qFilter" type="search" class="input-form-field" placeholder="Message, error class or path" v-model="filter.q" @keyup.enter="load(1)">
      </div>
      <button class="btn-ghost" @click="clearFilters()">Clear</button>
    </div>

    <!-- Bulk actions -->
    <div v-if="logs.length" class="flex flex-wrap gap-2 mb-4">
      <button v-if="filter.status !== 'resolved'" class="btn-secondary btn-sm" @click="confirmResolveAll = true">
        Resolve all matching
      </button>
      <button class="btn-ghost btn-sm" @click="confirmDeleteResolved = true">Delete resolved</button>
    </div>

    <!-- Table -->
    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
          <tr>
            <th>Level</th>
            <th>Problem</th>
            <th>Source</th>
            <th>Count</th>
            <th>Last seen</th>
            <th><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in logs" :key="log.id">
            <td><span :class="levelBadge(log.level)">{{ log.level }}</span></td>
            <td>
              <router-link :to="{ name: 'log-details', params: { id: log.id } }" class="table-link">
                {{ log.title }}
              </router-link>
              <p v-if="log.path" class="text-xs text-ink-muted mt-0.5">{{ log.path }}</p>
            </td>
            <td><span class="badge-gray">{{ log.source }}</span></td>
            <td>{{ log.occurrences }}</td>
            <td class="whitespace-nowrap">{{ formatDate(log.last_seen_at) }}</td>
            <td>
              <div class="flex justify-end gap-1">
                <button class="btn-ghost btn-sm" :title="log.resolved ? 'Reopen' : 'Resolve'" @click="toggleResolved(log)">
                  {{ log.resolved ? 'Reopen' : 'Resolve' }}
                </button>
                <router-link :to="{ name: 'log-details', params: { id: log.id } }" class="btn-ghost btn-sm" title="View details">View</router-link>
              </div>
            </td>
          </tr>
          <tr v-if="!logs.length">
            <td colspan="6" class="empty-state">
              {{ loaded ? 'Nothing here — no logs match these filters.' : 'Loading…' }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="card mt-6 flex items-center justify-between">
      <button class="btn-secondary btn-sm" :disabled="page === 1" @click="load(page - 1)">← Previous</button>
      <p class="text-sm text-ink-muted">Page {{ page }} of {{ totalPages }} · {{ total }} total</p>
      <button class="btn-secondary btn-sm" :disabled="page === totalPages" @click="load(page + 1)">Next →</button>
    </div>

    <confirm-modal
      v-if="confirmResolveAll"
      title="Resolve all matching logs?"
      message="Every unresolved log matching the current filters will be marked resolved. You can reopen them individually afterwards."
      confirm-text="Resolve all"
      @confirm="resolveAll()"
      @cancel="confirmResolveAll = false" />

    <confirm-modal
      v-if="confirmDeleteResolved"
      title="Delete resolved logs?"
      message="This permanently deletes every resolved log. This cannot be undone."
      confirm-text="Delete"
      confirm-style="danger"
      @confirm="deleteResolved()"
      @cancel="confirmDeleteResolved = false" />
  </div>
</template>

<script>
import RestService from '../../../services/RestService'
import ConfirmModal from '../../../components/ConfirmModal.vue'

export default {
  name: 'LogsList',
  components: { ConfirmModal },
  data () {
    return {
      model: starter.model,
      service: new RestService('logs', '/'),
      logs: [],
      counts: {},
      total: 0,
      page: 1,
      perPage: 25,
      loaded: false,
      confirmResolveAll: false,
      confirmDeleteResolved: false,
      filter: { status: 'unresolved', level: '', source: '', q: '' }
    }
  },
  computed: {
    totalPages () {
      return Math.max(1, Math.ceil(this.total / this.perPage))
    }
  },
  mounted () {
    this.load()
  },
  methods: {
    queryString (page) {
      const params = new URLSearchParams()
      params.set('page', page)
      params.set('per_page', this.perPage)
      if (this.filter.status) params.set('status', this.filter.status)
      if (this.filter.level) params.set('level', this.filter.level)
      if (this.filter.source) params.set('source', this.filter.source)
      if (this.filter.q) params.set('q', this.filter.q)
      return params.toString()
    },

    load (page = this.page) {
      this.model.loading = true
      const url = `/logs.json?${this.queryString(page)}`
      this.service.executeGet(url).then((response) => {
        this.logs = response.logs || []
        this.total = response.total || 0
        this.page = response.page || 1
        this.perPage = response.per_page || 25
        this.counts = response.counts || {}
        this.loaded = true
        this.model.loading = false
      }).catch((message) => {
        console.log('error loading logs')
        console.log(message)
        this.loaded = true
        this.model.loading = false
      })
    },

    toggleResolved (log) {
      this.service.update(log.id, { log: { resolved: !log.resolved } }).then(() => {
        this.load()
      }).catch((message) => {
        console.log('error updating log')
        console.log(message)
      })
    },

    resolveAll () {
      this.confirmResolveAll = false
      this.model.loading = true
      this.service.executePut(`/logs/resolve_all.json?${this.queryString(1)}`, {}).then(() => {
        this.load(1)
      }).catch((message) => {
        console.log('error resolving logs')
        console.log(message)
        this.model.loading = false
      })
    },

    deleteResolved () {
      this.confirmDeleteResolved = false
      this.model.loading = true
      this.service.remove('destroy_resolved').then(() => {
        this.load(1)
      }).catch((message) => {
        console.log('error deleting resolved logs')
        console.log(message)
        this.model.loading = false
      })
    },

    clearFilters () {
      this.filter = { status: 'unresolved', level: '', source: '', q: '' }
      this.load(1)
    },

    levelBadge (level) {
      return {
        fatal: 'badge-red',
        error: 'badge-red',
        warn: 'badge-amber',
        info: 'badge-blue'
      }[level] || 'badge-gray'
    },

    formatDate (value) {
      if (!value) return '—'
      return new Date(value).toLocaleString('en-US', {
        month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
      })
    }
  }
}
</script>
