variable "environment_name" {
  default = "dev"
}

variable "deployer_role_arn" {
  type = string
}

variable "domain_root_zone_tfstate_s3_region" {
  default = ""
}

variable "domain_root_zone_tfstate_s3_bucket" {
  default = ""
}

variable "domain_root_zone_tfstate_s3_key" {
  default = ""
}

variable "domain_root_zone_tfstate_id_output_name" {
  default = ""
}

variable "domain_subdomain" {
  default = ""
}

variable "allowed_ips_tf_module_output_name" {
  default = ""
}

variable "allowed_ips" {
  default = ""
}

variable "log_subscription_destination_arn" {
  default = ""
}

# environment variables for the lambdas

variable "GITHUB_CLIENT_SECRET" {
  type = string
  sensitive = true
}
variable "GITHUB_CLIENT_ID" {
  type = string
  sensitive = true
}
variable "REDIRECT_URI" {
  default = "http://localhost:1234"
}
variable "GITHUB_API_URL" {
  default = "https://api.github.com"
}
variable "GITHUB_LOGIN_URL" {
  default = "https://github.com"
}
