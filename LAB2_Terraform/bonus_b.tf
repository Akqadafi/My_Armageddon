############################################
# Bonus B - ALB (Public) -> Target Group (Private EC2) + TLS + WAF + Monitoring
############################################

locals {
  # Explanation: This is the roar address — where the galaxy finds your app.
  arcanum_fqdn      = "${var.app_subdomain}.${var.domain_name}"
  arcanum_apex_fqdn = var.domain_name # apex

  # Explanation: Secret header used for Lab 2 origin cloaking (CloudFront -> ALB).
  # Keep name consistent across all files.
  origin_header_name = "X-arcanum-base"
}

############################################
# Variables expected (add to variables.tf if missing)
############################################
# variable "certificate_validation_method" { type = string  default = "DNS" } # or "EMAIL"
# variable "enable_waf"                 { type = bool    default = true }
# variable "enable_origin_cloaking"     { type = bool    default = false }   # Lab1=false, Lab2=true
# variable "alb_allow_public_http_https"{ type = bool    default = true }    # Lab1=true, Lab2=false
#
# For Lab2, you typically generate this in CloudFront overlay:
# random_password.arcanum_origin_header_value01.result
# If you already have it somewhere else, do NOT duplicate it.
#
# If you want Bonus-B to own it, uncomment the random_password resource below.

############################################
# (Optional) Secret header value generator
############################################
# IMPORTANT: Only define this ONCE in the whole module.
# If you already have random_password.arcanum_origin_header_value01 elsewhere, leave this commented.
#
resource "random_password" "arcanum_origin_header_value01" {
  length  = 32
  special = false
}
#
locals {
  origin_header_value = random_password.arcanum_origin_header_value01.result
}

############################################
# Security Group: ALB
############################################

# Explanation: The ALB SG is the blast shield.
# Lab1: allow inbound 80/443 from internet.
# Lab2: REMOVE public ingress; allow only CloudFront prefix list (done in lab2 overlay file).
resource "aws_security_group" "arcanum_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.arcanum_vpc01.id

  # # Lab 1 public ingress (toggle)
  # dynamic "ingress" {
  #   for_each = var.alb_allow_public_http_https ? [1] : []
  #   content {
  #     description = "HTTP from internet (redirect to HTTPS)"
  #     from_port   = 80
  #     to_port     = 80
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  # }

  # dynamic "ingress" {
  #   for_each = var.alb_allow_public_http_https ? [1] : []
  #   content {
  #     description = "HTTPS from internet"
  #     from_port   = 443
  #     to_port     = 443
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  # }

  # Egress: ALB -> targets (usually port 80). You can tighten later if you want.
  egress {
    description = "ALB to targets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg01" }
}

# Explanation: arcanum only opens the hangar door — allow ALB -> EC2 on app port (80).
resource "aws_security_group_rule" "arcanum_ec2_ingress_from_alb01" {
  type                     = "ingress"
  security_group_id        = aws_security_group.arcanum_ec2_sg01.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.arcanum_alb_sg01.id
}

############################################
# Application Load Balancer
############################################

resource "aws_lb" "arcanum_alb01" {
  name               = "${var.project_name}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.arcanum_alb_sg01.id]
  subnets         = aws_subnet.arcanum_public_subnets[*].id

  access_logs {
    bucket  = aws_s3_bucket.arcanum_alb_logs_bucket01[0].bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  # # Explanation: arcanum keeps flight logs—ALB access logs go to S3 for audits and incident response.
  # dynamic "access_logs" {
  #   for_each = var.enable_alb_access_logs ? [1] : []
  #   content {
  #     bucket  = aws_s3_bucket.arcanum_alb_logs01[0].bucket
  #     prefix  = var.alb_access_logs_prefix
  #     enabled = true
  #   }
  # }

  # depends_on = [
  #   aws_s3_bucket_policy.arcanum_alb_logs_policy01,
  #   aws_s3_bucket_public_access_block.arcanum_alb_logs_pab01,
  #   aws_s3_bucket_ownership_controls.arcanum_alb_logs_owner01
  # ] 

  tags = { Name = "${var.project_name}-alb01" }
}

############################################
# Target Group + Attachment
############################################

resource "aws_lb_target_group" "arcanum_tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.arcanum_vpc01.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = { Name = "${var.project_name}-tg01" }
}

