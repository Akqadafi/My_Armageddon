# # Explanation: Shibuya Station is the hub—Tokyo is the data authority.
# resource "aws_ec2_transit_gateway" "shibuya_tgw01" {
#   description                     = "shibuya-tgw01 (Tokyo hub)"
#   default_route_table_association = "disable"
#   default_route_table_propagation = "disable"
#   tags                            = { Name = "shibuya-tgw01" }
# }

# resource "aws_ec2_transit_gateway_route_table" "shibuya_tgw_rt01" {
#   transit_gateway_id = aws_ec2_transit_gateway.shibuya_tgw01.id
#   tags               = { Name = "shibuya-tgw-rt01" }
# }

# # Explanation: Shibuya connects to the Tokyo VPC—this is the gate to the medical records vault.
# resource "aws_ec2_transit_gateway_vpc_attachment" "shibuya_attach_tokyo_vpc01" {
#   transit_gateway_id                              = aws_ec2_transit_gateway.shibuya_tgw01.id
#   vpc_id                                          = aws_vpc.shibuya_vpc01.id
#   subnet_ids                                      = [aws_subnet.shibuya_private_subnets[0].id, aws_subnet.shibuya_private_subnets[1].id]
#   transit_gateway_default_route_table_association = false
#   transit_gateway_default_route_table_propagation = false
#   tags                                            = { Name = "shibuya-attach-tokyo-vpc01" }
# }

# resource "aws_ec2_transit_gateway_route_table_association" "shibuya_vpc_assoc01" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shibuya_attach_tokyo_vpc01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shibuya_tgw_rt01.id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "shibuya_vpc_prop01" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shibuya_attach_tokyo_vpc01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shibuya_tgw_rt01.id
# }

# # # create the peering attachment (Tokyo -> Sao Paulo)
# resource "aws_ec2_transit_gateway_peering_attachment" "shibuya_to_liberdade_peer01" {
#   transit_gateway_id      = aws_ec2_transit_gateway.shibuya_tgw01.id
#   peer_transit_gateway_id = var.saopaulo_tgw_id
#   peer_region             = "sa-east-1"

#   tags = { Name = "shibuya-to-liberdade-peer01" }
# }

# data "aws_ec2_transit_gateway_peering_attachment" "shibuya_to_liberdade_peer01" {
#   count = var.saopaulo_tgw_id == null ? 0 : 1
#   id    = aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01.id
# }

# locals {
#   shibuya_peer_state     = try(data.aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01[0].state, null)
#   shibuya_peer_available = local.shibuya_peer_state == "available"
# }

# # associate peering attachment with Tokyo TGW route table
# resource "aws_ec2_transit_gateway_route_table_association" "shibuya_peer_assoc01" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shibuya_tgw_rt01.id
# }

# # propagate peering attachment into Tokyo TGW route table
# resource "aws_ec2_transit_gateway_route_table_propagation" "shibuya_peer_prop01" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shibuya_tgw_rt01.id
# }

# # TGW route: Tokyo TGW knows how to reach Sao Paulo VPC CIDR via the peering attachment
# resource "aws_ec2_transit_gateway_route" "shibuya_to_liberdade_tgw_route01" {
#   destination_cidr_block         = var.saopaulo_vpc_cidr
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shibuya_tgw_rt01.id
# }
