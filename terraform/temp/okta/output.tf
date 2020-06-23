output "okta_app_oauth_client_id" {
  value = okta_app_oauth.okta-byob.client_id
}

output "okta_auth_server_id" {
  value = okta_auth_server.okta-byob.id
}

output "okta_auth_server_issuer_uri" {
  value = "https://${var.org_name}.${var.base_url}/oauth2/${okta_auth_server.okta-byob.id}"
}