# # Explanation: Shinjuku returns traffic to Liberdade—doctors need answers, not one-way tunnels.
# resource "aws_route" "shibuya_to_liberdade_route01" {
#   route_table_id         = aws_route_table._private_rt01.id
#   destination_cidr_block = var.saopaulo_vpc_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.shibuya_tgw01.id
# }

# # resource "aws_route" "shibuya_rds_subnet_to_saopaulo" {
# #   route_table_id         = aws_route_table._private_rt01.id
# #   destination_cidr_block = var.saopaulo_vpc_cidr  # 10.1.0.0/16
# #   transit_gateway_id     = aws_ec2_transit_gateway.shibuya_tgw01.id
# # }