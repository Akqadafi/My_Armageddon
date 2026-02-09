############################################
# Security Group: RDS (allow 3306 ONLY from EC2 SG)
############################################
resource "aws_security_group" "shibuya_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.shibuya_vpc01.id

  tags = { Name = "${local.name_prefix}-rds-sg01" }
}

# # Allow MySQL ONLY from Tokyo EC2 SG
# resource "aws_vpc_security_group_ingress_rule" "shibuya_rds_ingress_mysql_from_tokyo_ec2" {
#   security_group_id            = aws_security_group.shibuya_rds_sg01.id
#   ip_protocol                  = "tcp"
#   from_port                    = 3306
#   to_port                      = 3306
#   referenced_security_group_id = aws_security_group.shibuya_ec2_sg01.id
# }

# # Allow Sao Paulo VPC CIDR to reach Tokyo RDS (over TGW/peering routing)
# resource "aws_vpc_security_group_ingress_rule" "shibuya_rds_ingress_mysql_from_saopaulo" {
#   security_group_id = aws_security_group.shibuya_rds_sg01.id
#   ip_protocol       = "tcp"
#   from_port         = 3306
#   to_port           = 3306
#   cidr_ipv4         = var.saopaulo_vpc_cidr
# }

# # Egress (optional, but fine)
# resource "aws_vpc_security_group_egress_rule" "shibuya_rds_egress_all" {
#   security_group_id = aws_security_group.shibuya_rds_sg01.id
#   ip_protocol       = "-1"
#   cidr_ipv4         = "0.0.0.0/0"
# }