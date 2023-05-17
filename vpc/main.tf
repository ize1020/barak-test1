resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block

  tags = {
    "Name" = "Barak_Test_1"
  }
}

# SUBNETS
resource "aws_subnet" "public" {
  map_public_ip_on_launch = "true"
  count                   = length(var.public_subnets_cidr_list)
  cidr_block              = var.public_subnets_cidr_list[count.index]
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name" = "Public_subnet_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets_cidr_list)
  cidr_block              = var.private_subnets_cidr_list[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "false"
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name" = "Private_subnet_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "IGW_${aws_vpc.vpc.id}"
  }
}

# EIPs (for nats)
#resource "aws_eip" "eip" {
#  count = length(var.public_subnets_cidr_list)
#
#  tags = {
#    "Name" = "NAT_elastic_ip_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
#  }
#}

# NATs
#resource "aws_nat_gateway" "nat" {
#  count         = length(var.public_subnets_cidr_list)
#  allocation_id = aws_eip.eip.*.id[count.index]
#  subnet_id     = aws_subnet.public.*.id[count.index]
#
#  tags = {
#    "Name" = "NAT_${regex(".$", data.aws_availability_zones.available.names[count.index])}_${aws_vpc.vpc.id}"
#  }
#}

# ROUTING #
resource "aws_route_table" "route_tables" {
  count  = length(var.route_tables_name_list)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.route_tables_name_list[count.index]}_RTB_${aws_vpc.vpc.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr_list)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.route_tables[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr_list)
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.route_tables[count.index + 1].id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.route_tables[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private" {
  count                  = length(var.private_subnets_cidr_list)
  route_table_id         = aws_route_table.route_tables.*.id[count.index + 1]
  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.nat.*.id[count.index]
}

resource "aws_ec2_transit_gateway" "barak-concect" {
  description = "tgw to connect to barak main tgw"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach" {
  subnet_ids = [aws_subnet.public.id]
  transit_gateway_id = aws_ec2_transit_gateway.barak_connect.id
  vpc_id = module.vpc_module.vpc_id
}

resource "aws_ec2_transit_gateway_connect" "attachment" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_attach.id
  transit_gateway_id = aws_ec2_transit_gateway.barak_connect.id
}