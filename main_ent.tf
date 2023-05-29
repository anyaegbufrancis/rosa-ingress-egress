## Create VPC
resource "aws_vpc" "ent_vpc" {
  cidr_block           = local.ent_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "false"
  enable_dns_support   = "false"
  tags = {
    Name = "${local.ent_vpc_name}"
  }
}

## Create private subnet
resource "aws_subnet" "ent_private_subnets" {
  count                   = local.ent_subnet_count
  vpc_id                  = aws_vpc.ent_vpc.id
  cidr_block              = cidrsubnet("${local.ent_vpc_cidr_block}", "${local.ent_newbits}", "${count.index}")
  availability_zone       = var.ent_priv_subnet_azs[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.ent_env}-private-subnet-${var.ent_priv_subnet_azs[count.index]}"
  }
}

## Create EC2 Instance for Public Subnet
resource "aws_security_group" "windows_vpc_ec2_sg" {
  name        = "ad-dns-svc"
  description = "Allow inbound to AD"
  vpc_id      = aws_vpc.ent_vpc.id
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "tcp"
    cidr_blocks = [
      local.rosa_vpc_cidr_block
      , local.net_vpc_cidr_block
    ]
  }
  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    cidr_blocks = [
      local.rosa_vpc_cidr_block
      , local.net_vpc_cidr_block
    ]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "tcp"
    cidr_blocks = [
      local.rosa_vpc_cidr_block
      , local.net_vpc_cidr_block
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.ent_env}-${var.windows_instance_name}-sg"
  }
}

## Deploy Windows servers
resource "aws_instance" "windows" {
  ami                         = var.windows_ami
  instance_type               = var.windows_instance_type
  associate_public_ip_address = false
  #key_name                    = random_string.random.result
  subnet_id              = aws_subnet.ent_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.windows_vpc_ec2_sg.id]

  tags = {
    Name = var.windows_instance_name
  }

}

# Add Route
resource "aws_route" "ent_rt_tgw" {
  route_table_id         = aws_vpc.ent_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tg.id
}
