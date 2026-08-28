<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">Article Details</h1>
        <p class="page-subtitle">{{ post.title || 'Loading article…' }}</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'posts' }" class="btn-secondary">
          Back to Articles
        </router-link>
        <router-link :to="{ name: 'edit-post', params: { id: $route.params.id } }" class="btn-primary">
          Edit
        </router-link>
      </div>
    </div>

    <div class="card mb-6">
      <div class="flex flex-wrap items-center gap-2 mb-6">
        <span :class="post.published ? 'badge-green' : 'badge-gray'">
          {{ post.published ? 'Published' : 'Draft' }}
        </span>
        <span v-if="post.featured" class="badge-amber">Featured</span>
        <span v-if="post.category" class="badge-brand">{{ post.category }}</span>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="md:col-span-2">
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Title</p>
          <div class="text-ink">{{ post.title || '-' }}</div>
        </div>
        <div class="md:col-span-2">
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Description</p>
          <div class="text-ink">{{ post.description || '-' }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Author</p>
          <div class="text-ink">{{ post.author || '-' }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Author Slug</p>
          <div class="text-ink font-mono text-sm">{{ post.author_slug || '-' }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Category</p>
          <div class="text-ink">{{ post.category || '-' }}</div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-1">Published At</p>
          <div class="text-ink">{{ post.published_at || '-' }}</div>
        </div>
      </div>
    </div>

    <div class="card">
      <h2 class="section-title mb-4">Content</h2>
      <div v-if="post.content" class="trix-content max-w-none text-ink" v-html="post.content"></div>
      <p v-else class="text-sm text-ink-muted">No content yet.</p>
    </div>

  </div>
</template>

<script>
import RestService from "../../../services/RestService";

export default {
  name: "PostsDetails",
  data() {
    return {
      post: {
        title: '',
        description: '',
        author: '',
        category: '',
        content: '',
        published: '',
        featured: '',
        published_at: '',
        author_slug: '',
        titleInvalid: false,
        descriptionInvalid: false,
        authorInvalid: false,
        categoryInvalid: false,
        contentInvalid: false,
        publishedInvalid: false,
        featuredInvalid: false,
        publishedAtInvalid: false,
        authorSlugInvalid: false,

      },
      service: new RestService('articles', '/')
    }
  },
  mounted() {
    let postId = this.$route.params.id
    this.service.get(postId).then((response) => {
      this.post = response
    }).catch((message) => {
      console.log('error loading post')
      console.log(message)
    })
  },
}
</script>
