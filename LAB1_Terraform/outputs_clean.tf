############################################
# outputs.tf — CLEAN (Core + Bonus A + Bonus B)
############################################

############################################
# Core networking + app resources
############################################

output "arcanum_region" {
  description = "AWS region used by this deployment"
  value       = var.aws_region
}

output "arcanum_vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.arcanum_vpc01.id
}

output "arcanum_public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.arcanum_public_subnets[*].id
}

output "arcanum_private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.arcanum_private_subnets[*].id
}

output "arcanum_private_subnet_id" {
  description = "Primary private subnet (index 0) used for private EC2 + endpoints"
  value       = aws_subnet.arcanum_private_subnets[0].id
}

output "arcanum_ec2_instance_id" {
  description = "Public EC2 instance ID (if you have one)"
  value       = aws_instance.arcanum_ec201.id
}

output "arcanum_rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.arcanum_rds01.address
}

output "lab_secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.arcanum_db_secret01.name
}

output "lab_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.arcanum_db_secret01.arn
}

output "arcanum_sns_topic_arn" {
  description = "SNS topic ARN for incidents"
  value       = aws_sns_topic.arcanum_sns_topic01.arn
}

output "arcanum_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.arcanum_log_group01.name
}

############################################
# Bonus A — Private EC2 + VPC Endpoints
############################################

output "arcanum_private_instance_id" {
  description = "Private EC2 instance ID (Session Manager target)"
  value       = aws_instance.arc_bonus_ec2.id
}

output "arcanum_private_instance_private_ip" {
  description = "Private EC2 private IP"
  value       = aws_instance.arc_bonus_ec2.private_ip
}

output "arcanum_private_instance_iam_instance_profile" {
  description = "Instance profile attached to private EC2"
  value       = aws_instance.arc_bonus_ec2.iam_instance_profile
}

output "arcanum_ssm_start_session_command" {
  description = "Command to open an SSM Session Manager shell"
  value       = "aws ssm start-session --target ${aws_instance.arc_bonus_ec2.id} --region ${var.aws_region}"
}

output "arcanum_vpce_security_group_id" {
  description = "Security group applied to Interface VPC Endpoints"
  value       = aws_security_group.arc_bonus_a_vpce_sg01.id
}

output "arcanum_private_ec2_security_group_ids" {
  description = "Security group IDs attached to the private EC2"
  value       = aws_instance.arc_bonus_ec2.vpc_security_group_ids
}

############################################
# VPC Endpoints — IDs (canonical set)
############################################

output "vpce_s3_gateway_id" {
  description = "S3 Gateway VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_s3_gw01.id
}

output "vpce_sts_id" {
  description = "STS Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_sts01.id
}

output "vpce_ssm_id" {
  description = "SSM Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_ssm01.id
}

output "vpce_ec2messages_id" {
  description = "EC2Messages Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_ec2messages01.id
}

output "vpce_ssmmessages_id" {
  description = "SSMMessages Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_ssmmessages01.id
}

output "vpce_logs_id" {
  description = "CloudWatch Logs Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_logs01.id
}

output "vpce_secretsmanager_id" {
  description = "Secrets Manager Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_secrets01.id
}

output "vpce_kms_id" {
  description = "KMS Interface VPC Endpoint ID"
  value       = aws_vpc_endpoint.arcanum_vpce_kms01.id
}

############################################
# VPC Endpoints — DNS entries (verification helpers)
############################################

output "vpce_sts_dns_entries" {
  description = "STS Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_sts01.dns_entry
}

output "vpce_ssm_dns_entries" {
  description = "SSM Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_ssm01.dns_entry
}

output "vpce_ec2messages_dns_entries" {
  description = "EC2Messages Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_ec2messages01.dns_entry
}

output "vpce_ssmmessages_dns_entries" {
  description = "SSMMessages Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_ssmmessages01.dns_entry
}

output "vpce_logs_dns_entries" {
  description = "CloudWatch Logs Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_logs01.dns_entry
}

output "vpce_secretsmanager_dns_entries" {
  description = "Secrets Manager Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_secrets01.dns_entry
}

output "vpce_kms_dns_entries" {
  description = "KMS Interface endpoint DNS entries"
  value       = aws_vpc_endpoint.arcanum_vpce_kms01.dns_entry
}

