<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Welcome</h1>
        <p class="page-subtitle">You're signed in to the Starter app.</p>
      </div>
    </div>

    <div class="card">
      <p class="eyebrow">Home</p>
      <h2 class="section-title mt-1 mb-2">Nothing here yet</h2>
      <p class="text-sm text-ink-muted">
        This is the signed-in app shell. Replace this card with your product's first screen.
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Home',
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
