# BYOB
**B**ring **Y**our **O**wn **B**rand...to the Okta Chicklet Page

## Introduction
![alt text](images/byob-demo.gif)

If you've ever considered building your own User HomePage (aka the "Chicklet Page") – in order to have 100% control of the branding – and want some sample code to get started, you've found the right repo!

This project is built in Vue.js 3.11.0, and uses
* [Vuetify 2.x](https://vuetifyjs.com/en/)
* [Vuedraggable](https://github.com/SortableJS/Vue.Draggable)
* [Okta Vue.js SDK](https://github.com/okta/okta-oidc-js/tree/master/packages/okta-vue)
* [Okta Sign-in Widget 3.x](https://github.com/okta/okta-signin-widget)


## Okta Org Setup
This application is represented by an OpenID Connect application in Okta, so we need to configure one:
1. In your **Developer Console**, navigate to the **Applications** menu, click **Add Application** and select **Single-Page App**
2. Click **Next**, then enter an Application **Name**. Then:
   * Set Base URIs to `http://localhost:8080/` (it should already be set by default)
   * Leave the default setting `http://localhost:8080/implicit/callback` value in the list of *Redirect URIs*
   * Leave the default setting, Group assignments = **Everyone**
3. Click **Done** to redirect back to the *General* tab of your application.
4. Make note of the **Client ID**, as it will be needed environment configuration. 
5. Make sure that **Use PKCE (for public clients)** (underneath the Client Id) is selected
6. Navigate to **Api** > **Trusted Origins** and add `http://localhost:8080` as a type = **CORS** entry.

## Local Installation
1. Clone this repository and `cd` into the main directory
2. Run `npm install`
3. Run `npm install @vue/cli -g`
4. Create `src/.config.js` and edit it in with the values below:
```
export default {
    oidc: {
        client_id: {{Your Client ID from the "Okta Org Setup" setup}},
        issuer: 'https://{{Your Okta Org Url}}/oauth2/default',
        redirect_uri: '/implicit/callback',
        scope: 'openid profile email',
    }
};
```
    * Note the `.` in front of the filename. This is simply for convention
5. The following command compiles and hot-reloads for development environment
`npm run serve`
6. Open your browser to `http://localhost:8080` and login

## Compile and minify for production
```
npm run build
```