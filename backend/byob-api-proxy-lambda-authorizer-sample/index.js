"use strict";
const AuthPolicy = require('aws-auth-policy')
const OktaJwtVerifier = require('@okta/jwt-verifier')

const oktaJwtVerifier = new OktaJwtVerifier({
    issuer: process.env.ISSUER,
    clientId: process.env.CLIENT_ID
});

exports.handler = function(event, context) {
    console.log(event)

    const accessTokenString = event.authorizationToken.split(' ')[1];

    oktaJwtVerifier.verifyAccessToken(accessTokenString, process.env.AUD)
    .then((jwt) => {
        var apiOptions = {};
        const arnParts = event.methodArn.split(':');
        
        const userId = arnParts[arnParts.length - 1].split('api/v1/users/')[1];
        console.log('uid=' + jwt.claims.uid);
        console.log('userId=' + userId);
        // Only allow operations against "self".
        // Assert that "uid" claim matches the {user_id} in the REST api request.
        if (userId != jwt.claims.uid) {
            return context.fail('Unauthorized');
        }
        
        const apiGatewayArnPart = arnParts[5].split('/');
        const awsAccountId = arnParts[4];
        apiOptions.region = arnParts[3];
        apiOptions.restApiId = apiGatewayArnPart[0];
        apiOptions.stage = apiGatewayArnPart[1];

        const policy = new AuthPolicy(jwt.claims.sub, awsAccountId, apiOptions);
        policy.allowAllMethods()
        var builtPolicy = policy.build();
        builtPolicy.context = {
            foo: 'bar'
        }

        return context.succeed(builtPolicy);
    })
    .catch((err) => {
        console.log(err);
        return context.fail('Unauthorized');
    });
};
