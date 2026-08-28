<template>
  <div id="richTextEditorForm" class="richText">
    <input :id="textId" type="hidden" :value="dataObject[fieldName]">
    <trix-editor
      :input="textId"
      class="trix-content max-w-5xl min-h-[300px] rounded-xl border border-line bg-surface px-4 py-2.5 text-ink focus:border-primary focus:outline-none"
    ></trix-editor>
  </div>
</template>

<script>

import RestService from "../services/RestService";

export default {
  name: 'Vue3TrixEditor',
  props: ['dataObject', 'fieldName', 'textId'],
  mounted() {
    document.addEventListener("trix-change", this.updateRichText)
    document.addEventListener("trix-focus", this.onFocus)
    document.addEventListener("trix-blur", this.onFocusOut)
    document.addEventListener("trix-attachment-add", this.attachmentAdded)
    document.addEventListener("trix-attachment-remove", this.attachmentRemoved)
  },
  beforeUnmount() {
    document.removeEventListener("trix-change", this.updateRichText)
    document.removeEventListener("trix-focus", this.onFocus)
    document.removeEventListener("trix-blur", this.onFocusOut)
    document.removeEventListener("trix-attachment-add", this.attachmentAdded)
    document.removeEventListener("trix-attachment-remove", this.attachmentRemoved)
  },
  data() {
    return {
      service: new RestService('images')
    }
  },
  methods: {
    updateRichText(e) {
      this.dataObject[this.fieldName] = document.getElementById(this.textId).value;
    },
    onFocus() {
      this.$emit('onFocus');
    },
    onFocusOut() {
      this.$emit('onFocusOut');
    },
    attachmentAdded(event) {
      if (event.attachment.file) {
        this.uploadFileAttachment(event.attachment)
      }
    },
    attachmentRemoved(event) {
      try {
        let imageId = event.attachment.attachment.attributes.values.image_id

        if(imageId) {
          console.log('Removing image')
          this.service.remove(imageId)
        }

      } catch (exception) {
        console.log('Error removing image')
        console.log(exception)
      }
    },
    uploadFileAttachment(attachment) {
      this.uploadFile(attachment.file, setProgress, setAttributes)

      function setProgress(progress) {
        attachment.setUploadProgress(progress)
      }

      function setAttributes(attributes) {
        attachment.setAttributes(attributes)
      }
    },

    uploadFile(file, progressCallback, successCallback) {
      let formData = this.createFormData(file)
      let xhr = new XMLHttpRequest()
      xhr.open("POST", '/images.json', true)
      xhr.setRequestHeader("X-CSRF-Token", Rails.csrfToken())

      xhr.upload.addEventListener("progress", function (event) {
        let progress = event.loaded / event.total * 100
        progressCallback(progress)
      })

      xhr.addEventListener("load", function (event) {
        if (xhr.status == 201) {
          let response = JSON.parse(xhr.responseText);
          console.log('Attachment created')
          console.log(response)

          let attributes = {
            url: response.url,
            href: response.url,
            image_id: response.id
          }
          successCallback(attributes)
        }
      })

      xhr.send(formData)
    },

    createFormData(file) {
      let data = new FormData()
      data.append("image[name]", file.name.substring(0, file.name.lastIndexOf('.')))
      data.append("image[metadata]", {fileType: file.type })
      data.append("image[source]", 'Upload')
      data.append("image[image]", file)
      data.append("Content-Type", file.type)
      return data
    }
  }
}
</script>