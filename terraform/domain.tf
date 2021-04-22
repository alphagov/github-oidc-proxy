data "terraform_remote_state" "domain_root_zone" {
  for_each = local.domains

  backend = "s3"

  config = {
    region = each.value.root_zone_tfstate_s3_region
    bucket = each.value.root_zone_tfstate_s3_bucket
    key = each.value.root_zone_tfstate_s3_key
    role_arn = local.deployer_role_arn
  }
}

data "aws_route53_zone" "public_root" {
  for_each = local.domains

  zone_id = data.terraform_remote_state.domain_root_zone[each.key].outputs[each.value.root_zone_tfstate_id_output_name]
}

resource "aws_route53_record" "public_alias" {
  for_each = local.domains

  zone_id = data.aws_route53_zone.public_root[each.key].zone_id
  name = aws_api_gateway_domain_name.public[each.key].domain_name
  type = "A"

  alias {
    name = aws_api_gateway_domain_name.public[each.key].regional_domain_name
    zone_id = aws_api_gateway_domain_name.public[each.key].regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_domain_name" "public" {
  for_each = local.domains

  domain_name = aws_acm_certificate.public_domain_cert[each.key].domain_name
  regional_certificate_arn = aws_acm_certificate_validation.public_domain_cert[each.key].certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.default_tags
}

resource "aws_api_gateway_base_path_mapping" "public_main" {
  for_each = local.domains

  domain_name = aws_api_gateway_domain_name.public[each.key].domain_name
  api_id      = aws_api_gateway_stage.main.rest_api_id
  stage_name  = aws_api_gateway_stage.main.stage_name
}

resource "aws_acm_certificate" "public_domain_cert" {
  for_each = local.domains

  domain_name = "${each.value.subdomain}.${data.aws_route53_zone.public_root[each.key].name}"
  validation_method = "DNS"

  tags = local.default_tags
}

resource "aws_route53_record" "public_domain_cert_validation" {
  # terraform (at time of writing) only supports flattening lists of lists, so we have to perform the
  # flattening on a list of maps, then turn that back into a map of maps, assigning a sensible key.
  for_each = {
    for crossobj in flatten([for domains_key, domains_value in local.domains : [
      for dvo in aws_acm_certificate.public_domain_cert[domains_key].domain_validation_options : {
        domains_key = domains_key
        domains_value = domains_value
        dvo = dvo
      }
    ]]) : "${crossobj.domains_key}__${crossobj.dvo.domain_name}" => crossobj
  }

  name    = each.value.dvo.resource_record_name
  records = [each.value.dvo.resource_record_value]
  type    = each.value.dvo.resource_record_type
  zone_id = data.aws_route53_zone.public_root[each.value.domains_key].zone_id
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "public_domain_cert" {
  for_each = local.domains

  certificate_arn = aws_acm_certificate.public_domain_cert[each.key].arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.public_domain_cert[each.key].domain_validation_options :
    aws_route53_record.public_domain_cert_validation["${each.key}__${dvo.domain_name}"].fqdn
  ]
}
