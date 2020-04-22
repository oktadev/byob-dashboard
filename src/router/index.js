import Vue from 'vue'
import Router from 'vue-router'
import Auth from '@okta/okta-vue'
import Home from '@/views/Home.vue'
import Settings from '@/views/Settings.vue'
import LoginComponent from '@/components/Login'
import config from '@/.config'

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
    }
  ]
})

config.oidc.redirect_uri = window.location.protocol + '//' + window.location.host + config.oidc.redirect_uri

Vue.use(Auth, {
  issuer: config.oidc.issuer,
  client_id: config.oidc.client_id,
  redirect_uri: config.oidc.redirect_uri,
  scopes: config.oidc.scope.split(' '),
  pkce: true
})

const onAuthRequired = async (from, to, next) => {
  if (from.matched.some(record => record.meta.requiresAuth) && !(await Vue.prototype.$auth.isAuthenticated())) {
    if (config.loginRedirect) {
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
