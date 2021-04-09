variable "environment_name" {
  default = "frank"
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

# environment variables for the lambdas

variable "GITHUB_CLIENT_SECRET" {
  type = string
  sensitive = true
}
variable "GITHUB_CLIENT_ID" {
  type = string
  sensitive = true
}
variable "COGNITO_REDIRECT_URI" {
  default = "http://localhost:1234"
}
variable "GITHUB_API_URL" {
  default = "https://api.github.com"
}
variable "GITHUB_LOGIN_URL" {
  default = "https://github.com"
}
