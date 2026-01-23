<template>
  <div class="p-6">
    <h1 class="text-2xl font-bold mb-6">Funnel Metrics</h1>

    <!-- Filters -->
    <div class="bg-white p-4 rounded-lg shadow mb-6 flex flex-wrap gap-4 items-end">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Funnel</label>
        <select v-model="filters.funnelSlug" @change="fetchMetrics" class="input-form-field w-48">
          <option value="">All Funnels</option>
          <option v-for="funnel in funnels" :key="funnel.id" :value="funnel.slug">
            {{ funnel.name }}
          </option>
        </select>
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
        <input type="date" v-model="filters.startDate" @change="fetchMetrics" class="input-form-field">
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
        <input type="date" v-model="filters.endDate" @change="fetchMetrics" class="input-form-field">
      </div>
      <button @click="clearFilters" class="text-purple-600 hover:text-purple-800 text-sm">
        Clear Filters
      </button>
    </div>

    <!-- Funnel Visualization -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-semibold mb-4">Conversion Funnel</h2>

      <div class="space-y-4">
        <!-- Lead Page -->
        <div class="funnel-stage">
          <div class="flex justify-between items-center mb-2">
            <span class="font-medium">Lead Page</span>
            <span class="text-2xl font-bold">{{ metrics.lead_page }}</span>
          </div>
          <div class="h-8 bg-purple-600 rounded" style="width: 100%"></div>
        </div>

        <!-- Arrow + Conversion Rate -->
        <div class="flex items-center justify-center text-gray-500">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
          </svg>
          <span class="ml-2 text-sm">{{ conversionRates.lead_to_book_call }}% conversion</span>
        </div>

        <!-- Book Call Page -->
        <div class="funnel-stage">
          <div class="flex justify-between items-center mb-2">
            <span class="font-medium">Book Call Page</span>
            <span class="text-2xl font-bold">{{ metrics.book_call_page }}</span>
          </div>
          <div class="h-8 bg-purple-500 rounded" :style="{ width: calculateWidth('book_call_page') }"></div>
        </div>

        <!-- Arrow + Conversion Rate -->
        <div class="flex items-center justify-center text-gray-500">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
          </svg>
          <span class="ml-2 text-sm">{{ conversionRates.book_call_to_order }}% conversion</span>
        </div>

        <!-- Order Page -->
        <div class="funnel-stage">
          <div class="flex justify-between items-center mb-2">
            <span class="font-medium">Order Page</span>
            <span class="text-2xl font-bold">{{ metrics.order_page }}</span>
          </div>
          <div class="h-8 bg-purple-400 rounded" :style="{ width: calculateWidth('order_page') }"></div>
        </div>

        <!-- Arrow + Conversion Rate -->
        <div class="flex items-center justify-center text-gray-500">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
          </svg>
          <span class="ml-2 text-sm">{{ conversionRates.order_to_completed }}% conversion</span>
        </div>

        <!-- Order Completed -->
        <div class="funnel-stage">
          <div class="flex justify-between items-center mb-2">
            <span class="font-medium">Order Completed</span>
            <span class="text-2xl font-bold text-green-600">{{ metrics.order_completed_page }}</span>
          </div>
          <div class="h-8 bg-green-500 rounded" :style="{ width: calculateWidth('order_completed_page') }"></div>
        </div>
      </div>

      <!-- Overall Conversion Rate -->
      <div class="mt-8 p-4 bg-gray-50 rounded-lg text-center">
        <p class="text-sm text-gray-600">Overall Conversion Rate</p>
        <p class="text-3xl font-bold text-purple-600">{{ conversionRates.overall }}%</p>
        <p class="text-sm text-gray-500">From Lead Page to Order Completed</p>
      </div>
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