############################################
# IAM + policies
############################################

output "arcanum_role_name" {
  description = "Role name used by EC2"
  value       = aws_iam_role.arcanum_ec2_role01.name
}

output "arcanum_instance_profile_name" {
  description = "Instance profile created for private EC2"
  value       = aws_iam_instance_profile.arc_bonus_ec2.name
}

output "arcanum_lp_params_policy_arn" {
  description = "Least-privilege SSM Parameter Store read policy ARN"
  value       = aws_iam_policy.arcanum_leastpriv_read_params01.arn
}

output "arcanum_lp_secret_policy_arn" {
  description = "Least-privilege Secrets Manager read policy ARN"
  value       = aws_iam_policy.arcanum_leastpriv_read_secret01.arn
}

output "arcanum_lp_cwlogs_policy_arn" {
  description = "Least-privilege CloudWatch Logs write policy ARN"
  value       = aws_iam_policy.arcanum_leastpriv_cwlogs01.arn
}

output "arcanum_secret_arn_guess" {
  description = "Wildcard guess for the secret ARN (use real ARN after apply)"
  value       = local.arcanum_secret_arn_guess
}

############################################
# Bonus B — ALB + TLS + WAF + Route53 + Monitoring
############################################

output "arcanum_alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.arcanum_alb01.dns_name
}

output "arcanum_app_fqdn" {
  description = "App FQDN (e.g., app.arcanum-base.click)"
  value       = "${var.app_subdomain}.${var.domain_name}"
}

output "arcanum_target_group_arn" {
  description = "Target group ARN for the ALB forward action"
  value       = aws_lb_target_group.arcanum_tg01.arn
}

output "arcanum_acm_cert_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.arcanum_acm_cert01.arn
}

output "arcanum_waf_arn" {
  value = "${length(aws_wafv2_web_acl.arcanum_waf01) > 0 ? aws_wafv2_web_acl.arcanum_waf01[0].arn : null}"
}

output "arcanum_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.arcanum_dashboard01.dashboard_name
}

output "arcanum_route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.arcanum_zone_id
}

output "arcanum_app_url_https" {
  description = "App HTTPS URL"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

# output "arcanum_apex_url_https" {
#   description = "Apex HTTPS URL"
#   value       = "https://${var.domain_name}"
# }

# output "arcanum_alb_logs_bucket_name" {
#   description = "ALB access logs bucket name (null if disabled)"
#   value       = var.enable_alb_access_logs ? aws_s3_bucket.arcanum_alb_logs01[0].bucket : null
# }

output "arcanum_origin_header_value" {
  description = "Origin cloaking header value (sensitive, null if disabled)"
  value       = var.enable_origin_cloaking ? random_password.arcanum_origin_header_value01.result : null
  sensitive   = true
}
output "arcanum_alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.arcanum_alb01.arn
}
output "arcanum_http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.arcanum_http_listener01.arn
}

output "arcanum_https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.arcanum_https_listener01.arn
}

output "arcanum_target_group_name" {
  description = "Target group name"
  value       = aws_lb_target_group.arcanum_tg01.name
}
# Explanation: The apex URL is the front gate—humans type this when they forget subdomains.
output "arcanum_apex_url_https" {
  value = "https://${var.domain_name}"
}

# Explanation: Log bucket name is where the footprints live—useful when hunting 5xx or WAF blocks.
output "arcanum_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.arcanum_alb_logs_bucket01[0].bucket : null
}
output "arcanum_cf_waf_arn" {
  description = "CloudFront-scoped WAF ARN"
  value       = try(aws_wafv2_web_acl.arcanum_cf_waf01.arn, null)
}
output "arcanum_cf_domain_name" {
  description = "CloudFront domain name"
  value       = try(aws_cloudfront_distribution.arcanum_cf01.domain_name, null)
}

output "arcanum_cf_distribution_id" {
  description = "CloudFront distribution ID"
  value       = try(aws_cloudfront_distribution.arcanum_cf01.id, null)
}

output "arcanum_waf_log_destination" {
  value = var.waf_log_destination
}

output "arcanum_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.arcanum_waf_log_group01[0].name : null
}

output "arcanum_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.arcanum_waf_logs_bucket01[0].bucket : null
}

output "arcanum_waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.arcanum_waf_firehose01[0].name : null
}



