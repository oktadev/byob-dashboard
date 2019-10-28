const axios = require('axios');
const apiKey = process.env.OKTA_API_KEY;
const orgUrl = process.env.OKTA_ORG;

exports.handler = async function(event, context, callback) {
    const requestBody = JSON.parse(event.body);
    const requestUri = orgUrl + '/api/v1/users/' + event.pathParameters.proxy;

    const response = {
        isBase64Encoded: false,
        headers: {
            "Access-Control-Allow-Origin": "*"
        }
    };
    try {
        let res = await axios.post(requestUri, requestBody, {headers: {Authorization: 'SSWS ' + apiKey}});
        response.statusCode = res.status;
        response.body = JSON.stringify(res.data);
    } 
    catch(err) {
        response.statusCode = err.response.status;
        response.body = JSON.stringify(err.response.data);
    }
    callback(null, response);
}