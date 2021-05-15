data "aws_iam_policy_document" "s3_website_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.statics.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_iam_arn]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.statics.arn]
    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_iam_arn]
    }
  }
}

data "aws_iam_policy_document" "s3_replication_assume_role_policy" {
  count = local.replication_master_count
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "s3_replication_policy" {
  count = local.replication_master_count
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.statics.arn
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "${aws_s3_bucket.statics.arn}/*"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = [for r in var.replications: "${r}/*"]
    effect = "Allow"
  }
}