############################################
# outputs.tf — CLEAN (Core + Bonus A + Bonus B)
############################################

############################################
# Core networking + app resources
############################################

# output "arcanum_region" {
#   description = "AWS region used by this deployment"
#   value       = var.aws_region
# }

# output "arcanum_vpc_id" {
#   description = "VPC ID"
#   value       = aws_vpc.arcanum_vpc01.id
# }

# output "arcanum_public_subnet_ids" {
#   description = "Public subnet IDs"
#   value       = aws_subnet.arcanum_public_subnets[*].id
# }

# output "arcanum_private_subnet_ids" {
#   description = "Private subnet IDs"
#   value       = aws_subnet.arcanum_private_subnets[*].id
# }

# output "arcanum_private_subnet_id" {
#   description = "Primary private subnet (index 0) used for private EC2 + endpoints"
#   value       = aws_subnet.arcanum_private_subnets[0].id
# }

# output "arcanum_ec2_instance_id" {
#   description = "Public EC2 instance ID (if you have one)"
#   value       = aws_instance.arcanum_ec201.id
# }

# output "arcanum_rds_endpoint" {
#   description = "RDS endpoint address"
#   value       = aws_db_instance.arcanum_rds01.address
# }

# output "lab_secret_name" {
#   description = "Secrets Manager secret name"
#   value       = aws_secretsmanager_secret.arcanum_db_secret01.name
# }

# output "lab_secret_arn" {
#   description = "Secrets Manager secret ARN"
#   value       = aws_secretsmanager_secret.arcanum_db_secret01.arn
# }

# output "arcanum_sns_topic_arn" {
#   description = "SNS topic ARN for incidents"
#   value       = aws_sns_topic.arcanum_sns_topic01.arn
# }

# output "arcanum_log_group_name" {
#   description = "CloudWatch log group name"
#   value       = aws_cloudwatch_log_group.arcanum_log_group01.name
# }

# ############################################
# # Bonus A — Private EC2 + VPC Endpoints
# ############################################

# output "arcanum_private_instance_id" {
#   description = "Private EC2 instance ID (Session Manager target)"
#   value       = aws_instance.arc_bonus_ec2.id
# }

# output "arcanum_private_instance_private_ip" {
#   description = "Private EC2 private IP"
#   value       = aws_instance.arc_bonus_ec2.private_ip
# }

# output "arcanum_private_instance_iam_instance_profile" {
#   description = "Instance profile attached to private EC2"
#   value       = aws_instance.arc_bonus_ec2.iam_instance_profile
# }

# output "arcanum_ssm_start_session_command" {
#   description = "Command to open an SSM Session Manager shell"
#   value       = "aws ssm start-session --target ${aws_instance.arc_bonus_ec2.id} --region ${var.aws_region}"
# }

# output "arcanum_vpce_security_group_id" {
#   description = "Security group applied to Interface VPC Endpoints"
#   value       = aws_security_group.arcanum_vpce_sg01.id
# }

# output "arcanum_private_ec2_security_group_ids" {
#   description = "Security group IDs attached to the private EC2"
#   value       = aws_instance.arc_bonus_ec2.vpc_security_group_ids
# }

# ############################################
# # VPC Endpoints — IDs (canonical set)
# ############################################

# output "vpce_s3_gateway_id" {
#   description = "S3 Gateway VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_s3_gw01.id
# }

# output "vpce_sts_id" {
#   description = "STS Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_sts01.id
# }

# output "vpce_ssm_id" {
#   description = "SSM Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_ssm01.id
# }

# output "vpce_ec2messages_id" {
#   description = "EC2Messages Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_ec2messages01.id
# }

# output "vpce_ssmmessages_id" {
#   description = "SSMMessages Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_ssmmessages01.id
# }

# output "vpce_logs_id" {
#   description = "CloudWatch Logs Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_logs01.id
# }

# output "vpce_secretsmanager_id" {
#   description = "Secrets Manager Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_secrets01.id
# }

# output "vpce_kms_id" {
#   description = "KMS Interface VPC Endpoint ID"
#   value       = aws_vpc_endpoint.arcanum_vpce_kms01.id
# }

# ############################################
# # VPC Endpoints — DNS entries (verification helpers)
# ############################################

