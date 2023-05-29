## Create VPCs
resource "aws_vpc" "rosa_vpc" {
  cidr_block           = local.rosa_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${local.rosa_vpc_name}"
  }
}

##Create Private Subnets
resource "aws_subnet" "rosa_private_subnets" {
  count                   = local.rosa_subnet_count
  vpc_id                  = aws_vpc.rosa_vpc.id
  cidr_block              = cidrsubnet("${local.rosa_vpc_cidr_block}", "${local.rosa_newbits}", "${count.index}")
  availability_zone       = var.rosa_priv_subnet_azs[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.rosa_env}-private-subnet-${var.rosa_priv_subnet_azs[count.index]}"
  }
}

resource "aws_security_group" "rosa_vpc_endpoint_inboud_sg" {
  name        = "vpc_route53_inboud_endpoint"
  description = "Allow inbound DNS Requestes"
  vpc_id      = aws_vpc.rosa_vpc.id
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "tcp"
    cidr_blocks = [
      local.ent_vpc_cidr_block
      , local.net_vpc_cidr_block
    ]
  }
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    cidr_blocks = [
      local.ent_vpc_cidr_block
      , local.net_vpc_cidr_block
    ]
  }
  tags = {
    Name = "${var.rosa_env}-vpc_route53_inboud_endpoint-sg"
  }
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "${var.rosa_env}-inbound-endpoint"
  direction = "INBOUND"
  security_group_ids = [
    aws_security_group.rosa_vpc_endpoint_inboud_sg.id
  ]
  dynamic "ip_address" {
    for_each = aws_subnet.rosa_private_subnets[*].id
    iterator = subnet

    content {
      subnet_id = subnet.value
    }
  }
  tags = {
    Name = "${var.rosa_env}-inbound-endpoint"
  }
}

# Add Table
resource "aws_route" "rosa_rt_tgw" {
  route_table_id         = aws_vpc.rosa_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tg.id
}