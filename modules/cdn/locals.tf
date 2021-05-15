locals {
  is_www      = "www." == substr(var.dns, 0, 4)
  dns_0       = var.dns
  dns_1       = var.apex_redirect ? (local.is_www ? substr(var.dns, 4, length(var.dns) - 4) : "www.${var.dns}") : null
  dnses       = concat([local.dns_0], (null != local.dns_1) ? [local.dns_1] : [])
  extra_dnses = (null != local.dns_1) ? [local.dns_1] : null
  origin_request_config_file = null == var.origin_request_config_file ? "${path.module}/origin_request_config.js" : var.origin_request_config_file
  origin_response_config_file = null == var.origin_response_config_file ? "${path.module}/origin_response_config.js" : var.origin_response_config_file
  forwarded_headers = [
    "CloudFront-Is-Desktop-Viewer",
    "CloudFront-Is-Tablet-Viewer",
    "CloudFront-Is-Mobile-Viewer",
    "CloudFront-Viewer-Country",
    "CloudFront-Viewer-Country-Region",
    "Origin",
    "Access-Control-Request-Headers",
    "Access-Control-Request-Method",
    "User-Agent",
  ]
  header_x_razzle_buckets = jsonencode({for k, v in var.regional_statics_buckets : k => {domain: v.domain}})
  header_x_razzle_apps    = jsonencode({for k, v in var.regional_razzle_apps : k => {domain: v.domain}})
}