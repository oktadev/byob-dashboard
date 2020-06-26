import Vue from "vue";
import Router from "vue-router";
import Auth from "@okta/okta-vue";
import Home from "@/views/Home.vue";
import Settings from "@/views/Settings.vue";
import LoginComponent from "@/components/Login";
import Activate from "@/components/Activate";
import config from "@/.config";

Vue.use(Router);

const router = new Router({
  mode: "history",
  base: process.env.BASE_URL,
  routes: [
    {
      path: "/",
      name: "home",
      component: Home,
      meta: {
        title: 'Home',
        requiresAuth: true
      },
    },
    {
      path: "/login",
      component: LoginComponent,
      meta: {
        title: 'Login'
      }
    },
    {
      path: "/oauth/callback",
      component: Auth.handleCallback(),
    },
    {
      path: "/settings",
      name: "settings",
      component: Settings,
      props: true,
      meta: {
        title: 'Settings',
        requiresAuth: true
      },
    },
    {
      path: "/activate/:token",
      name: "activate",
      component: Activate,
      meta: {
        title: "Activate",
      },
    }
  ],
});

config.oidc.redirect_uri =
  window.location.protocol +
  "//" +
  window.location.host +
  config.oidc.redirect_uri;

Vue.use(Auth, {
  issuer: config.oidc.issuer,
  client_id: config.oidc.client_id,
  redirect_uri: config.oidc.redirect_uri,
  scopes: config.oidc.scope.split(" "),
  pkce: true,
});

const onAuthRequired = async (from, to, next) => {
  document.title = config.brand.name;
  if (
    from.matched.some((record) => record.meta.requiresAuth) &&
    !(await Vue.prototype.$auth.isAuthenticated())
  ) {
    document.title = config.brand.name + " - " + "Sign In";
    if (config.loginRedirect) {
      Vue.prototype.$auth.loginRedirect("/");
    } else {
      next({ path: "/login" });
    }
  } else {
    document.title = config.brand.name + " - " + from.meta.title;
    next();
  }
};

router.beforeEach(onAuthRequired);

export default router;
