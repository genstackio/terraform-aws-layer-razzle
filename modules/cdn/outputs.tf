output "dns" {
  value = var.dns
}
output "cloudfront_id" {
  value = aws_cloudfront_distribution.webapp.id
}
output "cloudfront_iam_arn" {
  value = aws_cloudfront_origin_access_identity.oai.iam_arn
}