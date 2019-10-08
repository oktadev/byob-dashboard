# Bring Your Own Brand (byob)...
## ...to the Okta Chicklet Page

## Introduction

## Okta Org Setup
1. In your **Developer Console**, navigate to the **Applications** menu, click **Add Application** and select **Single-Page App**
2. Click **Next**, then enter an Application **Name**. Then:
   * Set Base URIs to `http://localhost:8080/` (it should already be set by default)
   * Leave the default setting `http://localhost:8080/implicit/callback` value in the list of *Redirect URIs*
   * Leave the default setting, Group assignments = **Everyone**
3. Click **Done** to redirect back to the *General* tab of your application.
4. Make note of the **Client ID**, as it will be needed environment configuration. 
5. Make sure that **Use PKCE (for public clients)** (underneath the Client Id) is selected

## Local Installation
1. Clone this repository and `cd` into the main directory
2. Run `npm install`
3. Create `src/.config.js` and edit it in with the values below:
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
4. The following command compiles and hot-reloads for development environment
`npm run serve`
5. Open your browser to `http://localhost:8080` and login

## Compile and minify for production
```
npm run build
```