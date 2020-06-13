"use strict";

const AuthPolicy = require("aws-auth-policy");
const OktaJwtVerifier = require("@okta/jwt-verifier");
const oktaJwtVerifier = new OktaJwtVerifier({
    issuer: process.env.ISSUER,
    clientId: process.env.OKTA_CLIENT_ID,
});

exports.auth = function (event, context) {
    if (!event.authorizationToken) {
        return context.fail("Unauthorized");
    }

    const accessTokenString = event.authorizationToken.split(" ")[1];
    oktaJwtVerifier
        .verifyAccessToken(accessTokenString, process.env.AUDIENCE)
        .then((jwt) => {
            let apiOptions = {};
            const arnParts = event.methodArn.split(':');
            const apiGatewayArnPart = arnParts[5].split('/');
            const awsAccountId = arnParts[4];
            apiOptions.region = arnParts[3];
            apiOptions.restApiId = apiGatewayArnPart[0];
            apiOptions.stage = apiGatewayArnPart[1];
            const policy = new AuthPolicy(jwt.claims.sub, awsAccountId, apiOptions);
            /*
             * Only the user (identified by the "uid" claim) can update themselves
             * We explicitly whitelist the paths containing "uid" only
             */
            const uid = jwt.claims.uid;
            policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid); // allow update own profile
            policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/credentials/*'); // allow change own password
            policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors'); // allow list own factors
            policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/factors'); // allow update own factods
            policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors/catalog'); // allow factor catalog list
            policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/factors/*'); // allow factor lifecycle operations
            policy.allowMethod(AuthPolicy.HttpVerb.DELETE, '/api/v1/users/' + uid + '/factors/*'); // allow factor lifecycle operations
            policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors/questions'); // retrieve security question list
            policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/groups'); // retrieve a user's groups

            policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/policies/'); // anyone can retrieve policies

            const builtPolicy = policy.build();
            // console.log(JSON.stringify(builtPolicy));
            console.log(builtPolicy.policyDocument.Statement);
            return context.succeed(builtPolicy);
        })
        .catch((err) => {
            console.log(err);
            return context.fail("Unauthorized");
        });
};