<template>
  <div class="fixed inset-0 z-50 bg-ink/40 transition-opacity">
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="flex min-h-full items-end justify-center p-4 sm:items-center">
        <div class="card max-w-lg w-full p-0 overflow-hidden text-left">
          <div class="px-6 pt-6 pb-5">
            <div class="flex items-start gap-4">
              <div
                class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
                :class="confirmStyle === 'danger' ? 'bg-red-100 text-red-600' : 'bg-primary/10 text-primary'"
              >
                <ExclamationTriangleIcon class="h-6 w-6" aria-hidden="true" />
              </div>
              <div class="min-w-0">
                <h3 class="font-display text-lg font-bold text-ink">{{ title }}</h3>
                <p class="mt-2 text-sm text-ink-muted">{{ message }}</p>
              </div>
            </div>
          </div>
          <div class="bg-surface-muted border-t border-line px-6 py-4 flex justify-end gap-3">
            <button type="button" class="btn-secondary" @click="$emit('cancel')">
              Cancel
            </button>
            <button
              type="button"
              :class="confirmStyle === 'danger' ? 'btn-danger' : 'btn-primary'"
              @click="$emit('confirm')"
            >
              {{ confirmText }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ExclamationTriangleIcon } from '@heroicons/vue/24/outline'

export default {
  name: 'ConfirmModal',
  components: {
    ExclamationTriangleIcon
  },
  props: {
    title: {
      type: String,
      required: true
    },
    message: {
      type: String,
      required: true
    },
    confirmText: {
      type: String,
      default: 'Confirm'
    },
    confirmStyle: {
      type: String,
      default: 'primary'
    }
  }
}
</script>
