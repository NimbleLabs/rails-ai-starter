<template>
  <div class="p-10">
    <h1 class="font-extrabold text-4xl md:text-5xl tracking-tight">PostForm</h1>

    <div class="my-3">
      <button class="w-32 bg-purple-600 hover:bg-purple-800 text-white px-8 py-1 rounded"
              @click.prevent="onSaveClick">Save
      </button>
      <router-link :to="{ name: 'posts' }"
                   class="ml-5 w-32 bg-white hover:bg-gray-100 border border-gray-300 text-slate-800 px-8 py-1 rounded">
        Cancel
      </router-link>
    </div>

    <div class="pb-10">
      <div class="my-2">
        <label for="titleInput" class="text-sm font-medium">Title</label>
        <input type="text" class="input-form-field" id="titleInput" v-model="post.title">
      </div>
      <div class="my-2">
        <label for="descriptionInput" class="text-sm font-medium">Description</label>
        <input type="text" class="input-form-field" id="descriptionInput"
               v-model="post.description">
      </div>
      <div class="my-2">
        <label for="authorInput" class="text-sm font-medium">Author</label>
        <input type="text" class="input-form-field" id="authorInput" v-model="post.author">
      </div>

      <div class="my-2">
        <label for="categoryInput" class="text-sm font-medium">Category</label>

        <select
            class="input-form-field"
            v-model="post.category">
          <option v-for="category in model.categories" :value="category">{{ category }}</option>
        </select>
      </div>

      <div class="my-2">
        <label class="inline-flex items-center">
          <input type="checkbox" v-model="post.published" class="rounded border-gray-300 text-indigo-600 shadow-sm
                          focus:border-indigo-300 focus:ring focus:ring-offset-0 focus:ring-indigo-200 focus:ring-opacity-50">
          <span class="ml-2">Published</span>
        </label>
      </div>

      <div class="my-2">
        <label class="inline-flex items-center">
          <input type="checkbox" v-model="post.featured" class="rounded border-gray-300 text-indigo-600 shadow-sm
                          focus:border-indigo-300 focus:ring focus:ring-offset-0 focus:ring-indigo-200 focus:ring-opacity-50">
          <span class="ml-2">Featured</span>
        </label>
      </div>

      <div v-if="contentReady" class="my-2">
        <label for="contentInput" class="text-sm font-medium">Content</label>
        <vue3-trix-editor :data-object="post" field-name="content" text-id="articleContentEditor"
                          @onFocus="onFocus" @onFocusOut="onFocusOut"></vue3-trix-editor>
      </div>

      <div class="my-2">
        <div for="featuredInput" class="text-sm font-medium">Featured Image</div>
        <button class="bg-purple-500 text-white px-4 py-1 rounded-lg" @click="showImageModal = true">Select Image
        </button>

        <div v-if="selectedImage" class="my-2">
          <img class="w-96" :src="selectedImage.url">
        </div>
      </div>
      <!--      <div class="my-2">-->
      <!--        <label for="publishedAtInput" class="text-sm font-medium">Published at</label>-->
      <!--        <input type="text" class="border-gray-200 rounded py-2 w-full mb-3" id="published_atInput"-->
      <!--               v-model="post.published_at">-->
      <!--      </div>-->

      <div class="mb-3">
        <button class="w-32 bg-purple-600 hover:bg-purple-800 text-white px-8 py-1 rounded"
                @click.prevent="onSaveClick">Save
        </button>
        <router-link :to="{ name: 'posts' }"
                     class="ml-5 w-32 bg-white hover:bg-gray-100 border border-gray-300 text-slate-800 px-8 py-1 rounded">
          Cancel
        </router-link>
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
        post: this.post
      }

      let objectId = this.post.id
      return objectId === null ? this.service.create(request) : this.service.update(objectId, request)
    }
  }
}
</script>

<style scoped>

</style>
