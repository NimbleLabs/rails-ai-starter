<template>
  <div class="p-6 lg:p-10 max-w-7xl mx-auto">
    <div class="page-header">
      <div>
        <h1 class="page-title">{{ post.id ? 'Edit Article' : 'New Article' }}</h1>
        <p class="page-subtitle">Content autosaves while you're editing the body.</p>
      </div>
      <div class="flex gap-2">
        <router-link :to="{ name: 'posts' }" class="btn-secondary">
          Cancel
        </router-link>
        <button type="button" class="btn-primary" @click.prevent="onSaveClick">Save</button>
      </div>
    </div>

    <div class="max-w-4xl space-y-6">
      <div class="card">
        <h2 class="section-title mb-4">Details</h2>

        <div class="mb-4">
          <label for="titleInput" class="form-label">Title</label>
          <input type="text" class="input-form-field" id="titleInput" v-model="post.title">
        </div>
        <div class="mb-4">
          <label for="descriptionInput" class="form-label">Description</label>
          <input type="text" class="input-form-field" id="descriptionInput"
                 v-model="post.description">
          <p class="form-hint">Short summary shown in listings and previews.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label for="authorInput" class="form-label">Author</label>
            <input type="text" class="input-form-field" id="authorInput" v-model="post.author">
          </div>
          <div>
            <label for="categoryInput" class="form-label">Category</label>
            <select
                id="categoryInput"
                class="input-form-field"
                v-model="post.category">
              <option v-for="category in model.categories" :value="category">{{ category }}</option>
            </select>
          </div>
        </div>

        <div class="flex flex-wrap gap-6">
          <label class="inline-flex items-center gap-2 text-sm text-ink">
            <input type="checkbox" v-model="post.published" class="form-checkbox">
            <span>Published</span>
          </label>

          <label class="inline-flex items-center gap-2 text-sm text-ink">
            <input type="checkbox" v-model="post.featured" class="form-checkbox">
            <span>Featured</span>
          </label>
        </div>
      </div>

      <div v-if="contentReady" class="card">
        <h2 class="section-title mb-4">Content</h2>
        <label for="articleContentEditor" class="form-label">Body</label>
        <vue3-trix-editor :data-object="post" field-name="content" text-id="articleContentEditor"
                          @onFocus="onFocus" @onFocusOut="onFocusOut"></vue3-trix-editor>
      </div>

      <div class="card">
        <h2 class="section-title mb-4">Featured Image</h2>
        <button type="button" class="btn-outline btn-sm" @click="showImageModal = true">Select Image</button>

        <div v-if="selectedImage" class="mt-4">
          <img class="w-96 max-w-full rounded-xl border border-line" :src="selectedImage.url">
        </div>
      </div>
      <!--      <div class="mb-4">-->
      <!--        <label for="publishedAtInput" class="form-label">Published at</label>-->
      <!--        <input type="text" class="input-form-field" id="published_atInput"-->
      <!--               v-model="post.published_at">-->
      <!--      </div>-->

      <div class="flex gap-3 justify-end">
        <router-link :to="{ name: 'posts' }" class="btn-secondary">
          Cancel
        </router-link>
        <button type="button" class="btn-primary" @click.prevent="onSaveClick">Save</button>
      </div>

    </div>

<!--    <select-image-modal v-if="showImageModal" @noEvent="showImageModal = false"-->
<!--                        :yes-event="onImageSelected"></select-image-modal>-->

  </div>
</template>

<script>

import RestService from "../../../services/RestService";
import Vue3TrixEditor from "../../../components/Vue3TrixEditor.vue";
// import SelectImageModal from "../../modals/SelectImageModal.vue";

export default {
  name: "PostForm",
  components: {Vue3TrixEditor},
  data() {
    return {
      model: starter.model,
      post: {
        id: null,
        title: '',
        description: '',
        author: '',
        category: '',
        content: '',
        published: false,
        featured: false,
        // published_at: '',
        author_slug: ''
      },
      service: new RestService('articles', '/'),
      timerId: null,
      contentReady: false,
      showImageModal: false,
      selectedImage: null
    }
  },
  computed: {
    currentPostContent() {
      return this.post.content
    }
  },
  mounted() {
    // document.addEventListener("trix-change", this.updatePostContent)
    // document.addEventListener("trix-focus", this.onFocus)
    // document.addEventListener("trix-blur", this.onFocusOut)

    if (this.$route.params.id) {
      let postId = this.$route.params.id
      this.service.get(postId).then((response) => {
        this.post = response
        this.contentReady = true
        // this.$refs.trix.innerHTML = this.post.content;
      }).catch((message) => {
        console.log('error loading post')
        console.log(message)
      })
    } else {
      this.contentReady = true
    }
  },
  beforeUnmount() {
    // document.removeEventListener("trix-change", this.updatePostContent)
    // document.removeEventListener("trix-focus", this.onFocus)
    // document.removeEventListener("trix-blur", this.onFocusOut)
  },
  methods: {

    // updatePostContent() {
    //   this.post.content = document.getElementById('x').value;
    // },
    onImageSelected(image) {
      console.log('onImageSelected')
      console.log(image)
      this.selectedImage = image
      this.post.featured_image_id = image.id
    },

    onFocus() {
      console.log('starting timer')
      this.timerId = setInterval(this.autoSave, 5000);
      console.log('timer id: ' + this.timerId)
    },
    onFocusOut() {
      if (this.timerId) {
        console.log('stopping timer')
        clearInterval(this.timerId)
      }

      this.timerId = null
      this.autoSave()
    },

    onSaveClick() {
      this.savePost().then((response) => {
        this.$router.push({name: 'posts'})
      }).catch((message) => {
        console.log('error saving post')
        console.log(message)
      })
    },

    autoSave() {
      this.savePost().then((response) => {
        this.post.id = response.id
      }).catch((message) => {
        console.log('error saving post')
        console.log(message)
      })
    },

    savePost() {
      let request = {
        article: this.post
      }

      let objectId = this.post.id
      return objectId === null ? this.service.create(request) : this.service.update(objectId, request)
    }
  }
}
</script>

<style scoped>

</style>
