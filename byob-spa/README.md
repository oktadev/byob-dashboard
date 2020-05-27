# Options
## 1. Alternative Login Flow
To see an example of logging in via redirect to the Okta hosted Signin page *(instead of the Signin Widget)*, add `loginRedirect` to the `.config.js` file.
The resulting file should look like this:
```
export default {
    org: process.env.VUE_APP_ISSUER.split("/oauth2")[0],
    oidc: {
      client_id: process.env.VUE_APP_CLIENT_ID,
      issuer: process.env.VUE_APP_ISSUER,
      redirect_uri: process.env.VUE_APP_REDIRECT_URI,
      scope: process.env.VUE_APP_SCOPES
    },
    api: process.env.VUE_APP_API,
    brand: {
      logo: process.env.VUE_APP_LOGO,
      logo_inv: process.env.VUE_APP_LOGO_INVERSE,
      color: process.env.VUE_APP_MAINCOLOR,
      name: process.env.VUE_APP_COMPANY_NAME,
      recaptcha_key: process.env.VUE_APP_RECAPTCHA_SITE_KEY
    },
    loginRedirect: true
}
```

## 2. Overriding the Icons uploaded into Okta
Sometimes it is useful to override the App icons that were uploaded into Okta with higher resolution images. To do this, edit the `/byob-spa/src/assets/icons.js` file with a list of objects containing the appId and the associated logo URL. 

