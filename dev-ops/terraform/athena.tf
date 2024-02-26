resource "aws_s3_bucket" "athena_query_results_bucket" {
  bucket = "athena-query-results-bucket"
  acl    = "private"
}

resource "aws_athena_workgroup" "athena_users_workgroup" {
  name = "athena_users_workgroup"
}

resource "aws_athena_data_catalog" "athena_users_data_catalog" {
  name = "athena_users_data_catalog"
}
