output "dns" {
  value = module.cdn.dns
}
output "cloudfront_id" {
  value = module.cdn.cloudfront_id
}
output "cloudfront_iam_arn" {
  value = module.cdn.cloudfront_iam_arn
}