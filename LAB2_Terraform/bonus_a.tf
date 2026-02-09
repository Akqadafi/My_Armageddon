# ############################################
# # Bonus A - Data + Locals
# ############################################

# Architecture: 
#   - Private EC2 (no public IP)
#   - VPC Interface Endpoints for SSM, EC2Messages, SSMMessages, CloudWatch Logs, 
#     Secrets Manager, KMS
#   - S3 Gateway Endpoint for yum/apt repos (if needed)
#   - Least-privilege IAM: scoped to specific secrets and parameter paths
#   - Session Manager for shell access (no SSH required)
#
# Real-world alignment:
#   - Matches regulated orgs (finance, healthcare, government)
#   - Reduces NAT complexity and dependency
#   - Eliminates internet exposure for compute
#   - Least-privilege follows security baseline (CIS, SOC2)


############################################
# BONUS A (CORE) — rewritten to STOP destroys
# Key fixes:
# - Use the ORIGINAL SG address: aws_security_group.arc_bonus_a_vpce_sg01
# - Use name_prefix (NOT name) so Terraform doesn't try to replace the existing SG
# - Remove/avoid any moved {} blocks
# - Do NOT redeclare aws_caller_identity if it already exists in CORE
# - Fix CW Logs policy Resource (no nested list)
############################################

locals {
  arcanum_prefix = "arc_bonus_a"

  vpc_id             = aws_vpc.arcanum_vpc01.id
  private_subnet_ids = aws_subnet.arcanum_private_subnets[*].id
  private_subnet_id  = local.private_subnet_ids[0]
  endpoint_subnets   = [local.private_subnet_id]
  private_rt_id      = aws_route_table.arcanum_private_rt01.id

  # relies on an existing data "aws_caller_identity" "arcanum_self01" defined elsewhere in CORE
  arcanum_secret_arn_guess = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.arcanum_self01.account_id}:secret:${local.arcanum_prefix}/rds/mysql*"
}

# IMPORTANT: Do NOT uncomment this if it already exists elsewhere in CORE
# data "aws_caller_identity" "arcanum_self01" {}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

############################################
# Security Group for VPC Interface Endpoints
############################################
# IMPORTANT: Keep the ORIGINAL resource NAME (address) so state matches.
# Use name_prefix so SG doesn't get replaced due to name drift.
resource "aws_security_group" "arc_bonus_a_vpce_sg01" {
  name_prefix = "arc_bonus_a-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "arcanum_vpce_sg_ingress_https_from_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.arc_bonus_a_vpce_sg01.id
  source_security_group_id = aws_security_group.arcanum_ec2_sg01.id
}

resource "aws_security_group_rule" "arcanum_vpce_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.arc_bonus_a_vpce_sg01.id
  description       = "Allow all outbound - endpoints receive only"
}

############################################
# IAM Instance Profile (keep name stable)
############################################
resource "aws_iam_instance_profile" "arc_bonus_ec2" {
  name = "arc_bonus_a-instance-profile-private"
  role = aws_iam_role.arcanum_ec2_role01.name
}

############################################
# Least-Privilege IAM Policies
############################################
resource "aws_iam_policy" "arcanum_leastpriv_read_params01" {
  name        = "arc_bonus_a-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.arcanum_self01.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "arcanum_leastpriv_read_secret01" {
  name        = "arc_bonus_a-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.arcanum_secret_arn_guess
      }
    ]
  })
}

resource "aws_iam_policy" "arcanum_leastpriv_cwlogs01" {
  name        = "arc_bonus_a-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.arcanum_log_group01.arn}:*"
        ]
      }
    ]
  })
}

############################################
# Attach policies to the EC2 role
############################################
resource "aws_iam_role_policy_attachment" "arcanum_attach_lp_params01" {
  role       = aws_iam_role.arcanum_ec2_role01.name
  policy_arn = aws_iam_policy.arcanum_leastpriv_read_params01.arn
}

resource "aws_iam_role_policy_attachment" "arcanum_attach_lp_secret01" {
  role       = aws_iam_role.arcanum_ec2_role01.name
  policy_arn = aws_iam_policy.arcanum_leastpriv_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "arcanum_attach_lp_cwlogs01" {
  role       = aws_iam_role.arcanum_ec2_role01.name
  policy_arn = aws_iam_policy.arcanum_leastpriv_cwlogs01.arn
}

############################################
# Private EC2 (no public IP) + TG attachment
############################################
resource "aws_instance" "arc_bonus_ec2" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.ec2_instance_type
  subnet_id                   = local.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.arcanum_ec2_sg01.id]
  iam_instance_profile        = aws_iam_instance_profile.arc_bonus_ec2.name
  associate_public_ip_address = false

  user_data_replace_on_change = true
  user_data                   = file("${path.module}/1a_user_data.sh")

  tags = {
    Name = "${local.arcanum_prefix}-ec2-private"
  }
}

resource "aws_lb_target_group_attachment" "arcanum_tg_attach01" {
  target_group_arn = aws_lb_target_group.arcanum_tg01.arn
  target_id        = aws_instance.arc_bonus_ec2.id
  port             = 80
}

############################################
# VPC Endpoint - S3 (Gateway)
############################################
resource "aws_vpc_endpoint" "arcanum_vpce_s3_gw01" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.arcanum_private_rt01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-s3-gw01"
  }
}

############################################
# VPC Endpoints (Interface): STS, SSM, EC2Messages, SSMMessages, Logs, Secrets, KMS
############################################
resource "aws_vpc_endpoint" "arcanum_vpce_sts01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-sts01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_ssm01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-ssm01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_ec2messages01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-ec2messages01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_ssmmessages01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-ssmmessages01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_logs01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-logs01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_secrets01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-secrets01" }
}

resource "aws_vpc_endpoint" "arcanum_vpce_kms01" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = { Name = "${local.arcanum_prefix}-vpce-kms01" }
}