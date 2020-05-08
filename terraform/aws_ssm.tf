provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = "~/.aws/creds"
  profile                 = var.aws_profile
}

resource "aws_ssm_parameter" "okta-api-token" {
  name        = "/${var.aws_ssm_prefix}/okta/${var.environment}/api-token"
  description = "Okta API Token"
  type        = "SecureString"
  value       = var.api_token

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "recaptcha-site-secret" {
  name        = "/${var.aws_ssm_prefix}/okta/${var.environment}/recaptcha-site-secret"
  description = "Google Recaptcha Site Secret"
  type        = "SecureString"
  value       = var.recaptcha_site_secret

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-client-id" {
  name        = "/${var.aws_ssm_prefix}/okta/${var.environment}/client-id"
  description = "Okta App Client ID"
  type        = "String"
  value       = okta_app_oauth.okta-byob.client_id

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-issuer-uri" {
  name        = "/${var.aws_ssm_prefix}/okta/${var.environment}/issuer-uri"
  description = "Okta Issuer URI"
  type        = "String"
  value       = "https://${var.org_name}.${var.base_url}/oauth2/${okta_auth_server.okta-byob.id}"

  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "okta-audience" {
  name        = "/${var.aws_ssm_prefix}/okta/${var.environment}/audience"
  description = "Okta Audience"
  type        = "String"
  value       = "api://${local.app_name}"

  tags = {
    environment = var.environment
  }
}


