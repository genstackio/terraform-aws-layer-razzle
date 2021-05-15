resource "aws_s3_bucket" "statics" {
  bucket = var.bucket_name
  acl    = "private"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET", "PUT", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  dynamic "versioning" {
    for_each = local.is_replication_mode ? {x = true} : {}
    content {
      enabled = true
    }
  }
  dynamic "replication_configuration" {
    for_each = local.is_replication_master ? {x: true} : {}
    content {
      role = aws_iam_role.replication[0].arn
      rules {
        id     = "all"
        status = "Enabled"
        dynamic "destination" {
          for_each = toset(var.replications)
          content {
            bucket        = destination.value
            storage_class = "STANDARD"
          }
        }
      }
    }
  }
}

resource "aws_s3_bucket_policy" "statics" {
  bucket = aws_s3_bucket.statics.id
  policy = data.aws_iam_policy_document.s3_website_policy.json
}

resource "aws_iam_role" "replication" {
  count              = local.replication_master_count
  name_prefix        = "tf-iam-role-replication-"
  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume_role_policy[0].json
}

resource "aws_iam_policy" "replication" {
  count       = local.replication_master_count
  name_prefix = "tf-iam-role-policy-replication-"
  policy      = data.aws_iam_policy_document.s3_replication_policy[0].json
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = local.replication_master_count
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}