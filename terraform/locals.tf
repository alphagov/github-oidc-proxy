locals {
  service_name = "github-oidc-proxy"
  apigw_stage_name = "main"
  api_name = "${local.service_name}-${var.environment_name}"

  deployer_role_arn = trimspace(var.deployer_role_arn) != "" ? var.deployer_role_arn : null

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

  allowed_ips_tf_modules = trimspace(var.allowed_ips_tf_module_output_name) != "" ? {
    main = {
      tf_module_output_name = var.allowed_ips_tf_module_output_name
    }
  } : {}

  # if this somehow becomes a single-item list, you will likely run into
  # https://github.com/hashicorp/terraform-provider-aws/issues/17341
  allowed_ips_final_list = concat(
    flatten([
      for k, v in local.allowed_ips_tf_modules : module.allowed_ips[k][v.tf_module_output_name]
    ]),
    trimspace(var.allowed_ips) != "" ? split(",", var.allowed_ips) : [],
  )

  allowed_ips_policies = local.allowed_ips_final_list != [] ? {
    main = {
      final_ip_list = local.allowed_ips_final_list
    }
  } : {}
}
