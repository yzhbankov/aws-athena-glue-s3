# AWS S3
resource "aws_s3_bucket" "users_bucket" {
  bucket = "users_bucket"
  acl    = "private"
}

resource "aws_s3_bucket_object" "csv_files_folder" {
  bucket = aws_s3_bucket.users_bucket.bucket
  key    = "csv-files/"
  acl    = "private"
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "glue_crawler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com",
        },
      },
    ],
  })
}

# Attach AWS managed AWSGlueServiceRole policy
resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_crawler_role.name
}

# Create a custom policy for Get and Put access to users_bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy allowing Get and Put access to users_bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ],
        Resource = [
          "${aws_s3_bucket.users_bucket.arn}/*",
        ],
      },
    ],
  })
}

# Attach the custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.glue_crawler_role.name
}

resource "aws_glue_database" "glue_database" {
  name = "glue_users_database"
}

resource "aws_glue_table" "glue_users_table" {
  name     = "glue_users_table"
  database = aws_glue_database.glue_database.name

  table_input {
    name = "glue_users_table"
    parameters = {
      "classification" = "csv"
    }

    storage_descriptor {
      location      = aws_s3_bucket_object.csv_files_folder.bucket
      input_format  = "org.apache.hadoop.mapred.TextInputFormat"
      output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

      serde_info {
        name                  = "glue_users_table"
        serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      }
    }
    columns = [
      { name = "first_name", type = "string" },
      { name = "second_name", type = "string" },
      { name = "email", type = "string" },
      { name = "created_at", type = "string" },
      { name = "updated_at", type = "string" },
      { name = "id", type = "bigint" },
    ]
  }
}

resource "aws_glue_classifier" "csv_classifier_users" {
  name = "CSV-Classifier-Users"
  csv_classifier {
    allow_single_column = false
    contains_header     = "PRESENT"
    delimiter           = ","
    disable_value_trim  = false
    header = [
      "first_name",
      "second_name",
      "email",
      "created_at",
      "updated_at",
      "id",
    ]
    name = "CSV-Classifier-Users"
  }
}

resource "aws_glue_crawler" "example_crawler" {
  name          = "glue_users_crawler"
  database_name = aws_glue_database.glue_database.name
  role          = aws_iam_role.glue_crawler_role.arn
  table_name    = aws_glue_table.glue_users_table.name
  classifiers   = [aws_glue_classifier.csv_classifier_users.name]
  s3_target {
    path = aws_s3_bucket.users_bucket.bucket
  }
}
