resource "aws_athena_data_catalog" "athena_users_data_catalog" {
  name        = "athena-users-data-catalog"
  description = "Athena Users data catalog"
  #  type        = "LAMBDA"

  #  parameters = {
  #    "function" = "arn:aws:lambda:eu-central-1:123456789012:function:not-important-lambda-function"
  #  }
}
