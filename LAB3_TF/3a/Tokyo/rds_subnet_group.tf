resource "aws_db_subnet_group" "shibuya_rds_subnets" {
  name       = "${local.name_prefix}-rds-subnets"
  subnet_ids = aws_subnet.shibuya_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnets"
  }
}

# resource "aws_route" "shibuya_rds_subnet_to_saopaulo" {
#   route_table_id         = "rtb-094e1e6c78b9ac307"
#   destination_cidr_block = var.saopaulo_vpc_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.shibuya_tgw01.id
# }