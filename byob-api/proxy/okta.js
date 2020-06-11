const axios = require("axios");
const apiKey = process.env.OKTA_API_KEY;
const orgUrl = process.env.ISSUER.split("/oauth2")[0];

exports.handler = async function(event, context, callback) {
    const response = {
        isBase64Encoded: false,
        headers: {
            "Access-Control-Allow-Origin": "*"
        }
    };

    const requestString = orgUrl + '/api/v1/' + event.pathParameters.proxy;
    
    let queryParams = null
    if(event.queryStringParameters){
        queryParams = event.queryStringParameters
    }
    
    let requestBody = null
    if(event.body){
        requestBody = JSON.parse(event.body);
        // IF updating user profile
        if (RegExp('^users/[0-9a-zA-Z]+$').test(event.pathParameters.proxy) && requestBody['profile']) {
            // Strip out "read only" profile attributes
            let profile = requestBody.profile
            await stripReadOnlyAttributes(orgUrl, apiKey, profile)
        }
    }
   
    try {
        let res = await axios({
            method: event.httpMethod,
            url: requestString,
            data: requestBody,
            params: queryParams,
            headers: {Authorization: 'SSWS ' + apiKey, 'Content-Type': 'application/json', 'Accept': 'application/json'}});
        response.statusCode = res.status;
        response.body = JSON.stringify(res.data);
    } 
    catch(err) {
        response.statusCode = err.response.status;
        response.body = JSON.stringify(err.response.data);
    }
    callback(null, response);
}


async function stripReadOnlyAttributes(orgUrl, apiKey, profile) {
  try {
    // see https://developer.okta.com/docs/reference/api/schemas/#get-user-schema
    const schema = await axios.get(
      orgUrl + "/api/v1/meta/schemas/user/default",
      { headers: { Authorization: "SSWS " + apiKey } }
    );
    const types = ["base", "custom"];
    types.forEach((type) => {
      const attributes = schema.data.definitions[type];
      if (attributes) {
        const properties = attributes.properties;
        Object.keys(properties).forEach((key) => {
          properties[key].permissions.forEach((perm) => {
            if (perm.principal == "SELF" && perm.action == "READ_ONLY") {
              delete profile[key];
            }
          });
        });
      }
    });
  } catch (err) {
    console.log(err);
  }
}
