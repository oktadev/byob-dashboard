# Local variables
locals {
  app_name = "byob-dashboard"
}

variable "api_token" {
    type = string
}

variable "org_name" {
    type = string
}

variable "base_url" {
    type = string
}

variable "app_url" {
    type = string
}