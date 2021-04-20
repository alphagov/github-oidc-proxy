locals {
  service_name = "github-oidc-proxy"
  apigw_stage_name = "main"
  api_name = "${local.service_name}-${var.environment_name}"

  handler_names = toset([
    "token",
    "authorize",
    "userinfo",
    "jwks",
    "openIdConfiguration",
  ])

  default_tags = {
    ManagedBy   = "terraform"
    Source      = "github.com/alphagov/github-oidc-proxy"
    Environment = var.environment_name
    Service     = local.service_name
  }

  lambda_environment_variables = {
    GITHUB_CLIENT_SECRET = var.GITHUB_CLIENT_SECRET
    GITHUB_CLIENT_ID = var.GITHUB_CLIENT_ID
    COGNITO_REDIRECT_URI = var.COGNITO_REDIRECT_URI
    GITHUB_API_URL = var.GITHUB_API_URL
    GITHUB_LOGIN_URL = var.GITHUB_LOGIN_URL
    OIDC_ISSUER_OMIT_STAGE = jsonencode(contains(keys(local.domains), "main"))
  }

  domains = (
    trimspace(var.domain_root_zone_tfstate_s3_region) != "" &&
    trimspace(var.domain_root_zone_tfstate_s3_bucket) != "" &&
    trimspace(var.domain_root_zone_tfstate_s3_key) != "" &&
    trimspace(var.domain_root_zone_tfstate_id_output_name) != ""
   ) ? {
    main = {
      root_zone_tfstate_s3_bucket = var.domain_root_zone_tfstate_s3_bucket
      root_zone_tfstate_s3_key = var.domain_root_zone_tfstate_s3_key
      root_zone_tfstate_s3_region = var.domain_root_zone_tfstate_s3_region
      root_zone_tfstate_id_output_name = var.domain_root_zone_tfstate_id_output_name
      subdomain = trimspace(var.domain_subdomain) != "" ? var.domain_subdomain : "${local.service_name}-${var.environment_name}"
    }
  } : {}
}
