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
      model: {
        loading: false,
      }
    }
  },
  computed: {
    loading() {
      return this.model.loading
    }
  },
  mounted() {
    // const service = new RestService('users')
    // let url = '/api/v1/users/current'
    // service.executeGet(url).then((response) => {
    //   this.model.user = response
    //   nimbleai.services.userService = new UserService(this.model.user)
    //   nimbleai.services.llmService = new RestService('foundation-models', '/')
    //
    //   nimbleai.services.llmService.list().then((foundationModels) => {
    //     this.model.foundationModels = foundationModels
    //   }).catch((message) => {
    //     console.log('error loading foundation models')
    //     console.log(message)
    //   })
    // }).catch((message) => {
    //   console.log('error loading current user')
    //   console.log(message)
    // })
  }
}
</script>
