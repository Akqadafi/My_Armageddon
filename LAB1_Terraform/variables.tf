variable "aws_region" {
  description = "AWS Region for the arcanum fleet to patrol."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for naming. Students should change from 'arcanum' to their own."
  type        = string
  default     = "arcanum"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.0.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-0724302e25d16f8f2" # TODO
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "arcdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "Tahiro77!" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "akqadafi@gmail.com" # TODO: student supplies
}

variable "my_ip_cidr" {
  description = "Your device's IP in CIDR"
  type        = string
}

variable "storage_type" {
  default = "gp2"
  type    = string
}

############################################
# Bonus B variables (ALB + TLS + WAF + Monitoring)
############################################

variable "app_subdomain" {
  description = "Subdomain for the app (e.g., 'app' for app.example.com)."
  type        = string
  default     = "app"
}

variable "domain_name" {
  description = "Base domain hosted in Route53 (e.g., 'example.com')."
  type        = string
  default     = "arcanum-base.click" # <-- change this to your real domain
}

variable "certificate_validation_method" {
  description = "ACM certificate validation method. Use 'DNS' for Route53 automation."
  type        = string
  default     = "DNS"
  validation {
    condition     = contains(["DNS", "EMAIL"], upper(var.certificate_validation_method))
    error_message = "certificate_validation_method must be DNS or EMAIL."
  }
}

variable "enable_waf" {
  description = "Whether to create and attach WAFv2 Web ACL to the ALB."
  type        = bool
  default     = true
}

# Alarm tuning (reasonable defaults)
variable "alb_5xx_evaluation_periods" {
  description = "How many periods to evaluate before alarming."
  type        = number
  default     = 1
}

variable "alb_5xx_threshold" {
  description = "5XX count threshold to trigger alarm."
  type        = number
  default     = 5
}

variable "alb_5xx_period_seconds" {
  description = "Alarm period in seconds."
  type        = number
  default     = 300
}

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}


variable "enable_https" {
  description = "Enable HTTPS listener (requires validated ACM cert / DNS validation)."
  type        = bool
  default     = false
}
variable "route53_hosted_zone_id" {
  description = "Hosted Zone ID when manage_route53_in_terraform=false"
  type        = string
  default     = ""

  validation {
    condition     = var.manage_route53_in_terraform || length(var.route53_hosted_zone_id) > 0
    error_message = "You must provide route53_hosted_zone_id when manage_route53_in_terraform=false."
  }
}
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

variable "alb_logs_bucket_name" {
  description = "Optional override: explicit S3 bucket name for ALB logs. If null, a default is generated."
  type        = string
  default     = null

}
variable "enable_origin_cloaking" {
  description = "Lab 2: lock ALB to CloudFront + require secret header"
  type        = bool
  default     = true
}
variable "cloudfront_acm_cert_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (covers arcanum-base.com and app.arcanum-base.com)."
  type        = string
}

variable "enable_cloudfront_frontdoor" {
  description = "Enable CloudFront distribution in front of ALB."
  type        = bool
  default     = false
}
variable "alb_allow_public_http_https" {
  description = "If true, ALB allows public HTTP/HTTPS ingress (Lab 1). If false, ALB is locked down for CloudFront only (Lab 2)."
  type        = bool
  default     = true
}
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}
variable "enable_waf_redaction" {
  type    = bool
  default = true
}
