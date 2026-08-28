<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Funnel Metrics</h1>
        <p class="page-subtitle">Page views at each stage and how many visitors move on.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'funnels' }" class="btn-secondary">
          Back to Funnels
        </router-link>
      </div>
    </div>

    <!-- Filters -->
    <div class="card flex flex-wrap items-end gap-4 mb-6">
      <div>
        <label class="form-label">Funnel</label>
        <select v-model="filters.funnelSlug" @change="fetchMetrics" class="input-form-field w-auto min-w-48">
          <option value="">All Funnels</option>
          <option v-for="funnel in funnels" :key="funnel.id" :value="funnel.slug">
            {{ funnel.name }}
          </option>
        </select>
      </div>
      <div>
        <label class="form-label">Start Date</label>
        <input type="date" v-model="filters.startDate" @change="fetchMetrics" class="input-form-field w-auto">
      </div>
      <div>
        <label class="form-label">End Date</label>
        <input type="date" v-model="filters.endDate" @change="fetchMetrics" class="input-form-field w-auto">
      </div>
      <button type="button" @click="clearFilters" class="btn-ghost">
        Clear
      </button>
    </div>

    <!-- Stage totals -->
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
      <div class="stat-tile">
        <p class="stat-label">Lead Page</p>
        <p class="stat-value">{{ metrics.lead_page }}</p>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Book Call Page</p>
        <p class="stat-value">{{ metrics.book_call_page }}</p>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Order Page</p>
        <p class="stat-value">{{ metrics.order_page }}</p>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Order Completed</p>
        <p class="stat-value text-emerald-600">{{ metrics.order_completed_page }}</p>
      </div>
    </div>

    <!-- Conversion by stage -->
    <div class="card-flush overflow-x-auto">
      <div class="flex flex-wrap items-center justify-between gap-3 px-6 py-4 border-b border-line">
        <h2 class="section-title">Conversion Funnel</h2>
        <div class="text-right">
          <p class="eyebrow">Overall conversion</p>
          <p class="font-display text-2xl font-extrabold text-primary leading-tight">{{ conversionRates.overall }}%</p>
          <p class="text-xs text-ink-muted">Lead Page to Order Completed</p>
        </div>
      </div>
      <table class="admin-table">
        <thead>
          <tr>
            <th>Stage</th>
            <th>Views</th>
            <th>From previous</th>
            <th class="w-1/2">Share of leads</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="font-medium whitespace-nowrap">Lead Page</td>
            <td class="font-semibold">{{ metrics.lead_page }}</td>
            <td class="text-ink-muted">-</td>
            <td>
              <div class="h-3 rounded-full bg-primary/10 overflow-hidden">
                <div class="h-3 rounded-full bg-primary" style="width: 100%"></div>
              </div>
            </td>
          </tr>
          <tr>
            <td class="font-medium whitespace-nowrap">Book Call Page</td>
            <td class="font-semibold">{{ metrics.book_call_page }}</td>
            <td><span class="badge-brand">{{ conversionRates.lead_to_book_call }}%</span></td>
            <td>
              <div class="h-3 rounded-full bg-primary/10 overflow-hidden">
                <div class="h-3 rounded-full bg-primary/80" :style="{ width: calculateWidth('book_call_page') }"></div>
              </div>
            </td>
          </tr>
          <tr>
            <td class="font-medium whitespace-nowrap">Order Page</td>
            <td class="font-semibold">{{ metrics.order_page }}</td>
            <td><span class="badge-brand">{{ conversionRates.book_call_to_order }}%</span></td>
            <td>
              <div class="h-3 rounded-full bg-primary/10 overflow-hidden">
                <div class="h-3 rounded-full bg-primary/60" :style="{ width: calculateWidth('order_page') }"></div>
              </div>
            </td>
          </tr>
          <tr>
            <td class="font-medium whitespace-nowrap">Order Completed</td>
            <td class="font-semibold text-emerald-600">{{ metrics.order_completed_page }}</td>
            <td><span class="badge-green">{{ conversionRates.order_to_completed }}%</span></td>
            <td>
              <div class="h-3 rounded-full bg-primary/10 overflow-hidden">
                <div class="h-3 rounded-full bg-emerald-500" :style="{ width: calculateWidth('order_completed_page') }"></div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import RestService from '../../../services/RestService.js'

export default {
  name: 'FunnelMetrics',
  data() {
    return {
      model: starter.model,
      funnels: [],
      metrics: {
        lead_page: 0,
        book_call_page: 0,
        order_page: 0,
        order_completed_page: 0
      },
      conversionRates: {
        lead_to_book_call: 0,
        book_call_to_order: 0,
        order_to_completed: 0,
        overall: 0
      },
      filters: {
        funnelSlug: '',
        startDate: '',
        endDate: ''
      }
    }
  },
  mounted() {
    this.fetchFunnels()
    this.fetchMetrics()
  },
  methods: {
    async fetchFunnels() {
      try {
        const service = new RestService('funnels')
        this.funnels = await service.list()
      } catch (error) {
        console.error('Error fetching funnels:', error)
      }
    },
    async fetchMetrics() {
      try {
        this.model.loading = true
        const params = new URLSearchParams()
        if (this.filters.funnelSlug) params.append('funnel_slug', this.filters.funnelSlug)
        if (this.filters.startDate) params.append('start_date', this.filters.startDate)
        if (this.filters.endDate) params.append('end_date', this.filters.endDate)

        const url = `/api/v1/funnels/metrics.json?${params.toString()}&t=${Date.now()}`
        const response = await fetch(url, {
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
          }
        })
        const data = await response.json()

        this.metrics = data.metrics
        this.conversionRates = data.conversion_rates
      } catch (error) {
        console.error('Error fetching metrics:', error)
      } finally {
        this.model.loading = false
      }
    },
    calculateWidth(stage) {
      if (this.metrics.lead_page === 0) return '0%'
      const percentage = (this.metrics[stage] / this.metrics.lead_page) * 100
      return `${Math.max(percentage, 5)}%`
    },
    clearFilters() {
      this.filters = { funnelSlug: '', startDate: '', endDate: '' }
      this.fetchMetrics()
    }
  }
}
</script>
