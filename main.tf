module "https-cert" {
  source    = "./modules/https-cert"
  dns       = var.dns
  zone      = var.dns_zone
  providers = {
    aws     = aws
    aws.acm = aws.acm
  }
}

module "cdn" {
  source                      = "./modules/cdn"
  dns                         = var.dns
  zone                        = var.dns_zone
  certificate_arn             = module.https-cert.certificate_arn
  geolocations                = var.geolocations
  apex_redirect               = var.apex_redirect
  price_class                 = var.price_class
  origin_request_config_file  = var.origin_request_config_file
  origin_response_config_file = var.origin_response_config_file
  name                        = var.name
  custom_behaviors            = var.custom_behaviors
  s3_master_domain_name       = var.s3_master_domain_name
  regional_statics_buckets    = var.regional_statics_buckets
  regional_razzle_apps        = var.regional_razzle_apps
  providers                   = {
    aws = aws
  }
}