# Sample Okta API Proxy Lambda

# Deployment

## Step 1. Build
1. Clone this repository and `cd` into `/api/byob-api-proxy-sample/`
2. `rm -rf node_modules/ && npm install --production`
3. `npm run zip` will create a source bundle and place it in the `/dist` folder. You will need this zip file in the next steps, below.

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


# Special processing
Though we are mostly proxying the api calls, additional handling can be added. We provide an example stripReadOnlyAttributes() function that reads the user [schema](https://developer.okta.com/docs/reference/api/schemas/#get-user-schema) to decide which profile attributes are read vs. read-write by the user. The function strips out and read-only attributes to make sure users don't overwrite admin protected information.