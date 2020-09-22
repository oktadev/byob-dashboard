# Proxy API calls to Okta
The Single Page App (SPA) would need to call Okta APIs (*For Example, to update the users' own profile/password or configure factors, see [Manage Okta resources by API](https://developer.okta.com/docs/reference/#manage-okta-resources) for more info*) but the Okta API endpoints are protected by API keys ([SSWS key](https://developer.okta.com/docs/reference/api-overview/#authentication)) that cannot be stored on the client side. However, the SPA has an **access_token** that can authenticate its *own apis*. So in order to securely call Okta endpoints, the SPA would call its own API (protected by the access_token), and then the API (a Lambda, *which can store secrets*) proxies calls to Okta with the SSWS key.

![alt text](../images/byob-demo-crud.gif)

---

## Prerequisites
* Install [Serverless](https://www.serverless.com/framework/docs/getting-started/)
    e.g. via npm:
    ```
    npm install -g serverless
    ```

## Serverless
Use the provided Makefile to deploy the api with serverless. From the `/byob-dashboard` (root) folder (that contains the Makefile), run
```
make api
```
Stop here. You are done deploying the API.

---

## Optional
If you prefer not to use the Makefile, follow these steps:

1. `cd` into the `byob-api` folder, then
2. Copy the file `.env.json.template` into `.env.json` (note there should be a leading `.`) and edit it with corresponding values from `/terraform/terraform.tfvars`:
    ```js
    {
        "AWS_PROFILE": "<aws_profile>",
        "AWS_REGION": "<aws_region>",
        "ENVIRONMENT": "<environment>",
        "AWS_SSM_PREFIX": "<aws_ssm_prefix>"
    }
    ```
3. Populate AWS SSM parameters: <a id="populate-aws-ssm-parameters"></a>
    * IF YOU DID RUN Terraform, SKIP THIS STEP.
    * If you did NOT not run Terraform, add the ssm parameters manually: From AWS console, navigate to **Systems Manager > Parameter Store**. Add the following parameters in your desired region:

    | parameter             | type         | value |
    | --------------------- | ------------ | ----- |
    | api-token             | SecureString | Follow [these steps](https://docs.idp.rocks/setup/#enable-programmatic-access-to-okta) to obtain an api token |
    | client-id             | String       | The client_id of the Okta App. In Okta, search for the app named `byob-dashboard` and copy-paste its *client_id* value |
    | issuer_uri            | String       | The `issuer_uri` of the Auth Server. In Okta, search for the Authorization Server named `byob-dashboard` and copy-paste its *Issuer URI* value |
    | audience              | String       | The `audience` of the Auth Server. In Okta, search for the Authorization Server named `byob-dashboard` and copy-paste its *Audience* value | 

    ---

    Terraform adds parameters in the AWS Systems Manager Parameter Store that are referenced in `serverless.yml`. So if you did not run Terraform, edit your `serverless.yml`:
    ```yml
    provider:
        name: aws
        runtime: nodejs12.x
        profile: ${self:custom.env.AWS_PROFILE} # <-- edit this
        region: ${self:custom.env.AWS_REGION}   # <-- edit this
        stage: ${self:custom.env.ENVIRONMENT}   # <-- edit this
        environment:
            ISSUER: ${ssm:/${self:custom.ssmPrefix}/okta/${self:provider.stage}/issuer-uri}           # <-- edit this
            AUDIENCE: ${ssm:/${self:custom.ssmPrefix}/okta/${self:provider.stage}/audience}           # <-- edit this
            OKTA_CLIENT_ID: ${ssm:/${self:custom.ssmPrefix}/okta/${self:provider.stage}/client-id}    # <-- edit this
            OKTA_API_KEY: ${ssm:/${self:custom.ssmPrefix}/okta/${self:provider.stage}/api-token~true} # <-- edit this
    ```

4. Run the serverless deploy command
    ```
    sls deploy
    ```
