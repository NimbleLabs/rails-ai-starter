<template>
  <div class="h-full">
    <router-view></router-view>
  </div>
</template>

<script>

export default {
  name: 'NewApp',
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
