output "arn" {
  value = aws_s3_bucket.statics.arn
}
output "name" {
  value = aws_s3_bucket.statics.id
}
output "regional_domain_name" {
  value = aws_s3_bucket.statics.bucket_regional_domain_name
}