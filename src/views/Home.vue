<template>
  <div class="home">
    <Chicklets/>
  </div>
</template>

<script>
  import Chicklets from '@/components/Chicklets'

  export default {
    name: 'home',
    components: {
      Chicklets
    },
    data () {
        return {
            showApps: false,
            apps: null
        }
    },
    created() {
    },
    methods: {
    }
  }
</script>
