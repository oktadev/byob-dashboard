## BYOB Okta Org configuration for:
#    Oauth2 SPA
#    Custom authorization server for SPA

# Local variables
locals {
  app_name = "byob-dashboard"
}

# Required providers
terraform {
  required_providers {
    okta = {
      source  = "oktadeveloper/okta"
      version = "~> 3.0"
    }
  }  
}

# Setup Okta Tenant
provider "okta" {
  org_name  = var.org_name
  api_token = var.api_token
  base_url  = var.base_url
  version   = "~> 3.0"
}

# BYOB Users - Everyone 
data "okta_group" "byob-users" {
  name = "Everyone"
}

# Create OAuth2 SPA App
resource "okta_app_oauth" "okta-byob" {
  label                      = local.app_name
  type                       = "browser"
  redirect_uris              = ["${var.app_url}/oauth/callback"]
  post_logout_redirect_uris  = ["${var.app_url}/"]
  grant_types                = ["authorization_code"]
  response_types             = ["code"]
  token_endpoint_auth_method = "none"
  issuer_mode                = "ORG_URL"
  consent_method             = "TRUSTED"
}

# Create the App Assignment
resource "okta_app_group_assignment" "okta-byob" {
  app_id   = okta_app_oauth.okta-byob.id
  group_id = data.okta_group.byob-users.id
}

# Create Trusted Origin for the APP
resource "okta_trusted_origin" "okta-byob" {
  name   = "BYOB Dashboard"
  origin = var.app_url
  scopes = ["CORS", "REDIRECT"]
}

# Create Custom Authorization Server
resource "okta_auth_server" "okta-byob" {
  audiences   = ["api://${local.app_name}"]
  description = "Okta BYOB Authorization Server"
  name        = local.app_name
}

## Create scope in custom authorization server
# resource "okta_auth_server_scope" "okta-byob" {
#   auth_server_id   = okta_auth_server.okta-byob.id
#   metadata_publish = "ALL_CLIENTS"
#   name             = "read:okta-byob"
#   description      = "Read okta-byob"
#   consent          = "IMPLICIT"
# }

resource "okta_auth_server_claim" "okta-byob-groups-id" {
  auth_server_id    = okta_auth_server.okta-byob.id
  name              = "groups"
  value             = ".*"
  value_type        = "GROUPS"
  group_filter_type = "REGEX"
  claim_type        = "IDENTITY"
}

resource "okta_auth_server_claim" "okta-byob-mobile-phone" {
  auth_server_id    = okta_auth_server.okta-byob.id
  name              = "MobilePhone"
  value             = "user.mobilePhone"
  value_type        = "EXPRESSION"
  claim_type        = "IDENTITY"
}

# Create policy in custom authorization server
resource "okta_auth_server_policy" "okta-byob" {
  auth_server_id   = okta_auth_server.okta-byob.id
  status           = "ACTIVE"
  name             = "okta-byob"
  description      = "okta-byob policy"
  priority         = 1
  client_whitelist = [okta_app_oauth.okta-byob.client_id]
}

# Create policy rule in custom authorization server
resource "okta_auth_server_policy_rule" "okta-byob" {
  auth_server_id                = okta_auth_server.okta-byob.id
  policy_id                     = okta_auth_server_policy.okta-byob.id
  status                        = "ACTIVE"
  name                          = "okta byob rule"
  priority                      = 1
  grant_type_whitelist          = ["authorization_code"]
  scope_whitelist               = ["*"]
  group_whitelist               = [data.okta_group.byob-users.id]
  access_token_lifetime_minutes = 60
}

# Deprecate. email template is not supported by Provider oktadeveloper/okta 
# Change the welcome email template
// resource "okta_template_email" "email-welcome" {
//   type = "email.welcome"

//   translations {
//     language = "en"
//     subject  = "Welcome to BYOB"
//     template = "<div style=\"background-color:#fafafa;margin:0\"> \n  <table style=\"font-family:'proxima nova' , 'century gothic' , 'arial' , 'verdana' , sans-serif;font-size:14px;color:#5e5e5e;width:98%;max-width:600px;float:none;margin:0 auto\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" valign=\"top\" align=\"left\">\n    <tbody>\n      <tr bgcolor=\"#ffffff\">\n        <td> \n          <table bgcolor=\"#ffffff\" style=\"width:100%;line-height:20px;padding:32px;border:1px solid;border-color:#f0f0f0\" cellpadding=\"0\">\n            <tbody>\n              <tr>\n                <td style=\"padding-top:24px;vertical-align:bottom\"> Hi $${f:escapeHtml(user.firstName)}, </td>\n              </tr>\n              <tr>\n                <td style=\"padding-top:24px\"> <strong>Welcome to BYOB</strong> <br/> Click the following link to activate your account:</strong> </td>\n              </tr>\n              <tr>\n                <td align=\"center\" style=\"border:none;padding:25px 0 0 0\"> \n                  <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" valign=\"top\">\n                    <tbody>\n                      <tr>\n                        <td align=\"center\" style=\"display:inline-block;padding:10px;border:1px solid;text-align:center;cursor:pointer;color:#fff;border-radius:3px;background-color:#44bc98;border-color:#328c71 #328c71 #2f856b;box-shadow:#d8d8d8 0 1px 0\"> <a id=\"reset-password-link\" href=\"http://localhost:8081/activate/$${activationToken}\" style=\"text-decoration:none\"> <span style=\"font-size:13.5px;color:#fff\"> Activate Account </span> </a> </td>\n                      </tr>\n                      <tr>\n                        <td align=\"center\" style=\"color:#999\"> This link expires in $${f:formatTimeDiffHoursNowInUserLocale(org.activationTokenExpirationHours)}. </td>\n                      </tr>\n                    </tbody>\n                  </table> </td>\n              </tr>\n              <tr>\n                <td style=\"padding-top:24px\"> Your username is <strong>$${user.login}</strong></td>\n              </tr>\n            </tbody>\n          </table> </td>\n      </tr>\n      <tr>\n        <td style=\"font-size:12px;padding:16px 0 30px 50px;color:#999\"> This is an automatically generated message from <a href=\"http://www.okta.com\" style=\"color:rgb( 97 , 97 , 97 )\">Okta</a>. Replies are not monitored or answered. </td>\n      </tr>\n    </tbody>\n  </table> \n</div>"
//   }
// }

# Outputs
output "okta_app_oauth_client_id" {
  value = okta_app_oauth.okta-byob.client_id
}

output "okta_auth_server_id" {
  value = okta_auth_server.okta-byob.id
}

output "okta_auth_server_issuer_uri" {
  value = "https://${var.org_name}.${var.base_url}/oauth2/${okta_auth_server.okta-byob.id}"
}

