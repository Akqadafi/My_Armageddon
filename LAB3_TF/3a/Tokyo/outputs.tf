# ##
# These outputs are required for cross-region remote state consumption by SÃ£o Paulo.

# - tokyo_vpc_cidr: Used for TGW routing in SÃ£o Paulo
# - tokyo_rds_endpoint: Used for app/database connectivity from SÃ£o Paulo

output "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR for cross-region routing"
  value       = aws_vpc.shibuya_vpc01.cidr_block
}

output "tokyo_rds_endpoint" {
  description = "Tokyo RDS endpoint for remote access"
  value       = aws_db_instance.shibuya_rds01.address
}

# output "tokyo_tgw_id" {
#   description = "Tokyo Transit Gateway ID for cross-region peering"
#   value       = aws_ec2_transit_gateway.shibuya_tgw01.id
# }

# output "tokyo_tgw_peering_attachment_id" {
#   value = aws_ec2_transit_gateway_peering_attachment.shibuya_to_liberdade_peer01.id
# }

output "rds_endpoint" {
  value = aws_db_instance.shibuya_rds01.address
}

output "db_port" {
  value = aws_db_instance.shibuya_rds01.port
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.shibuya_db_secret01.name
}
