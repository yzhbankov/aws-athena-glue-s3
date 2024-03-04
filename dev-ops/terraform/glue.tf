resource "aws_iam_role" "glue_crawler_role" {
  name = "${terraform.workspace}_yz_glue_crawler_role"
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

resource "aws_glue_catalog_database" "glue_database" {
  name = "${terraform.workspace}-yz-glue-users-db"
}

resource "aws_glue_catalog_table" "glue_users_table" {
  name          = "${terraform.workspace}_yz_glue_users_table"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "skip.header.line.count" = 1
    "quoteChar"              = "'"
    "classification"         = "csv"
    "delimiter"              = ","
  }

  storage_descriptor {
    location      = "s3://${aws_s3_object.csv_files_folder.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "${terraform.workspace}_yz_glue_users_table"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "'"
      }
    }

    columns {
      name = "first_name"
      type = "string"
    }

    columns {
      name = "second_name"
      type = "string"
    }

    columns {
      name = "email"
      type = "string"
    }

    columns {
      name = "created_at"
      type = "string"
    }

    columns {
      name = "updated_at"
      type = "string"
    }

    columns {
      name = "id"
      type = "bigint"
    }

  }
}

resource "aws_glue_classifier" "csv_classifier_users" {
  name = "${terraform.workspace}-yz-CSV-Classifier-Users"

  csv_classifier {
    allow_single_column    = false
    contains_header        = "PRESENT"
    delimiter              = ","
    disable_value_trimming = false
    header                 = ["first_name", "second_name", "email", "created_at", "updated_at", "id"]
    quote_symbol           = "'"
  }
}

resource "aws_glue_crawler" "example_crawler" {
  name          = "${terraform.workspace}_yz_glue_users_crawler"
  database_name = aws_glue_catalog_database.glue_database.name
  role          = aws_iam_role.glue_crawler_role.arn
  classifiers   = [aws_glue_classifier.csv_classifier_users.name]

  s3_target {
    path = aws_s3_bucket.users_bucket.bucket
  }

  table_exists_behavior = "UPDATE_IN_DATABASE"
}

