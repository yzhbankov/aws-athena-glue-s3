output "api_gateway_base_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "aws_region" {
  value = var.AWS_REGION
}
