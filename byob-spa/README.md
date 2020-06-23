
# Single Page Application (Local Installation)

## Prerequisites
* Install [vuecli](https://cli.vuejs.org/#getting-started)

   e.g. via npm:

   ```
   npm install @vue/cli -g
   ```

   Note: if you get WARN/ERR on MacOS, run:

   ```
   sudo npm install -g @vue/cli --unsafe-perm
   ```

## Make
1. Use the provided Makefile to generate the local env file using outputs from previous makes. From the `/byob-dashboard` (root) folder (that contains the Makefile), run
    ```
    make spa
    ```
    This generates the `.env.development.local` file in the `/byob-spa` folder and populates it with the necessary values.

2. Then, compile for development environment. `cd` into the `/byob-spa` folder and run
    ```
    npm run serve
    ```
3. Open your browser to `http://localhost:8081` and login

---

## Manual Setup
**If you prefer not to use the makefile, then follow these steps:**

1. `cd` into `/byob-spa`, then:
2. Run `npm install`
3. Create env file `.env.development.local` (In that same `/byob-spa` directory. Note: there is an existing `.env` file. Do not touch that file; Add this `.local` in addition to it). Edit it in with the values below:

   ```
   VUE_APP_CLIENT_ID={{client_id}}
   VUE_APP_ISSUER={{issuer_uri}}
   VUE_APP_API={{api_base_url}}
   VUE_APP_ADMIN_URL={{e.g. http://localhost:8080/login}}
   ```

   Where the above variables are:
   | Variable | Where to find |
   | --- |:------------- |
   | VUE_APP_CLIENT_ID | The `client_id` of the Okta App. In Okta, search for the app named `byob-dashboard` (that was provisioned by terraform) |
   | VUE_APP_ISSUER | The `issuer_uri` of the Auth Server. In Okta, search for the Authorization Server named `byob-dashboard` (that was provisioned by terraform) |
   | VUE_APP_API | The api base url of the API that was deployed |
   | VUE_APP_ADMIN_URL | The url of the [okta-dac](https://github.com/oktadeveloper/okta-dac) app, e.g. `http://localhost:8080/login` |

4. The following command compiles and hot-reloads for development environment
   ```
   npm run serve
   ```
5. Open your browser to `http://localhost:8081` and login

---

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

