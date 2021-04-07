variable "environment_name" {
  default = "frank"
}

variable "deployer_role_arn" {
  type = string
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
