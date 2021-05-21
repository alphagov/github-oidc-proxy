resource "aws_cloudwatch_log_subscription_filter" "central_log" {
  for_each = toset(
    trimspace(var.log_subscription_destination_arn) != "" ? [
      for k, lg in aws_cloudwatch_log_group.lambdas: lg.name
    ] : []
  )

  name           = "central_log"
  log_group_name = "/aws/lambda/${each.key}"
  filter_pattern = ""

  destination_arn = var.log_subscription_destination_arn
}
