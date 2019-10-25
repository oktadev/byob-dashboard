# This Lambda proxies calls to Okta API endpoints
The Single Page App (SPA) needs to call Okta APIs - *For Example, to update the users' profile, change password or reset factors, see [Manage Okta resources by API](https://developer.okta.com/docs/reference/#manage-okta-resources) for more info* - which are protected by API keys ([SSWS key](https://developer.okta.com/docs/reference/api-overview/#authentication)) that cannot be stored on the client side. The SPA however, has an **access_token** that can authenticate its *own apis*. This sample Lambda is essentially all the SPA needs and simply proxies api calls to Okta (securely) with the SSWS key

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
5. Resource Name = **api**, Resource Path = **/api**, Enable API Gateway CORS = **N**
6. Click **Create Resource**
7. Click **Actions**>**Create Resource** again
8. Resource Name = **v1**, Resource Path = **/v1**, Enable API Gateway CORS = **N**
9. Click **Create Resource**
10. Click **Actions**>**Create Resource** again
11. Select **Configure as proxy resource** and accept all the defaults (should say Resource Name = **proxy**, Resource Path = **/api/v1/{proxy+}**)
12. Set Enable API Gateway CORS = **Y**
13. Click **Create Resource**
14. On the next screen, select Integration type = **Lambda Function Proxy**
15. Lambda Function = **the lambda function created in "Step 2"**
16. Click **Save**
17. Click **Ok** when prompted about CORS

## Step 4. Add Lambda Authorizer to the proxy:
1. Select **Authorizers** in the left navigation pane
2. Click **Create New Authorizer**
3. Provide a name
4. Lambda Function = **the name of the lambda authorizer we created**
5. Lambda Event Payload = **Token** (this should be the default)
6. Token Source = **Authorization**
7. Token Validation = **^Bearer [-0-9a-zA-z\.]*$**
8. Click **Create**
9. Click **Resources** in the left navigation pane to go back to our API definition
10. Click into the pink **ANY** definition
11. Click into **Method Request**
12. Under Settings, change **Authorization = NONE** to **Authorization = (Authorizer that was just defined)**


