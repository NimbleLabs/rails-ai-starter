<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-subtitle">Welcome to the Starter admin. Jump into a section below.</p>
      </div>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-8">
      <div class="stat-tile">
        <p class="stat-label">Users</p>
        <p class="font-display text-lg font-bold text-ink mt-1">Accounts &amp; API tokens</p>
        <router-link :to="{ name: 'users' }" class="table-link text-sm inline-block mt-3">View &rarr;</router-link>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Contacts</p>
        <p class="font-display text-lg font-bold text-ink mt-1">Leads &amp; sign-ups</p>
        <router-link :to="{ name: 'contacts' }" class="table-link text-sm inline-block mt-3">View &rarr;</router-link>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Articles</p>
        <p class="font-display text-lg font-bold text-ink mt-1">Blog posts &amp; content</p>
        <router-link :to="{ name: 'posts' }" class="table-link text-sm inline-block mt-3">View &rarr;</router-link>
      </div>
      <div class="stat-tile">
        <p class="stat-label">Features</p>
        <p class="font-display text-lg font-bold text-ink mt-1">Roadmap &amp; planning</p>
        <router-link :to="{ name: 'features' }" class="table-link text-sm inline-block mt-3">View &rarr;</router-link>
      </div>
    </div>

    <div class="card">
      <p class="eyebrow">Getting started</p>
      <h2 class="section-title mt-1 mb-4">Make this app yours</h2>
      <ul class="space-y-3 text-sm text-ink">
        <li class="flex gap-3">
          <span class="mt-1 h-2 w-2 shrink-0 rounded-full bg-primary"></span>
          <span>Open <span class="font-semibold">Users</span> to grab an API token for the mobile app and test signed-in requests.</span>
        </li>
        <li class="flex gap-3">
          <span class="mt-1 h-2 w-2 shrink-0 rounded-full bg-primary"></span>
          <span>Publish your first post under <span class="font-semibold">Articles</span>; drafts stay hidden until you mark them published.</span>
        </li>
        <li class="flex gap-3">
          <span class="mt-1 h-2 w-2 shrink-0 rounded-full bg-primary"></span>
          <span>Track upcoming work in <span class="font-semibold">Features</span> and drag planned items to set their order.</span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'NewAppHome',
  props: ['prop1', 'prop2'],
  data () {
    return {
      model: {}
    }
  },
  mounted () {
  },
  methods: {
    importantMethodHere () {
    }
  }
}
</script>
