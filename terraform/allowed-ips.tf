module "allowed_ips" {
  for_each = local.allowed_ips_tf_modules

  source = "./modules/allowed-ips"
}

resource "aws_api_gateway_rest_api_policy" "allowed_ips" {
  for_each = local.allowed_ips_policies

  rest_api_id = aws_api_gateway_rest_api.github_oidc_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Principal = "*"
          Action = "execute-api:Invoke"
          Resource = "${aws_api_gateway_rest_api.github_oidc_proxy.execution_arn}/*"
        },
      ],
      # not all endpoints can be IP-restricted: IAM itself needs to hit at least /.well-known/jwks.json
      # from an unpredictable source ip.
      [
        for path in ["/token", "/authorize", "/userinfo"] : {
          Effect = "Deny"
          Principal = "*"
          Action = "execute-api:Invoke"
          Resource = "${aws_api_gateway_rest_api.github_oidc_proxy.execution_arn}/*/*${path}"
          Condition = {
            NotIpAddress = {
              "aws:SourceIp" = each.value.final_ip_list
            }
          }
        }
      ],
    )
  })
}
