output "api_base_url" {
  value = (
    contains(keys(local.domains), "main") ?
    "https://${aws_api_gateway_domain_name.public["main"].domain_name}"
    : aws_api_gateway_stage.main.invoke_url
  )
}
