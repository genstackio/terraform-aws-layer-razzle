resource "aws_acm_certificate" "cert" {
  domain_name       = local.dns_0
  validation_method = "DNS"
  provider          = aws.acm
  subject_alternative_names = local.extra_dnses

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  zone_id = var.zone
  records = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value]
  ttl     = 60
}
resource "aws_route53_record" "cert_validation_alt" {
  count   = (null != local.dns_1) ? 1 : 0
  name    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_name
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_type
  zone_id = var.zone
  records = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 1).resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = (null != local.dns_1) ? [aws_route53_record.cert_validation.fqdn, aws_route53_record.cert_validation_alt[0].fqdn] : [aws_route53_record.cert_validation.fqdn]
}

