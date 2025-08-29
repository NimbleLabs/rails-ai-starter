<template>
  <div>
    <h1>Posts Details</h1>

    <div class="p-5 border border-gray-300">
      <div>
        <strong>Title:</strong> {{ post.title }}
      </div>
      <div>
        <strong>Description:</strong> {{ post.description }}
      </div>
      <div>
        <strong>Author:</strong> {{ post.author }}
      </div>
      <div>
        <strong>Category:</strong> {{ post.category }}
      </div>
      <div>
        <strong>Published:</strong> {{ post.published }}
      </div>
      <div>
        <strong>Featured:</strong> {{ post.featured }}
      </div>
      <div>
        <strong>Published At:</strong> {{ post.published_at }}
      </div>
      <div>
        <strong>Author Slug:</strong> {{ post.author_slug }}
      </div>
    </div>

    <div class="mt-5">
      <h2 class="text-3xl my-5">Content</h2>
      <hr class="mb-3">
      <div v-html="post.content"></div>
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

