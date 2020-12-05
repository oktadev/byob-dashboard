ℹ️ Disclaimer: This project serves as a Sample Application, that you can tweak or completely repurpose. It is community-supported and is maintained by members of the Okta team for developers and other IT professionals. BYOB-dashboard is not an official Okta product and does not qualify for any Okta support. Okta makes no warranties regarding this project. Anyone who chooses to use this project must ensure that their implementation meets any applicable legal obligations including any Okta terms and conditions.

ℹ️ It is recommended that you collaborate with your preferred Okta Solution Provider [(link)](https://www.okta.com/partners/meet-our-partners/) to implement and adapt this app code sample within your existing portal. This app features frontend and backend components and like any web app hosted and running on your side, you should perform a code review, as well as security and scalability tests.

# BYOB Dashboard

**B**ring **Y**our **O**wn **B**rand...to the Okta Chicklet Page

## Introduction

![alt text](images/byob-demo.gif)

If you've ever considered building your own User HomePage (aka the "Chicklet Page") – in order to have 100% control of the branding – and want some sample code to get started, you've found the right repo!

* The SPA is built in Vue.js and uses
    - [Vuetify 2.x](https://vuetifyjs.com/en/) Material Design Component Framework
    - [Vuedraggable](https://github.com/SortableJS/Vue.Draggable) Vue drag-and-drop component based on Sortable.js
    - [Okta Vue.js SDK 2.0.x](https://github.com/okta/okta-oidc-js/tree/master/packages/okta-vue)
    - [Okta Sign-in Widget 4.1.x](https://github.com/okta/okta-signin-widget)
* The API is developed using [Serverless](https://www.serverless.com/) framework

## Setup

Setting up the required configurations in Okta; the API Gateway and lambda functions (in AWS, for the [REST APIs](/byob-api)) are quite involved. So we've leveraged [Terraform](https://www.terraform.io/) and [Serverless](https://www.serverless.com), and provided a Makefile:

### Prerequisites

1. **macOS Catalina issues:** You must be able to run `npm install`.

   - The Makefiles runs `npm install` commands. You should make sure that your machine is able to run this command without any issues.
   - If you are getting the error _"gyp: No Xcode or CLT version detected!"_ on macOS Catalina, [follow these steps](https://medium.com/flawless-app-stories/gyp-no-xcode-or-clt-version-detected-macos-catalina-anansewaa-38b536389e8d)

2. Install [terraform v0.13.0 or above](https://learn.hashicorp.com/terraform/getting-started/install)
   * The terraform files uses v0.13 syntax. If you have an older version of terraform, you need to upgrade. If you can't upgrade, skip terraform and do these manual steps:
   1. [Follow the manual steps to configure Okta](terraform#manually-configure-okta).
   2. [Populate AWS SSM parameters](byob-api#populate-aws-ssm-parameters)
3. Install [Serverless v1.1.0 or above](https://www.serverless.com/framework/docs/getting-started/)

   e.g. via npm:

   cd to the /byob-dashboard folder and run:

   ```
   npm install -g serverless
   ```

   Note: if you get WARN/ERR on MacOS, run:

   ```
   sudo npm install -g serverless
   ```

4. Install [vuecli](https://cli.vuejs.org/#getting-started)

   e.g. via npm:

   ```
   npm install @vue/cli -g
   ```

   Note: if you get WARN/ERR on MacOS, run:

   ```
   sudo npm install -g @vue/cli --unsafe-perm
   ```

5. Create a Named Profile in AWS. [Steps](https://docs.idp.rocks/setup/#create-named-profile-in-aws-cli)
6. Enable Programmatic Access for Okta. [Steps](https://docs.idp.rocks/setup/#enable-programmatic-access-to-okta)

### Environment Variables

- Copy the file `/terraform/terraform.tfvars.template` into `/terraform/terraform.tfvars` and edit it with your Org variables:

  ```
  org_name       = "<org subdomain>"
  base_url       = "<oktapreview.com || okta.com>"
  api_token      = "<OKTA_API_TOKEN>"
  app_url        = "http://localhost:8081"
  environment    = "dev"
  aws_region     = "us-east-1"
  aws_profile    = "(see Prerequisites Step 5.)"
  aws_ssm_prefix = "byob"
  ```

  Where the above variables are: <a name="variable-names"></a>

  | Variable       | Description                                                                | Default Value           |
  | -------------- | :------------------------------------------------------------------------- | ----------------------- |
  | org_name       | Okta Org subdomain name (e.g. "atko")                                      |                         |
  | base_url       | Base URL for the Okta org (okta.com or oktapreview.com)                    | "okta.com"              |
  | api_token      | OKTA_API_TOKEN, per [Prerequisites Step 6.](#prerequisites)                |                         |
  | app_url        | Base URL for the SPA.                                                      | "http://localhost:8081" |
  | environment    | Stage configured in API Gateway (dev, prod, ...)                           | "dev"                   |
  | aws_region     | Region to deploy AWS components.                                           | "us-east-1"             |
  | aws_profile    | Profile configured in AWS CLI. per [Prerequisites Step 5.](#prerequisites) |                         |
  | aws_ssm_prefix | Prefix for parameters created in AWS Parameter Store.                      | "byob"                  |

---

## Make

Once `/terraform/terraform.tfvars` is populated correctly, cd to the /byob-dashboard folder and run:

```
make check
```

This will check if the pre-requisites and print out the version numbers installed on your machine.

On a Mac, this is a sample output:

```
$ make check
Found Terraform v0.12.26
Found Serverless: Framework Core: 1.72.0 Plugin: 3.6.13 SDK: 2.3.1 Components: 2.30.12
Found aws-cli/2.0.8 Python/3.7.4 Darwin/19.4.0 botocore/2.0.0dev12
Found @vue/cli 4.3.1
```

If you dont see any error messages, you can run `make all`.

```
make all
```

The above will:

1. Run the provided Terraform scripts to configure your Okta Org
2. Deploy the API using Serverless
3. Create the local env file (`.env.development.local`) for the SPA

If you didn't see any errors during `make`, you're ready to go:


## (Required) Manual Step
Terraform currently does not support updating email templates so you have to do the following manually to get the welcome email to be redirect to the user activation path of the locally running app: `localhost:8081/activate`. Follow step 8 [here](terraform#activation-email-template).


## Run
`cd` into the `byob-dashboard` folder and run
```
npm run serve
```
Then, open your browser to `http://localhost:8081` and login

---

## Step-by-step Options

If you would rather do things step by step, do not run `make all`. Deploying this project has 3 parts:

1. Run the provided Terraform scripts. Click [here](terraform#okta-setup) for next steps.
2. Deploy the API. Click [here](byob-api#serverless) for next steps.
3. Bring up the spa on localhost. Click [here](byob-spa#make) for next steps.
