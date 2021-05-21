resource "aws_cloudwatch_log_subscription_filter" "central_log" {
  for_each = toset(
    trimspace(var.log_subscription_destination_arn) != "" ? [
      for k, l in aws_lambda_function.handler: l.function_name
    ] : []
  )

  name           = "central_log"
  log_group_name = "/aws/lambda/${each.key}"
  filter_pattern = ""

  destination_arn = var.log_subscription_destination_arn
}
