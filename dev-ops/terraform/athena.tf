resource "aws_athena_workgroup" "athena_users_workgroup" {
  name = "${terraform.workspace}-yz-athena-users-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results_bucket.bucket}/output/"
    }
  }
}
