<template>
  <div class="p-10">
    <h1 class="font-extrabold text-4xl md:text-5xl tracking-tight">Articles</h1>

    <div class="my-5 flex items-center">
      <div>
        <router-link :to="{ name: 'new-post' }" class="bg-purple-600 hover:bg-purple-800 text-white px-8 py-2 rounded-lg">
          New Post
        </router-link>
      </div>

    </div>

    <div class="w-full text-sm">
      <table class="min-w-full">
        <thead>
        <tr>
          <th>Title</th>
          <th>Author</th>
          <th>Category</th>
          <th>Published</th>
          <th>Featured</th>
          <th>Published At</th>
          <th></th>
        </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
        <tr v-for="post in filteredPosts" class="my-1">
          <td class="py-3">{{ post.title }}</td>
          <td class="py-3">{{ post.author }}</td>
          <td class="py-3">{{ post.category }}</td>
          <td class="py-3">
            <i class="fas fa-check-circle" :class="post.published ? 'text-green-500' : 'text-zinc-200'"></i>
          </td>
          <td class="py-3">
            <i class="fas fa-check-circle" :class="post.featured ? 'text-green-500' : 'text-zinc-200'"></i>
          </td>
          <td class="py-3">{{ post.published_at }}</td>
          <td class="py-3">
            <div class="flex">
            <router-link :to="{ name: 'post-details', params: {id: post.slug} }" class="mr-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                   class="feather feather-grid">
                <rect x="3" y="3" width="7" height="7"></rect>
                <rect x="14" y="3" width="7" height="7"></rect>
                <rect x="14" y="14" width="7" height="7"></rect>
                <rect x="3" y="14" width="7" height="7"></rect>
              </svg>
            </router-link>

            <router-link :to="{ name: 'edit-post', params: {id: post.slug} }">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                   class="feather feather-edit">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              </svg>
            </router-link>
            </div>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

  </div>
</template>

<script>
import RestService from "../../../services/RestService";

export default {
  name: "PostsList",
  data() {
    return {
      model: starter.model,
      posts: [],
      service: new RestService('articles', '/'),
      filter: {
        category: null,
        author: null,
      },
    }
  },
  computed: {
    filteredPosts() {
      let postList = this.posts

      if (this.filter.category !== null) {
        postList = postList.filter((post) => {
          return this.filter.category === post.category
        })
      }

      if (this.filter.author !== null) {
        postList = postList.filter((post) => {
          return this.filter.author === post.author
        })
      }

      return postList
    }
  },
  mounted() {
    this.model.loading = true
    this.service.list().then((response) => {
      this.posts = response
      this.model.loading = false
    }).catch((message) => {
      // TODO: display alert
      console.log('error loading posts')
      console.log(message)
      this.model.loading = false
    })
  },
  methods: {
    onDeleteClick(post) {
    },
    onEditClick(post) {
    },
    clearFilters() {
      this.filter.category = null
      this.filter.author = null
    }
  }
}
</script>

<style scoped>

</style>