# output "vpce_sts_dns_entries" {
#   description = "STS Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_sts01.dns_entry
# }

# output "vpce_ssm_dns_entries" {
#   description = "SSM Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_ssm01.dns_entry
# }

# output "vpce_ec2messages_dns_entries" {
#   description = "EC2Messages Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_ec2messages01.dns_entry
# }

# output "vpce_ssmmessages_dns_entries" {
#   description = "SSMMessages Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_ssmmessages01.dns_entry
# }

# output "vpce_logs_dns_entries" {
#   description = "CloudWatch Logs Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_logs01.dns_entry
# }

# output "vpce_secretsmanager_dns_entries" {
#   description = "Secrets Manager Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_secrets01.dns_entry
# }

# output "vpce_kms_dns_entries" {
#   description = "KMS Interface endpoint DNS entries"
#   value       = aws_vpc_endpoint.arcanum_vpce_kms01.dns_entry
# }

# ############################################
# # IAM + policies
# ############################################

# output "arcanum_role_name" {
#   description = "Role name used by EC2"
#   value       = aws_iam_role.arcanum_ec2_role01.name
# }

# output "arcanum_instance_profile_name" {
#   description = "Instance profile created for private EC2"
#   value       = aws_iam_instance_profile.arc_bonus_ec2.name
# }

# output "arcanum_lp_params_policy_arn" {
#   description = "Least-privilege SSM Parameter Store read policy ARN"
#   value       = aws_iam_policy.arcanum_leastpriv_read_params01.arn
# }

# output "arcanum_lp_secret_policy_arn" {
#   description = "Least-privilege Secrets Manager read policy ARN"
#   value       = aws_iam_policy.arcanum_leastpriv_read_secret01.arn
# }

# output "arcanum_lp_cwlogs_policy_arn" {
#   description = "Least-privilege CloudWatch Logs write policy ARN"
#   value       = aws_iam_policy.arcanum_leastpriv_cwlogs01.arn
# }

# output "arcanum_secret_arn_guess" {
#   description = "Wildcard guess for the secret ARN (use real ARN after apply)"
#   value       = local.arcanum_secret_arn_guess
# }

# ############################################
# # Bonus B — ALB + TLS + WAF + Route53 + Monitoring
# ############################################

# output "arcanum_alb_dns_name" {
#   description = "ALB DNS name"
#   value       = aws_lb.arcanum_alb01.dns_name
# }

# output "arcanum_app_fqdn" {
#   description = "App FQDN (e.g., app.arcanum-base.click)"
#   value       = "${var.app_subdomain}.${var.domain_name}"
# }

# output "arcanum_target_group_arn" {
#   description = "Target group ARN for the ALB forward action"
#   value       = aws_lb_target_group.arcanum_tg01.arn
# }

# output "arcanum_acm_cert_arn" {
#   description = "ACM certificate ARN"
#   value       = aws_acm_certificate.arcanum_acm_cert01.arn
# }

# output "arcanum_waf_arn" {
#   description = "WAF Web ACL ARN (null if WAF disabled)"
#   value       = var.enable_waf ? aws_wafv2_web_acl.arcanum_waf01[0].arn : null
# }

# output "arcanum_dashboard_name" {
#   description = "CloudWatch dashboard name"
#   value       = aws_cloudwatch_dashboard.arcanum_dashboard01.dashboard_name
# }

# output "arcanum_route53_zone_id" {
#   description = "Route53 hosted zone ID"
#   value       = local.arcanum_zone_id
# }

# output "arcanum_app_url_https" {
#   description = "App HTTPS URL"
#   value       = "https://${var.app_subdomain}.${var.domain_name}"
# }

# output "arcanum_apex_url_https" {
#   description = "Apex HTTPS URL"
#   value       = "https://${var.domain_name}"
# }

# output "arcanum_alb_logs_bucket_name" {
#   description = "ALB access logs bucket name (null if disabled)"
#   value       = var.enable_alb_access_logs ? aws_s3_bucket.arcanum_alb_logs_bucket01[0].bucket : null
# }

# output "arcanum_origin_header_value" {
#   description = "Origin cloaking header value (sensitive, null if disabled)"
#   value       = var.enable_origin_cloaking ? random_password.arcanum_origin_header_value01.result : null
#   sensitive   = true
# }
