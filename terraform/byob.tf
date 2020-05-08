## BYOB Okta Org configuration for:
#    Oauth2 SPA
#    Custom authorization server for SPA

# TF Variables
variable "org_name" {
}

variable "api_token" {
}

variable "base_url" {
  default = "okta.com" #"oktapreview.com" if using non-prod.
}

variable "app_url" {
}

variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
}

# Setup Okta Tenant
provider "okta" {
  org_name  = var.org_name
  api_token = var.api_token
  base_url  = var.base_url
  version   = "~> 3.0"
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = "~/.aws/creds"
  profile                 = var.aws_profile
}

# BYOB Users - Everyone 
resource "okta_group" "byob-users" {
  name = "Everyone"
}

# Create OAuth2 SPA App
resource "okta_app_oauth" "okta-byob" {
  label                      = local.app_name
  type                       = "browser"
  redirect_uris              = ["${var.app_url}/implicit/callback", "${var.app_url}/pkce/callback"]
  grant_types                = ["authorization_code"]
  response_types             = ["code"]
  token_endpoint_auth_method = "none"
  issuer_mode                = "ORG_URL"
}

# Create the App Assignment
resource "okta_app_group_assignment" "okta-byob" {
  app_id   = okta_app_oauth.okta-byob.id
  group_id = okta_group.byob-users.id
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

# Create policy in custom authorization server
resource "okta_auth_server_policy" "okta-byob" {
  auth_server_id   = okta_auth_server.okta-byob.id
  status           = "ACTIVE"
  name             = "okta-byob"
  description      = "okta-byob policy"
  priority         = 1
  client_whitelist = [okta_app_oauth.okta-byob.client_id]
}

# Create tokens claim in custom authorization server
resource "okta_auth_server_claim" "okta-byob-tenants-at" {
  auth_server_id = okta_auth_server.okta-byob.id
  name           = "tenants"
  value          = "appuser.tenants"
  value_type     = "EXPRESSION"

  ## Not Tied to Any scope
  #scopes         = [okta_auth_server_scope.okta-byob.name]
  claim_type = "RESOURCE"
}

resource "okta_auth_server_claim" "okta-byob-tenants-id" {
  auth_server_id = okta_auth_server.okta-byob.id
  name           = "tenants"
  value          = "appuser.tenants"
  value_type     = "EXPRESSION"

  ## Not Tied to Any scope
  #scopes         = [okta_auth_server_scope.okta-byob.name]
  claim_type = "IDENTITY"
}

resource "okta_auth_server_claim" "okta-byob-groups-at" {
  auth_server_id    = okta_auth_server.okta-byob.id
  name              = "groups"
  value             = ".*"
  value_type        = "GROUPS"
  group_filter_type = "REGEX"

  ## Not Tied to Any scope
  #scopes         = [okta_auth_server_scope.okta-byob.name]
  claim_type = "RESOURCE"
}

# resource "okta_auth_server_claim" "okta-byob-groups-id" {
#   auth_server_id    = okta_auth_server.okta-byob.id
#   name              = "groups"
#   value             = ".*"
#   value_type        = "GROUPS"
#   group_filter_type = "REGEX"

#   ## Not Tied to Any scope
#   #scopes         = [okta_auth_server_scope.okta-byob.name]
#   claim_type = "RESOURCE"
# }

# Create policy rule in custom authorization server
resource "okta_auth_server_policy_rule" "okta-byob" {
  auth_server_id                = okta_auth_server.okta-byob.id
  policy_id                     = okta_auth_server_policy.okta-byob.id
  status                        = "ACTIVE"
  name                          = "okta byob rule"
  priority                      = 1
  grant_type_whitelist          = ["authorization_code"]
  scope_whitelist               = ["*"]
  group_whitelist               = [okta_group.byob-users.id]
  access_token_lifetime_minutes = 60
}

resource "aws_ssm_parameter" "okta-api-token" {
  name        = "/okta/${var.environment}/api-token"
  description = "Okta API Token"
  type        = "SecureString"
  value       = var.api_token

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-client-id" {
  name        = "/okta/${var.environment}/client-id"
  description = "Okta App Client ID"
  type        = "String"
  value       = okta_app_oauth.okta-byob.client_id

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-issuer-uri" {
  name        = "/okta/${var.environment}/issuer-uri"
  description = "Okta Issuer URI"
  type        = "String"
  value       = "https://${var.org_name}.${var.base_url}/oauth2/${okta_auth_server.okta-byob.id}"

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-audience" {
  name        = "/okta/${var.environment}/audience"
  description = "Okta Audience"
  type        = "String"
  value       = "api://${local.app_name}"

  tags = {
    environment = var.environment
  }
}

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

# Local variables
locals {
  app_name = "byob-dashboard"
}