# resource "aws_lb_target_group_attachment" "arcanum_tg_attach01" {
#   target_group_arn = aws_lb_target_group.arcanum_tg01.arn
#   target_id        = aws_instance.arc_bonus_ec2.id
#   port             = 80
# }

############################################
# ACM Certificate (TLS)
############################################

resource "aws_acm_certificate" "arcanum_acm_cert01" {
  domain_name               = "arcanum-base.click"
  subject_alternative_names = ["app.arcanum-base.click"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-acm-cert01" }
}


# # EMAIL validation path (manual) — kept for compatibility.
# resource "aws_acm_certificate_validation" "arcanum_acm_validation01" {
#   certificate_arn = aws_acm_certificate.arcanum_acm_cert01.arn
#   # If using DNS validation, your DNS validation resource should exist elsewhere (bonus_b_route53.tf).
# }

############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> (Lab1 forward OR Lab2 deny+rule)
############################################

resource "aws_lb_listener" "arcanum_http_listener01" {
  load_balancer_arn = aws_lb.arcanum_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "arcanum_https_listener01" {
  load_balancer_arn = aws_lb.arcanum_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.arcanum_acm_cert01.arn

  # When origin cloaking is OFF: normal forward
  dynamic "default_action" {
    for_each = var.enable_origin_cloaking ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.arcanum_tg01.arn
    }
  }

  # When origin cloaking is ON: default deny
  dynamic "default_action" {
    for_each = var.enable_origin_cloaking ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        status_code  = "403"
        message_body = "Forbidden"
      }
    }
  }
}
############################################
# HTTP Listener Rule: allow CloudFront (secret header) to bypass redirect
############################################

resource "aws_lb_listener_rule" "arcanum_http_allow_cloudfront01" {
  listener_arn = aws_lb_listener.arcanum_http_listener01.arn
  priority     = 10

  condition {
    http_header {
      http_header_name = "X-arcanum-base"
      values           = ["OxjfYLsed3DkjwPYxcb1c9nxvhXz0Rry"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.arcanum_tg01.arn
  }
}


# Lab2: allow ONLY when CloudFront supplies the secret header.
# Requires local.origin_header_value to exist (usually from random_password in lab2 file).
# resource "aws_lb_listener_rule" "allow_cloudfront_only_secret_header" {
#   count        = var.enable_origin_cloaking ? 1 : 0
#   listener_arn = aws_lb_listener.arcanum_https_listener01.arn
#   priority     = 20

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.arcanum_tg01.arn
#   }

#   condition {
#     http_header {
#       http_header_name = local.origin_header_name
#       values           = [local.origin_header_value]
#     }
#   }
# }

############################################
# WAF (ALB-scoped) — Lab1. Lab2 moves WAF to CloudFront.
############################################

resource "aws_wafv2_web_acl" "arcanum_waf01" {
  count = var.enable_waf && !var.enable_origin_cloaking ? 1 : 0

  name  = "${var.project_name}-waf01"
  scope = "CLOUDFRONT"

  default_action {
    allow {
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf01"
    sampled_requests_enabled   = true
  }

  # Starter managed rule set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "arcanum_waf_assoc01" {
  count        = var.enable_waf && !var.enable_origin_cloaking ? 1 : 0
  resource_arn = aws_lb.arcanum_alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.arcanum_waf01[0].arn
}

############################################
# Monitoring: ALB 5xx Alarm
############################################

resource "aws_cloudwatch_metric_alarm" "arcanum_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.arcanum_alb01.arn_suffix
  }

  alarm_actions = [aws_sns_topic.arcanum_sns_topic01.arn]
}

############################################
# Dashboard
############################################

resource "aws_cloudwatch_dashboard" "arcanum_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.arcanum_alb01.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Requests + 5XX"
        }
      }
    ]
  })
}
