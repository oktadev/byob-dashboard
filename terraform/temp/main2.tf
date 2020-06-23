## BYOB Okta Org configuration for:
#    Oauth2 SPA
#    Custom authorization server for SPA

module "okta" {
    source = "./okta"

    api_token = var.api_token
    org_name  = var.org_name
    base_url  = var.base_url
    app_url = var.app_url
}

module "ssm" {
    source = "./ssm"

    api_token = var.api_token
    org_name  = var.org_name
    base_url  = var.base_url
    app_url = var.app_url

    aws_region = var.aws_region
    aws_profile = var.aws_profile
    aws_ssm_prefix = var.aws_ssm_prefix
    environment = var.environment
}

