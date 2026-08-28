<template>
  <div class="h-full flex">
    <loading-spinner :loading="loading"></loading-spinner>
    <MainContainer class="h-full flex-1" />
  </div>
</template>

<script>

import LoadingSpinner from "~/components/LoadingSpinner.vue";
import MainContainer from "~/admin/layout/MainContainer.vue";

export default {
  name: 'AdminApp',
  components: {MainContainer, LoadingSpinner},
  data() {
    return {
      model: starter.model
    }
  },
  computed: {
    loading() {
      return this.model.loading
    }
  },
  mounted() {
    // The host page (app/views/static/admin.html.erb) serializes the signed-in
    // user into window.__currentUser, so the admin boots without a round trip.
    if (window.__currentUser) {
      this.model.user = window.__currentUser
    }
  }
}
</script>
