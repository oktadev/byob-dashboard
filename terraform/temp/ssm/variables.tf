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

variable "aws_region" {
    type = string
}

variable "aws_profile" {
    type = string
}

variable "aws_ssm_prefix" {
    type = string
}

variable "environment" {
    type = string
}