locals {
  users-lambda   = "${path.module}/../../apps/lambdas/users"
  lambda_timeout = 60
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "athena_execution_policy" {
  # Define the IAM policy for Athena execution
  # You may need to customize this policy based on your specific needs
  source_json = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution"
      ],
      "Resource": "*"
    }
  ]
}
JSON
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${terraform.workspace}_athena_users_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "athena_execution_attachment" {
  policy_arn = data.aws_iam_policy.athena_execution_policy.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_role_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Users LAMBDA
resource "null_resource" "install_users_dependencies" {
  provisioner "local-exec" {
    command = "cd ${local.users-lambda} && npm install"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "archive_file" "users-lambda" {
  type        = "zip"
  source_dir  = local.users-lambda
  output_path = "/tmp/users-lambda.zip"

  depends_on = [null_resource.install_users_dependencies]
}

resource "aws_lambda_function" "users-lambda" {
  function_name    = "${terraform.workspace}-users-lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = data.archive_file.users-lambda.output_path
  handler          = "index.handler"
  source_code_hash = data.archive_file.users-lambda.output_base64sha256
  runtime          = "nodejs14.x"
  timeout          = local.lambda_timeout


  environment = {
    variables = {
      ENVIRONMENT = terraform.workspace
      ATHENA_REGION      = "us-east-1",  # Replace with your Athena region
      ATHENA_WORKGROUP   = athena_users_workgroup,  # Replace with your Athena workgroup
      ATHENA_OUTPUT_PATH = athena_query_results_bucket,  # Replace with your S3 bucket path
      DATABASE_NAME    = aws_glue_database.glue_database.name
      TABLE_NAME = aws_glue_table.glue_users_table.name
    }
  }
}
