resource "aws_athena_data_catalog" "athena_users_data_catalog" {
  name        = "glue-data-catalog"
  description = "Glue based Data Catalog"
  type        = "GLUE"

  parameters = {
    "catalog-id" = aws_glue_catalog_database.glue_database.id
  }
}

resource "aws_athena_workgroup" "athena_users_workgroup" {
  name = "athena_users_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results_bucket.bucket}/output/"
    }
  }
}
