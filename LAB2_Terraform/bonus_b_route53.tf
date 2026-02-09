############################################
# Bonus B - Route53 (Hosted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

data "aws_route53_zone" "arcanum_existing" {
  zone_id = var.route53_hosted_zone_id
}
locals {
  # Explanation: arcanum needs a home planet—Route53 hosted zone is your DNS territory.
  arcanum_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (students choose their destiny).
  arcanum_zone_id = var.route53_hosted_zone_id

  # Explanation: This is the app address that will growl at the galaxy (app.arcanum-growl.com).
  arcanum_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Hosted Zone (optional creation)
############################################

# # Explanation: A hosted zone is like claiming Kashyyyk in DNS—names here become law across the galaxy.
# resource "aws_route53_zone" "arcanum_zone01" {
#   count = var.manage_route53_in_terraform ? 1 : 0

#   name = local.arcanum_zone_name

#   tags = {
#     Name = "${var.project_name}-zone01"
#   }
# }

############################################
# ACM DNS Validation Records
############################################

# Explanation: ACM asks “prove you own this planet”—DNS validation is arcanum roaring in the right place.
resource "aws_route53_record" "arcanum_acm_validation_records01" {
  allow_overwrite = true

  for_each = var.certificate_validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.arcanum_acm_cert01.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = local.arcanum_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}

# Explanation: This ties the “proof record” back to ACM—arcanum gets his green checkmark for TLS.
resource "aws_acm_certificate_validation" "arcanum_acm_validation01_dns_bonus" {
  count = var.certificate_validation_method == "DNS" ? 1 : 0

  certificate_arn = aws_acm_certificate.arcanum_acm_cert01.arn

  validation_record_fqdns = [
    for r in aws_route53_record.arcanum_acm_validation_records01 : r.fqdn
  ]
}

# ############################################
# # ALIAS record: app.arcanum-base.com -> ALB
# ############################################

# # # Explanation: This is the holographic sign outside the cantina—app.arcanum-base.com points to your ALB.
# resource "aws_route53_record" "arcanum_app_alias01" {
#   zone_id = local.arcanum_zone_id
#   name    = local.arcanum_app_fqdn
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.arcanum_cf01.domain_name
#     zone_id                = aws_cloudfront_distribution.arcanum_cf01.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# # Apex -> ALB
# resource "aws_route53_record" "arcanum_apex_to_alb" {
#   zone_id = data.aws_route53_zone.arcanum_existing.zone_id
#   name    = var.domain_name
#   type    = "A"

#   alias {
#     name                   = aws_lb.arcanum_alb01.dns_name
#     zone_id                = aws_lb.arcanum_alb01.zone_id
#     evaluate_target_health = true
#   }
# }

# # app -> ALB
# resource "aws_route53_record" "arcanum_app_to_alb" {
#   zone_id = data.aws_route53_zone.arcanum_existing.zone_id
#   name    = "app.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = aws_lb.arcanum_alb01.dns_name
#     zone_id                = aws_lb.arcanum_alb01.zone_id
#     evaluate_target_health = true
#   }
# }
