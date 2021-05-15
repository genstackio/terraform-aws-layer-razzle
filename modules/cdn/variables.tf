variable "name" {
  type    = string
  default = "front"
}
variable "dns" {
  type = string
}
variable "zone" {
  type = string
}
variable "apex_redirect" {
  type    = bool
  default = false
}
variable "certificate_arn" {
  type = string
}
variable "geolocations" {
  type    = list(string)
  default = []
}
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
variable "origin_request_config_file" {
  type    = string
  default = null
}
variable "origin_response_config_file" {
  type    = string
  default = null
}
variable "custom_behaviors" {
  type    = list(any)
  default = null
}
variable "s3_master_domain_name" {
  type = string
}
variable "regional_razzle_apps" {
  type = map(object({
    endpoint = string
    domain = string
  }))
  default = {}
}
variable "regional_statics_buckets" {
  type = map(object({
    arn  = string
    name = string
    domain = string
  }))
  default = {}
}
variable "custom_error_responses" {
  type = list(object({
    error_code = number
    response_code = number
    response_page_path = string
  }))
  default = []
}