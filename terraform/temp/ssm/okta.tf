provider "okta" {
  org_name  = var.org_name
  api_token = var.api_token
  base_url  = var.base_url
  version   = "~> 3.0"
}

data "okta_app" "okta-byob" {
    label = local.app_name
}

data "okta_auth_server" "okta-byob" {
    name = local.app_name
}