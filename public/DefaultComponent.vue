<template>
  <div>
    DefaultComponent
  </div>
</template>

<script>
  export default {
    name: 'DefaultComponent',
    props: ['prop1', 'prop2'],
    data () {
      return {
        model: nimbleai.model
      }
    },
    mounted () {
    },
    methods: {
      importantMethodHere () {
      }
    }
  }
</script>
