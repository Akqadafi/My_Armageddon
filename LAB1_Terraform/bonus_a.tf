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


locals {
  arcanum_prefix = "arc_bonus_a"
  vpc_id         = aws_vpc.arcanum_vpc01.id
  private_subnet = aws_subnet.arcanum_private_subnets[0].id
  # For session manager endpoints, we'll use first private subnet
  endpoint_subnets         = aws_subnet.arcanum_private_subnets[*].id
  arcanum_secret_arn_guess = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.arcanum_self01.account_id}:secret:${local.arcanum_prefix}/rds/mysql*"
}

# Explanation: arcanum wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "arcanum_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "arcanum_region01" {}

# Amazon Linux 2023 AMI via SSM public parameter
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}





# # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
#   arcanum_secret_arn_guess = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.arcanum_self01.account_id}:secret:${local.arcanum_prefix}/rds/mysql*"
# # }

# ############################################
# Security Group for VPC Interface Endpoints
# ############################################

resource "aws_security_group" "arc_bonus_a_vpce_sg01" {
  name_prefix = "${local.arcanum_prefix}-vpce-sg01"
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

# ################################################################################
# # BONUS-A: Security Group for Private EC2
# ################################################################################

# resource "aws_security_group" "arc_bonus_a_sg01" {
#   name_prefix = "arc_bonus_a-ec2"
#   description = "SG for private EC2 outbound to endpoints and RDS"
#   vpc_id      = local.vpc_id

#   # No inbound rules allow Session Manager access

#   egress {
#     description     = "HTTPS to VPC endpoints"
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.arc_bonus_a_sg01.id]
#   }

#   # Allow RDS connectivity (to Lab 1a RDS in private subnet)
#   egress {
#     description = "MySQL to RDS (Lab 1a)"
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = var.private_subnet_cidrs
#   }

#   tags = {
#     Name = "${local.arcanum_prefix}-ec2-sg01"
#   }
# }

# ############################################
# # Move EC2 into PRIVATE subnet (no public IP)
# ############################################

resource "aws_iam_instance_profile" "arc_bonus_ec2" {
  name = "${local.arcanum_prefix}-instance-profile-private"
  role = aws_iam_role.arcanum_ec2_role01.name
}


# # Explanation: arcanum hates exposure—private subnets keep your compute off the public holonet.
resource "aws_instance" "arc_bonus_ec2" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.ec2_instance_type
  subnet_id                   = local.private_subnet
  vpc_security_group_ids      = [aws_security_group.arcanum_ec2_sg01.id]
  iam_instance_profile        = aws_iam_instance_profile.arc_bonus_ec2.name
  associate_public_ip_address = false # PRIVATE

  # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
  # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.
  user_data_replace_on_change = true
  user_data                   = file("${path.module}/1a_user_data.sh")

  depends_on = [aws_db_instance.arcanum_rds01]

  tags = {
    Name = "${local.arcanum_prefix}-ec2-private"
  }
}


# ############################################
# # VPC Endpoint - S3 (Gateway)
# ############################################

# # Explanation: S3 is the supply depot—without this, your private world starves (updates, artifacts, logs).
resource "aws_vpc_endpoint" "arcanum_vpce_s3_gw01" {
  vpc_id            = aws_vpc.arcanum_vpc01.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.arcanum_private_rt01.id
  ]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-s3-gw01"
  }
}

############################################
# VPC Endpoint - STS (Interface)
############################################

# Explanation: STS is how the instance refreshes its identity.
# Without this, IAM roles silently fail in private-only networks.
resource "aws_vpc_endpoint" "arcanum_vpce_sts01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-sts01"
  }
}

# ############################################
# # VPC Endpoints - SSM (Interface)
# ############################################

# # Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "arcanum_vpce_ssm01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-ssm01"
  }
}

# # Explanation: ec2messages is the Wookiee messenger—SSM sessions won’t work without it.
resource "aws_vpc_endpoint" "arcanum_vpce_ec2messages01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-ec2messages01"
  }
}

# # Explanation: ssmmessages is the holonet channel—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "arcanum_vpce_ssmmessages01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-ssmmessages01"
  }
}

# ############################################
# # VPC Endpoint - CloudWatch Logs (Interface)
# ############################################

# # Explanation: CloudWatch Logs is the ship’s black box—arcanum wants crash data, always.
resource "aws_vpc_endpoint" "arcanum_vpce_logs01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-logs01"
  }
}

# ############################################
# # VPC Endpoint - Secrets Manager (Interface)
# ############################################

# # Explanation: Secrets Manager is the locked vault—arcanum doesn’t put passwords on sticky notes.
resource "aws_vpc_endpoint" "arcanum_vpce_secrets01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-secrets01"
  }
}

# ############################################
# # Optional: VPC Endpoint - KMS (Interface)
# ############################################

# # Explanation: KMS is the encryption kyber crystal—arcanum prefers locked doors AND locked safes.
resource "aws_vpc_endpoint" "arcanum_vpce_kms01" {
  vpc_id              = aws_vpc.arcanum_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.endpoint_subnets
  security_group_ids = [aws_security_group.arc_bonus_a_vpce_sg01.id]

  tags = {
    Name = "${local.arcanum_prefix}-vpce-kms01"
  }
}

# ############################################
# # Least-Privilege IAM (BONUS A)
# ############################################

# # Explanation: arcanum doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "arcanum_leastpriv_read_params01" {
  name        = "${local.arcanum_prefix}-lp-ssm-read01"
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

# # Explanation: arcanum only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "arcanum_leastpriv_read_secret01" {
  name        = "${local.arcanum_prefix}-lp-secrets-read01"
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

# # Explanation: When the Falcon logs scream, this lets arcanum ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "arcanum_leastpriv_cwlogs01" {
  name        = "${local.arcanum_prefix}-lp-cwlogs01"
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

# # Explanation: Attach the scoped policies—arcanum loves power, but only the safe kind.
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