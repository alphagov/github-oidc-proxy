locals {
  service_name = "github-oidc-proxy"
  apigw_stage_name = "main"
  api_name = "github-oidc-proxy-${var.environment_name}"

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
  }
}

resource "aws_api_gateway_rest_api" "github_oidc_proxy" {
  name = local.api_name
  body = jsonencode({
    "swagger" = "2.0"
    "info" = {
      "version" = "1.0"
      "title" = local.api_name
    }
    "paths" = {
      "/token" = {
        "post" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["token"].invoke_arn
          }
          "responses" = {}
        }
        "get" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["token"].invoke_arn
          }
          "responses" = {}
        }
      }
      "/authorize" = {
        "get" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["authorize"].invoke_arn
          }
          "responses" = {}
        }
      }
      "/userinfo" = {
        "post" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["userinfo"].invoke_arn
          }
          "responses" = {}
        }
        "get" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["userinfo"].invoke_arn
          }
          "responses" = {}
        }
      }
      "/.well-known/jwks.json" = {
        "get" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["jwks"].invoke_arn
          }
          "responses" = {}
        }
      }
      "/.well-known/openid-configuration" = {
        "get" = {
          "x-amazon-apigateway-integration" = {
            "httpMethod" = "POST"
            "type" = "aws_proxy"
            "uri" = aws_lambda_function.handler["openIdConfiguration"].invoke_arn
          }
          "responses" = {}
        }
      }
    }
  })
  tags = local.default_tags
}

resource "aws_api_gateway_deployment" "current" {
  rest_api_id = aws_api_gateway_rest_api.github_oidc_proxy.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.github_oidc_proxy.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lambda_permission.allow_apigw_invoke]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.current.id
  rest_api_id   = aws_api_gateway_rest_api.github_oidc_proxy.id
  stage_name    = local.apigw_stage_name
  tags = local.default_tags
}

resource "aws_iam_role" "basic_lambda_role" {
  name_prefix = "basic_lambda_role_${var.environment_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = local.default_tags
}

data "archive_file" "dist_lambda" {
  type        = "zip"
  source_dir = "${path.module}/../dist-lambda"
  output_path = "${path.module}/../dist-lambda.zip"
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  for_each = local.handler_names

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.github_oidc_proxy.execution_arn}/${local.apigw_stage_name}/*/*"
}

resource "aws_lambda_function" "handler" {
  for_each = local.handler_names

  function_name = "${local.service_name}-${var.environment_name}-${each.key}"

  role = aws_iam_role.basic_lambda_role.arn
  publish = true

  runtime = "nodejs10.x"
  timeout = 15

  handler = "${each.key}.handler"

  environment {
    variables = local.lambda_environment_variables
  }

  filename = data.archive_file.dist_lambda.output_path
  source_code_hash = data.archive_file.dist_lambda.output_base64sha256

  tags = local.default_tags
}

