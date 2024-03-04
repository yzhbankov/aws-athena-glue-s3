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

resource "aws_iam_policy" "athena_execution_policy" {
  name        = "${terraform.workspace}_yz_athena_execution_policy"
  description = "Execution policy for Athena"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "athena:StartQueryExecution"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${terraform.workspace}_yz_athena_users_iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "athena_execution_attachment" {
  policy_arn = aws_iam_policy.athena_execution_policy.arn
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
  function_name    = "${terraform.workspace}-yz-glue-users-lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = data.archive_file.users-lambda.output_path
  handler          = "index.handler"
  source_code_hash = data.archive_file.users-lambda.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = local.lambda_timeout


  environment {
    variables = {
      ENVIRONMENT        = terraform.workspace
      ATHENA_REGION      = "us-east-1",
      ATHENA_WORKGROUP   = aws_athena_workgroup.athena_users_workgroup.name,
      ATHENA_OUTPUT_PATH = aws_s3_bucket.athena_query_results_bucket.bucket,
      DATABASE_NAME      = aws_glue_catalog_database.glue_database.name
      TABLE_NAME         = aws_glue_catalog_table.glue_users_table.name
    }
  }
}
