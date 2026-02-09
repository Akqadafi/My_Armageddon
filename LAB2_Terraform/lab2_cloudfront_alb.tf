# ###########################################
# Lab 2 - CloudFront in front of ALB
# Internet -> CloudFront (+WAF) -> ALB -> Private EC2 -> RDS
# ###########################################

# IMPORTANT:
# - This file assumes aws_lb.arcanum_alb01 already exists (from Bonus B).
# - This file assumes you already have ONE random_password resource somewhere else
#   (e.g., bonus_b.tf) named: random_password.arcanum_origin_header_value01
# - This file assumes a CloudFront-scoped WAF exists:
#   aws_wafv2_web_acl.arcanum_cf_waf01 (scope = "CLOUDFRONT")

# locals {
#   # Explanation: The header CloudFront sends and ALB requires.
#   # Use the SAME header name in your ALB listener rule condition.
#   origin_header_name  = "X-arcanum-base"
#   origin_header_value = random_password.arcanum_origin_header_value01.result
# }

resource "aws_cloudfront_distribution" "arcanum_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"
  web_acl_id      = aws_wafv2_web_acl.arcanum_cf_waf01.arn

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.arcanum_alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    origin_shield {
      enabled              = true
      origin_shield_region = "ap-northeast-1"
    }

    custom_header {
      name  = local.origin_header_name
      value = local.origin_header_value
    }
  }

  ############################################################
  # Honors: api/public-feed = origin-driven caching
  # IMPORTANT: more specific must come before api/*
  ############################################################
  ordered_cache_behavior {
    path_pattern           = "api/public-feed"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.arcanum_use_origin_cache_headers01.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.arcanum_orp_all_viewer_except_host01.id

    compress = true
  }

  ############################################################
  # api/* = safe default (no caching)
  ############################################################
  ordered_cache_behavior {
    path_pattern           = "api/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.arcanum_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.arcanum_orp_api01.id

    compress = true
  }

  ############################################################
  # static/* = cache hard
  ############################################################
  ordered_cache_behavior {
    path_pattern           = "static/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.arcanum_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.arcanum_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.arcanum_rsp_static01.id

    compress = true
  }

  ############################################################
  # Default behavior = conservative / dynamic
  ############################################################
  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.arcanum_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.arcanum_orp_api01.id

    compress = true
  }

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_wafv2_web_acl.arcanum_cf_waf01
  ]
}