############################################
# Security Group: EC2 (SSM + outbound)
############################################
resource "aws_security_group" "shibuya_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 security group (SSM access only)"
  vpc_id      = aws_vpc.shibuya_vpc01.id

  # No ingress rules needed for SSM

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

############################################
# IAM Role + Instance Profile (SSM + Secrets + CW optional)
############################################
resource "aws_iam_role" "shibuya_ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Required for Session Manager
resource "aws_iam_role_policy_attachment" "shibuya_ec2_ssm_attach" {
  role       = aws_iam_role.shibuya_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow EC2 to read ONE specific secret (optional but you’re using it in user_data)
resource "aws_iam_policy" "shibuya_secrets_policy" {
  name        = "${local.name_prefix}-secrets-policy"
  description = "Allow EC2 to read the DB secret from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSpecificSecret"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.shibuya_db_secret01.arn,
          "${aws_secretsmanager_secret.shibuya_db_secret01.arn}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "shibuya_ec2_secrets_attach" {
  role       = aws_iam_role.shibuya_ec2_role01.name
  policy_arn = aws_iam_policy.shibuya_secrets_policy.arn
}

# CloudWatch Agent policy (optional)
resource "aws_iam_role_policy_attachment" "shibuya_ec2_cw_attach" {
  role       = aws_iam_role.shibuya_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "shibuya_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.shibuya_ec2_role01.name
}

############################################
# EC2 Instance (Private subnet)
############################################
resource "aws_instance" "shibuya_ec2_private03" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.shibuya_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.shibuya_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.shibuya_instance_profile01.name

  associate_public_ip_address = false

  # Uncomment when ready
  user_data                   = file("${path.module}/1a_user_data.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${local.name_prefix}-ec2-private03"
  }
}