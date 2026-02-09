# Explanation: Tokyo vault opens only to approved clinics Liberdade gets DB access, the public gets nothing.
resource "aws_security_group_rule" "shibuya_rds_ingress_from_liberdade01" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  security_group_id = aws_security_group.shibuya_rds_sg01.id
  cidr_blocks       = [var.saopaulo_vpc_cidr]
}
