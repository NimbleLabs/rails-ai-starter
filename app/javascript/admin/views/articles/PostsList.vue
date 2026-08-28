<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Articles</h1>
        <p class="page-subtitle">Blog posts and long-form content for the marketing site.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'new-post' }" class="btn-primary">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          New Post
        </router-link>
      </div>
    </div>

    <div class="card-flush overflow-x-auto">
      <table class="admin-table">
        <thead>
        <tr>
          <th>Title</th>
          <th>Author</th>
          <th>Category</th>
          <th>Status</th>
          <th>Featured</th>
          <th>Published At</th>
          <th class="text-right">Actions</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="post in filteredPosts" :key="post.id">
          <td>
            <router-link :to="{ name: 'post-details', params: {id: post.slug} }" class="table-link">
              {{ post.title }}
            </router-link>
          </td>
          <td class="whitespace-nowrap">{{ post.author }}</td>
          <td class="whitespace-nowrap">
            <span v-if="post.category" class="badge-brand">{{ post.category }}</span>
            <span v-else class="text-ink-muted">-</span>
          </td>
          <td class="whitespace-nowrap">
            <span :class="post.published ? 'badge-green' : 'badge-gray'">
              {{ post.published ? 'Published' : 'Draft' }}
            </span>
          </td>
          <td class="whitespace-nowrap">
            <span v-if="post.featured" class="badge-amber">Featured</span>
            <span v-else class="text-ink-muted">-</span>
          </td>
          <td class="whitespace-nowrap text-ink-muted">{{ post.published_at || '-' }}</td>
          <td class="whitespace-nowrap">
            <div class="flex justify-end gap-1">
              <router-link :to="{ name: 'post-details', params: {id: post.slug} }" class="btn-ghost btn-sm" title="View">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                     class="feather feather-grid">
                  <rect x="3" y="3" width="7" height="7"></rect>
                  <rect x="14" y="3" width="7" height="7"></rect>
                  <rect x="14" y="14" width="7" height="7"></rect>
                  <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
              </router-link>

              <router-link :to="{ name: 'edit-post', params: {id: post.slug} }" class="btn-ghost btn-sm" title="Edit">
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
        <tr v-if="filteredPosts.length === 0">
          <td colspan="7" class="empty-state">No articles yet.</td>
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
