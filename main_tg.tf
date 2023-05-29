resource "aws_ec2_transit_gateway" "tg" {
  description                     = "Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = {
    Name = "${var.tg_name}-tg"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "rosa_tg_attach" {
  subnet_ids         = aws_subnet.rosa_private_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.tg.id
  vpc_id             = aws_vpc.rosa_vpc.id
  tags = {
    Name = "${var.rosa_attach}-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "ent_tg_attach" {
  subnet_ids         = aws_subnet.ent_private_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.tg.id
  vpc_id             = aws_vpc.ent_vpc.id
  tags = {
    Name = "${var.ent_attach}-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "net_tg_attach" {
  subnet_ids         = aws_subnet.net_private_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.tg.id
  vpc_id             = aws_vpc.net_vpc.id
  tags = {
    Name = "${var.net_attach}-attachment"
  }
}

resource "aws_ec2_transit_gateway_route" "def_net_tg_attach" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.net_tg_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tg.association_default_route_table_id
}


