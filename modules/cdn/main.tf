resource "aws_cloudfront_origin_access_identity" "oai" {
}

resource "aws_cloudfront_distribution" "webapp" {
  origin {
    domain_name = var.s3_master_domain_name // unused domain name
    origin_id   = "statics"
    origin_path = ""
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
    custom_header {
      name  = "X-Razzle-Buckets"
      value = local.header_x_razzle_buckets
    }
    custom_header {
      name  = "X-Razzle-Apps"
      value = local.header_x_razzle_apps
    }
  }
  // dynamics => /* (failover: after having tried 'cached' origin, this one is calling the api-gateway with Razzle lambda)
  origin {
    domain_name = var.s3_master_domain_name // unused domain name
    origin_id   = "dynamics"
    origin_path = ""
    custom_header {
      name  = "X-Razzle-Buckets"
      value = local.header_x_razzle_buckets
    }
    custom_header {
      name  = "X-Razzle-Apps"
      value = local.header_x_razzle_apps
    }
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  // publics => /*.* (to be fetched with path '/publics/*.*' on the s3 bucket)
  origin {
    domain_name = var.s3_master_domain_name // unused domain name
    origin_id   = "publics"
    origin_path = ""
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
    custom_header {
      name  = "X-Razzle-Buckets"
      value = local.header_x_razzle_buckets
    }
    custom_header {
      name  = "X-Razzle-Apps"
      value = local.header_x_razzle_apps
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.geolocations) == 0 ? "none" : "whitelist"
      locations        = length(var.geolocations) == 0 ? null : var.geolocations
    }
  }

  tags = {
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "HA Razzle ${var.name} CloudFront CDN Distribution"
  default_root_object = null
  aliases             = local.dnses
  price_class         = var.price_class

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "dynamics"
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3_origin.id
    viewer_protocol_policy   = "redirect-to-https"
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda-origin-request.qualified_arn
      include_body = false
    }
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda-origin-response.qualified_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/static/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "statics"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3_origin.id
    compress                 = true
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda-origin-request.qualified_arn
      include_body = false
    }
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda-origin-response.qualified_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/*.*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "publics"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3_origin.id
    compress                 = true
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda-origin-request.qualified_arn
      include_body = false
    }
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda-origin-response.qualified_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "dynamics"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    min_ttl                  = 0
    default_ttl              = 0
    max_ttl                  = 86400
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = local.forwarded_headers
    }
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda-origin-request.qualified_arn
      include_body = false
    }
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda-origin-response.qualified_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern             = "/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "dynamics"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    min_ttl                  = 0
    default_ttl              = 0
    max_ttl                  = 86400
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = local.forwarded_headers
    }
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda-origin-request.qualified_arn
      include_body = false
    }
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.lambda-origin-response.qualified_arn
      include_body = false
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.custom_behaviors != null ? var.custom_behaviors : []
    content {
      path_pattern             = ordered_cache_behavior.value["path_pattern"]
      allowed_methods          = lookup(ordered_cache_behavior.value, "allowed_methods", ["GET", "HEAD"])
      cached_methods           = lookup(ordered_cache_behavior.value, "cached_methods", ["GET", "HEAD"])
      target_origin_id         = lookup(ordered_cache_behavior.value, "target_origin_id", "publics")
      compress                 = lookup(ordered_cache_behavior.value, "compress", true)
      viewer_protocol_policy   = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", "redirect-to-https")
      origin_request_policy_id = lookup(ordered_cache_behavior.value, "origin_request_policy_id", null)
      cache_policy_id          = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
    }
  }

  dynamic "custom_error_response" {
    for_each = toset(var.custom_error_responses)
    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
    }
  }
}

resource "aws_route53_record" "webapp" {
  zone_id = var.zone
  name    = local.dns_0
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.webapp.domain_name
    zone_id                = aws_cloudfront_distribution.webapp.hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "webapp_apex" {
  count   = (null != local.dns_1) ? 1 : 0
  zone_id = var.zone
  name    = local.dns_1
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.webapp.domain_name
    zone_id                = aws_cloudfront_distribution.webapp.hosted_zone_id
    evaluate_target_health = false
  }
}

module "lambda-origin-request" {
  source      = "../lambda-origin-request"
  name        = "${var.name}-origin-request"
  config_file = local.origin_request_config_file
}

module "lambda-origin-response" {
  source      = "../lambda-origin-response"
  name        = "${var.name}-origin-response"
  config_file = local.origin_response_config_file
}
