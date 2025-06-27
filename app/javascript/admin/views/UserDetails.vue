<template>
  <div class="p-6">

    <h1 class="text-2xl font-bold mb-5">User Details</h1>

    <div class="flex items-center justify-end mb-3">
      <div>
        <router-link :to="{ name: 'users' }" class="btn btn-secondary">
          Back to Users
        </router-link>
      </div>
    </div>

    <div>
      <div><strong>Name:</strong> {{ user.name }}</div>
    </div>
  </div>
</template>

<script>
import RestService from "@/services/RestService.js";

export default {
  name: 'UserDetails',
  props: ['prop1', 'prop2'],
  data() {
    return {
      user: {
        id: null,
        name: '',
        email: '',
        created_at: '2021-09-22T15:25:00.000Z',
        updated_at: '2021-09-22T15:25:00.000Z',
      }
    }
  },
  mounted() {
    this.loadUser()
  },
  methods: {
    async loadUser() {
      try {
        console.log('loading users')
        const service = new RestService('users')
        const response = await service.get(this.$route.params.id)
        console.log('user loaded')
        console.log(response)
        this.user = response
      } catch (error) {
        console.error('Error fetching users:', error)
      }
    },
  }
}
</script>
