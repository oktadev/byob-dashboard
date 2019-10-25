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
          tag='button' id="login-button"
          to="/login"
          v-if="!loginRedirect && !authenticated"
        >
        <v-btn text>Login</v-btn>
      </router-link>
      <div v-if="authenticated">
        <router-link
            tag='button' id='home-button'
            v-if="authenticated"
            to="/"
          >
          <v-btn text>
            <v-icon left dark>mdi-home</v-icon>
            Home
          </v-btn>
        </router-link>

        <ProfileButton
          v-bind:userinfo="userinfo"
          >
        </ProfileButton>
      </div>
    </v-app-bar>

    <v-content>    
      <router-view/>
    </v-content>
  </v-app>
</template>

<script>
import oktaAuthConfig from '@/.config.js'
import ProfileButton from '@/components/ProfileButton'

export default {
  name: 'App',
  data () {
    return {
      loginRedirect: false,
      authenticated: false,
      userinfo: {},
      key: 0
    }
  },
  components: {
      ProfileButton
  },
  created () { this.appInit() },
  watch: {
    // Everytime the route changes, check for auth status
    '$route': 'isAuthenticated'
  },
  methods: {
    async appInit() {
      this.loginRedirect = oktaAuthConfig.loginRedirect
      this.isAuthenticated()
    },
    async isAuthenticated () {
      if (this.$auth) {
        this.authenticated = await this.$auth.isAuthenticated()
        this.userinfo = await this.$auth.getUser()
      }
    }
  }
}
</script>