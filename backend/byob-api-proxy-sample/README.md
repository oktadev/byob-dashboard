# Proxy API calls to Okta
The Single Page App (SPA) needs to call Okta APIs (*For Example, to update the users' own profile/password or configure factors, see [Manage Okta resources by API](https://developer.okta.com/docs/reference/#manage-okta-resources) for more info*). However, the Okta API endpoints are protected by API keys ([SSWS key](https://developer.okta.com/docs/reference/api-overview/#authentication)) that cannot be stored on the client side. The SPA has an **access_token** that can authenticate its *own apis*. In order to securely call the Okta endpoints, the SPA calls its own API (protected by the SPA's access_token), and the SPA's API (for example, a Lambda, which can store secrets) then proxies api calls to Okta (securely) with the SSWS key.

# Deployment

## Step 1. Build
1. Clone this repository and `cd` into `backend/byob-api-proxy-sample/`
2. `rm -rf node_modules/ && npm install --production`
3. `npm run zip` will create a source bundle and place it in the `\dist` folder. You will need this zip file in the next steps, below.

## Step 2. Create Lambda function using the AWS Lambda Console/UI
1. Click **Create Function**
2. Select **Author from scratch**
3. Provide a value for **Function name**
4. Runtime = **Node.js 10.x**
5. Click **Create Function** (This will automatically create an AMI role. But you can also select an existing one with the correct permissions if you have one)
6. In the **Code entry type** field, select **Upload a .zip file** and upload the previously generated zip file
7. Add **Environment variables**:

| NAME | VALUE |
| ---- | ----- |
|OKTA_API_KEY|[An *SSWS* key](https://developer.okta.com/docs/reference/api-overview/#authentication) to authenticate Okta API calls|
|OKTA_ORG|Your *"okta org url"* (e.g. `https://acme.okta.com`)|

## Step 3. Create a proxy endpoint (to the Okta API) using Amazon API Gateway:
1. From the Amazon API Gateway Console/UI, click **Create API**
2. Accept all defaults, and provide a name for **API name**
3. Click **Create API**
4. On the next screen, click **Actions**>**Create Resource**
* Resource Name = **api**
* Resource Path = **/api**
* Enable API Gateway CORS = **N**
* Click **Create Resource**
5. Click **Actions**>**Create Resource** again
* Resource Name = **v1**
* Resource Path = **/v1** 
* Enable API Gateway CORS = **N**
* Click **Create Resource**
6. Click **Actions**>**Create Resource** again
* Select **Configure as proxy resource**
* Accept all the defaults *(you should see Resource Name = **proxy**, Resource Path = **/api/v1/{proxy+}**)*
* Set *Enable API Gateway CORS* = **Y**
* Click **Create Resource**
7. In the next screen
* Select *Integration type* = **Lambda Function Proxy**
* Lambda Function = *name of the lambda function from "Step 2"*
* Click **Save**
* Click **Ok** when prompted about CORS

## Step 4. Add Lambda Authorizer to the proxy:
1. Select **Authorizers** in the left navigation pane
2. Click **Create New Authorizer**, then configure with these values:
* Lambda Function = *name of the lambda function from [byob-api-proxy-lambda-authorizer-sample](../byob-api-proxy-lambda-authorizer-sample)*
* Lambda Event Payload = **Token** (is defaulted for you)
* Token Source = **Authorization**
* Token Validation = **^Bearer [-0-9a-zA-z\.]*$**
* Click **Create**
3. Click **Resources** in the left navigation pane *(to return to our API definition)*
4. Click into the (pink) **ANY** definition
5. Click into **Method Request**
6. Under Settings, change **Authorization = NONE** to **Authorization = (Authorizer that was just defined)**


