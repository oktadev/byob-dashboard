"use strict";

const axios = require("axios");
const qs = require("querystring");

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Credentials": true,
};

const AXIOS_CONFIG = {
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
    Authorization: "SSWS " + process.env.OKTA_API_KEY,
  },
};

async function createOktaUser(data) {
  delete data.recaptchaToken;

  let body = {
    profile: data,
  };

  console.log("Sending to Okta: " + JSON.stringify(body));

  return await axios.post(
    process.env.OKTA_ORG + "/api/v1/users?activate=true",
    JSON.stringify(body),
    AXIOS_CONFIG
  );
}

// async function lookupGroup(email) {
//   let domain = email.substring(
//     email.lastIndexOf("@") + 1,
//     email.lastIndexOf(".")
//   );

//   await axios.get(
//     process.env.OKTA_ORG + "/api/v1/groups?q=PENDING_" + domain,
//     JSON.stringify(body),
//     AXIOS_CONFIG
//   );
// }

module.exports.handler = async (event) => {
  console.log("Entering register function");
  const data = JSON.parse(event.body);
  console.log(event.body);

  try {
    var recaptchaRequest = {
      secret: process.env.RECAPTCHA_SITE_SECRET,
      response: data.recaptchaToken,
    };

    console.log(
      "Sending Recaptcha Request: " + JSON.stringify(recaptchaRequest)
    );
    let result = await axios.post(
      "https://www.google.com/recaptcha/api/siteverify",
      qs.stringify(recaptchaRequest)
    );

    if (result.data.success) {
      let result2 = await createOktaUser(data);
      console.log("Got result", result2.status);
      return {
        statusCode: result2.status,
        headers: CORS_HEADERS,
        body: JSON.stringify(result2.data),
      };
    } else {
      return {
        statusCode: result.status,
        headers: CORS_HEADERS,
        body: JSON.stringify(result.data),
      };
    }
  } catch (err) {
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: "Unknow Server Error: " + JSON.stringify(err),
    };
  }
};
