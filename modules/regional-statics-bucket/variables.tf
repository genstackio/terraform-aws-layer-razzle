variable "bucket_name" {
  type = string
}
variable "replications" {
  type    = list(string)
  default = []
}
variable "replication_slave" {
  type    = bool
  default = false
}
variable "cloudfront_iam_arn" {
  type    = string
  default = "*"
}