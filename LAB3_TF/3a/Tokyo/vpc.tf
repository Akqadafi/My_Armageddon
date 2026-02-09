############################################
# Locals (naming convention: shibuya-*)
############################################
locals {
  name_prefix = var.project_name
  ports_http  = 80
  ports_ssh   = 22
  ports_https = 443
  # ports_dns = 53
  db_port        = 3306
  tcp_protocol   = "tcp"
  udp_protocol   = "udp"
  all_ip_address = "0.0.0.0/0"
  # For AWS SG rules, "all protocols" is represented by ip_protocol = "-1".
  # When ip_protocol = "-1", AWS expects from_port/to_port to be 0.
  all_ports    = 0
  all_protocol = "-1"
}

############################################
# VPC + Internet Gateway
############################################

# Explanation: satellite needs a hyperlane—this VPC is the Millennium Falcon’s flight corridor.
resource "aws_vpc" "shibuya_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "shibuya_igw01" {
  vpc_id = aws_vpc.shibuya_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "shibuya_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.shibuya_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are the hidden Rebel base—no direct access from the internet.
resource "aws_subnet" "shibuya_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.shibuya_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]



  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# Explanation: satellite wants the private base to call home—EIP gives the NAT a stable “holonet address.”
resource "aws_eip" "_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# Explanation: NAT is satellite’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "shibuya_nat01" {
  allocation_id = aws_eip._nat_eip01.id
  subnet_id     = aws_subnet.shibuya_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.shibuya_igw01]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "_public_rt01" {
  vpc_id = aws_vpc.shibuya_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "shibuya_public_default_route" {
  route_table_id         = aws_route_table._public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shibuya_igw01.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "shibuya_public_rta" {
  count          = length(aws_subnet.shibuya_public_subnets)
  subnet_id      = aws_subnet.shibuya_public_subnets[count.index].id
  route_table_id = aws_route_table._public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "_private_rt01" {
  vpc_id = aws_vpc.shibuya_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Explanation: Private subnets route outbound internet via NAT (satellite-approved stealth).
resource "aws_route" "shibuya_private_default_route" {
  route_table_id         = aws_route_table._private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.shibuya_nat01.id
}

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "shibuya_private_rta" {
  count          = length(aws_subnet.shibuya_private_subnets)
  subnet_id      = aws_subnet.shibuya_private_subnets[count.index].id
  route_table_id = aws_route_table._private_rt01.id
}
