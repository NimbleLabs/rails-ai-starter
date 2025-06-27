<template>
    <div>
        <div class="modal fade" id="defaultModal" tabindex="-1" role="dialog" aria-labelledby="fontModalLabel"
             aria-hidden="true">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="flex border-b border-zinc-100 pl-4 pt-4 pb-2">
                        <div class="flex flex-row items-center">
                            <div class="flex justify-center items-center bg-purple-100 h-8 w-8 rounded-full">
                                <PlusIcon class="h-5 w-5 text-primary" aria-hidden="true" />
                            </div>

                            <h5 class="ml-2 text-lg font-medium tracking-tight text-slate-600">
                                Modal Title
                            </h5>
                        </div>
                        <button type="button" class="btn-close" @click="noHandler" aria-label="Close"></button>
                    </div>

                    <div class="modal-body px-10 pb-5 text-slate-500">

                        <h2>Hello World</h2>

                    </div>
                    <div class="border-t border-zinc-200 bg-zinc-50 rounded-b-xl flex justify-end py-5 pr-5 space-x-4">
                        <button type="button"
                                class="w-32 bg-purple-600 hover:bg-purple-800 text-white px-8 py-1 rounded"
                                @click="yesHandler">Ok
                        </button>
                        <button type="button"
                                class="w-32 bg-white hover:bg-gray-100 border border-gray-300 text-slate-800 px-8 py-1 rounded"
                                @click="noHandler">Cancel
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>

import RestService from "@/app/services/RestService.js";
import {PlusIcon} from "@heroicons/vue/24/outline/index.js";

export default {
    name: 'DefaultModal',
    props: {
        yesEvent: Function
    },
    data() {
        return {
            model: nimbleai.model,
            currentModal: null,
            modalElement: null,
        }
    },
    mounted() {
        this.modalElement = document.getElementById('defaultModal')
        this.currentModal = new bootstrap.Modal(this.modalElement)
        this.modalElement.addEventListener('hidden.bs.modal', this.onModalHidden)
        this.currentModal.show()
    },
    beforeUnmount() {
        this.modalElement.removeEventListener('hidden.bs.modal', this.onModalHidden)
    },
    methods: {
        onModalHidden() {
            this.$emit('noEvent')
        },
        noHandler(e) {
            this.currentModal.hide()
        },
        yesHandler(e) {
            // call the parent's "yesEvent"
            if (this.yesEvent) {
                this.yesEvent()
            }

            // hide the modal
            this.noHandler()
        }
    }
}
</script>
