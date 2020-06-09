"use strict";
const AuthPolicy = require('aws-auth-policy')
const OktaJwtVerifier = require('@okta/jwt-verifier')
const oktaJwtVerifier = new OktaJwtVerifier({
    issuer: process.env.ISSUER
});
exports.handler = function(event, context) {
    const accessTokenString = event.authorizationToken.split(' ')[1];
    oktaJwtVerifier.verifyAccessToken(accessTokenString, process.env.AUD)
    .then((jwt) => {
        var apiOptions = {};
        const arnParts = event.methodArn.split(':');
        const apiGatewayArnPart = arnParts[5].split('/');
        const awsAccountId = arnParts[4];
        apiOptions.region = arnParts[3];
        apiOptions.restApiId = apiGatewayArnPart[0];
        apiOptions.stage = apiGatewayArnPart[1];
        const policy = new AuthPolicy(jwt.claims.sub, awsAccountId, apiOptions);
        /*
         * Only the user (identified by the "uid" claim) can update themselves
         * We explicitly whitelist the http POST paths containing "uid" only
         */
        const uid = jwt.claims.uid;
        // allow update own profile
        policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid);
        // allow change own password
        policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/credentials/*');
        
        //allow factor list
        policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors');
        policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/factors');
        //allow factor catalog list
        policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors/catalog');
        //allow factor lifecycle operations
        policy.allowMethod(AuthPolicy.HttpVerb.POST, '/api/v1/users/' + uid + '/factors/**');
        policy.allowMethod(AuthPolicy.HttpVerb.DELETE, '/api/v1/users/' + uid + '/factors/*');
        //retrieve security question list
        policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/factors/questions');
        
        //retrieve a user's groups
        policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/users/' + uid + '/groups');
        
        //retrieve the policies
        policy.allowMethod(AuthPolicy.HttpVerb.GET, '/api/v1/policies/');
        
        var builtPolicy = policy.build();
        return context.succeed(builtPolicy);
    })
    .catch((err) => {
        console.log(err);
        return context.fail('Unauthorized');
    });
};