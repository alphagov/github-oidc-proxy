resource "aws_cloudwatch_log_subscription_filter" "central_log" {
  for_each = (
    trimspace(var.log_subscription_destination_arn) != "" ? {
      for k, lg in aws_cloudwatch_log_group.lambdas: k => lg.name
    } : {}
  )

  name           = "central_log_${each.key}"
  log_group_name = each.value
  filter_pattern = ""

  destination_arn = var.log_subscription_destination_arn
}
