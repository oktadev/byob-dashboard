import Vue from 'vue'
import Router from 'vue-router'
import Auth from '@okta/okta-vue'
import Home from '@/views/Home.vue'
import Settings from '@/views/Settings.vue'
import LoginComponent from '@/components/Login'
import oktaAuthConfig from '@/.config.js'

Vue.use(Router)

const router = new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home,
      meta: {requiresAuth: true}
    },
    {
      path: '/login',
      component: LoginComponent
    },
    {
      path: '/implicit/callback',
      component: Auth.handleCallback()
    },
    {
      path: '/settings',
      name: 'settings',
      component: Settings,
      props: true,
      meta: {requiresAuth: true}
    },
    {
      path: '/settings/change-password',
      name: 'change-password',
      component: Settings,
      props: true,
      meta: {requiresAuth: true}
    }

  ]
})

oktaAuthConfig.oidc.redirect_uri = window.location.protocol + '//' + window.location.host + oktaAuthConfig.oidc.redirect_uri

Vue.use(Auth, {
  issuer: oktaAuthConfig.oidc.issuer,
  client_id: oktaAuthConfig.oidc.client_id,
  redirect_uri: oktaAuthConfig.oidc.redirect_uri,
  scopes: oktaAuthConfig.oidc.scope.split(' '),
  pkce: true
})

const onAuthRequired = async (from, to, next) => {
  if (from.matched.some(record => record.meta.requiresAuth) && !(await Vue.prototype.$auth.isAuthenticated())) {
    if (oktaAuthConfig.loginRedirect) {
      Vue.prototype.$auth.loginRedirect('/')
    } else {
      next({ path: '/login' })
    }
  } else {
    next()
  }
}

router.beforeEach(onAuthRequired)

export default router
