<template>
    <div></div>
</template>
<script>
export default {
    name: 'o4o',
    data() {
        return {}
    },
    created() {
        // console.log('o4o created');
        const fragment = window.location.hash;
        // console.log('fragment=' + fragment);
        const token = fragment.split('&')[0].split('#access_token=')[1];
        console.log('access_token: ' + token);
        localStorage.setItem('o4o-token', token);
        // console.log('o4oAuthorizeUrl=' + this.$parent.$root.$children[0].o4oAuthorizeUrl);
    },
    methods: {

    }
}
</script>