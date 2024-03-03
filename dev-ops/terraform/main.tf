# AWS S3 Data Source
resource "aws_s3_bucket" "users_bucket" {
  bucket = "users_bucket"
}

resource "aws_s3_object" "csv_files_folder" {
  key    = "csv-files/"
  bucket = aws_s3_bucket.users_bucket.id
}

resource "aws_s3_bucket_ownership_controls" "users_bucket" {
  bucket = aws_s3_bucket.users_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "users_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.users_bucket]

  bucket = aws_s3_bucket.users_bucket.id
  acl    = "private"
}

# AWS S3 Output Bucket
resource "aws_s3_bucket" "athena_query_results_bucket" {
  bucket = "athena-query-results-bucket"
}

resource "aws_s3_bucket_ownership_controls" "athena_query_results_bucket" {
  bucket = aws_s3_bucket.athena_query_results_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "athena_query_results_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.athena_query_results_bucket]

  bucket = aws_s3_bucket.athena_query_results_bucket.id
  acl    = "private"
}
