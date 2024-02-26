resource "aws_api_gateway_rest_api" "users-api" {
  name        = "athena-users-api"
  description = "Aws Web Server API Gateway"
  body = templatefile("${path.module}/../../apps/api-gateway/api.yaml",
    {
      aws_region       = var.AWS_REGION
      users_lambda_arn = aws_lambda_function.users-lambda.arn
      domain_url       = ""
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "users-api-gateway"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.users-api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "api-gateway-invoke-users-lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.users-lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the specified API Gateway.
  source_arn = "${aws_api_gateway_rest_api.users-api.execution_arn}/*/*"
}
