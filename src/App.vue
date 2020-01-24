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
        <!-- <router-link
            tag='button' id='home-button'
            v-if="authenticated"
            to="/"
          > -->
          <v-btn text @click="home">
            <v-icon left dark>mdi-home</v-icon>
            Home
          </v-btn>
        <!-- </router-link> -->

        <ProfileButton
          v-bind:userinfo="userinfo"
          >
        </ProfileButton>
        <v-btn text outlined
            @click="o4o"
            >
            O4o
        </v-btn>
      </div>
    </v-app-bar>
    <div>
        <iframe
            width="100%"
            height="0"
            :src="o4oAuthorizeUrl"
            frameborder="0"
        ></iframe>
    </div>

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
      userinfo: undefined,
      key: 0,
      o4oAuthorizeUrl: undefined,
      o4oToken: undefined
    }
  },
  components: {
      ProfileButton
  },
  created () {
    this.appInit()
  },
  watch: {
    // Everytime the route changes, check for auth status
    '$route': 'isAuthenticated'
  },
  methods: {
    appInit() {
      if (oktaAuthConfig.loginRedirect)
        this.loginRedirect = oktaAuthConfig.loginRedirect 
      this.isAuthenticated()
    },
    async isAuthenticated () {
      this.authenticated = await this.$auth.isAuthenticated()

      if (!this.userinfo) {
        // hacky-hack. Since we're directly updating userinfo. Do not fetch new data because there may be a race-condition and data from Okta could lag the UI
        this.userinfo = await this.$auth.getUser()
      }
    },
    home() {
      this.$router.push({
          name: 'home',
      })
    },
    o4o() {
        let url = oktaAuthConfig.oidc.issuer.split('oauth2')[0] + '/oauth2/v1/authorize?client_id=' + oktaAuthConfig.oidc.client_id
            + '&&response_type=token&response_mode=fragment&scope=okta.users.manage.self&redirect_uri=http://localhost:8080/o4o/callback&state=foo&nonce=foo'
        this.o4oAuthorizeUrl = url;
    }
  }
}
</script>