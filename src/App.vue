<template>
  <v-app>
    <v-app-bar app>
      <v-toolbar-title class="headline text-uppercase">
        <v-icon size="30px" color="primary">mdi-emoticon</v-icon>
        &nbsp;
        <span class="font-weight-light">Bring Your Own Brand</span>
      </v-toolbar-title>

      <v-spacer></v-spacer>

      <router-link
          tag='button' id='home-button'
          v-if="authenticated"
          to="/"
        >
        <v-btn text>Home</v-btn>
      </router-link>
      <router-link
          tag='button' id="login-button"
          to="/login"
          v-if="!loginRedirect && !authenticated"
        >
        <v-btn text>Login</v-btn>
      </router-link>
      <router-link
          tag='button' id="logout-button"
          to="/"
          v-if="authenticated"
          v-on:click.native="logout()"
        >
        <v-btn text>Logout</v-btn>
      </router-link>


    </v-app-bar>

    <v-content>    
      <router-view/>
    </v-content>
  </v-app>
</template>

<script>
import oktaAuthConfig from '@/.config.js'

export default {
  name: 'App',
  data () {
    return {
      loginRedirect: false,
      authenticated: false
    }
  },
  created () { this.appInit() },
  watch: {
    // Everytime the route changes, check for auth status
    '$route': 'isAuthenticated'
  },
  methods: {
    appInit() {
      this.loginRedirect = oktaAuthConfig.loginRedirect
      this.isAuthenticated()
    },
    async isAuthenticated () {
      if (this.$auth) {
        this.authenticated = await this.$auth.isAuthenticated()
      }
    },
    async logout () {
      await this.$auth.logout()
      await this.isAuthenticated()
      window.location.href="/"
    }
  }
}
</script>