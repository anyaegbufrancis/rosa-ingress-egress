## Create VPC
resource "aws_vpc" "net_vpc" {
  cidr_block           = local.net_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${local.net_vpc_name}"
  }
}

## Create Private Subnet
resource "aws_subnet" "net_private_subnets" {
  count                   = local.net_subnet_count
  vpc_id                  = aws_vpc.net_vpc.id
  cidr_block              = cidrsubnet("${local.net_vpc_cidr_block}", "${local.net_newbits}", "${count.index}")
  availability_zone       = var.net_priv_subnet_azs[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.net_env}-private-subnet-${var.net_priv_subnet_azs[count.index]}"
  }
}

## Create Public Subnets
resource "aws_subnet" "net_public_subnets" {
  count                   = local.net_subnet_count
  vpc_id                  = aws_vpc.net_vpc.id
  cidr_block              = cidrsubnet("${local.net_vpc_cidr_block}", "${local.net_newbits}", "${count.index + length(var.net_priv_subnet_azs)}")
  availability_zone       = var.net_priv_subnet_azs[count.index]
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.net_env}-public-subnet-${var.net_priv_subnet_azs[count.index]}"
  }
}

## Create Internet Gateway + Resources
resource "aws_internet_gateway" "net_vpc_igw" {
  vpc_id = aws_vpc.net_vpc.id
  tags = {
    Name = "${var.net_env}-igw"
  }
}

## Create EIP
resource "aws_eip" "net_eip" {
  vpc = true
  tags = {
    Name = "${var.net_env}_eip"
  }
  depends_on = [
    aws_internet_gateway.net_vpc_igw
  ]
}

## Create NAT GW
resource "aws_nat_gateway" "net_nat_gw" {
  allocation_id = aws_eip.net_eip.id
  subnet_id     = aws_subnet.net_public_subnets[0].id
  tags = {
    Name = "${var.net_env}-nat_gw"
  }
}

## Public Route Table & Associations
resource "aws_route_table" "net_public_subnet_to_igw_rtb" {
  vpc_id = aws_vpc.net_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net_vpc_igw.id
  }
  tags = {
    Name = "${var.net_env}-public_subnets->net_igw-rtb"
  }
}

resource "aws_route" "net_route-tgw" {
  for_each               = toset(aws_subnet.ent_private_subnets[*].cidr_block)
  route_table_id         = aws_route_table.net_public_subnet_to_igw_rtb.id
  destination_cidr_block = each.key
  transit_gateway_id     = aws_ec2_transit_gateway.tg.id
}

resource "aws_route" "rosa_route-tgw" {
  for_each               = toset(aws_subnet.rosa_private_subnets[*].cidr_block)
  route_table_id         = aws_route_table.net_public_subnet_to_igw_rtb.id
  destination_cidr_block = each.key
  transit_gateway_id     = aws_ec2_transit_gateway.tg.id
}

resource "aws_route_table_association" "associate_1" {
  count          = local.net_subnet_count
  subnet_id      = element(aws_subnet.net_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.net_public_subnet_to_igw_rtb.id
}

## Private Network Route table association
resource "aws_route_table" "net_private_subnet_to_ngw_rtb" {
  vpc_id = aws_vpc.net_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.net_nat_gw.id
  }
  tags = {
    Name = "${var.net_env}-private_subnets->nat_gw_rtb"
  }
}

resource "aws_route_table_association" "associate_2" {
  count          = local.net_subnet_count
  subnet_id      = aws_subnet.net_private_subnets[count.index].id
  route_table_id = aws_route_table.net_private_subnet_to_ngw_rtb.id
}

## Create EC2 Instance for Public Subnet
resource "aws_security_group" "net_vpc_ec2_sg" {
  name        = "jump-server"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.net_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ec2_inbound_network
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [local.rosa_vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.net_env}-${var.ec2_instance_name}-sg"
  }
}

resource "random_string" "random" {
  length = 10
  lower  = true
}

resource "aws_key_pair" "key-pem" {
  key_name   = random_string.random.result
  public_key = data.local_file.ssh_key_pub.content
}

resource "aws_instance" "deployment_svr" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  key_name                    = random_string.random.result
  subnet_id                   = aws_subnet.net_public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.net_vpc_ec2_sg.id]
  tags = {
    Name = "${var.env}-${var.ec2_instance_name}"
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = data.local_file.ssh_key_priv.content
  }

  provisioner "file" {
    source      = "./install/install.sh"
    destination = "/home/ec2-user/install.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ./install.sh",
      "./install.sh"
    ]

  }
}

## Create NLB for custom domain inbound
resource "aws_lb" "nlb" {
  name               = var.custom_domain
  internal = false
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.net_public_subnets : subnet.id]
}

resource "aws_lb_target_group" "nlb_tg" {
  for_each = var.ports
  port        = each.value
  protocol    = "TCP"
  vpc_id      = aws_vpc.net_vpc.id
  target_type = "ip"
}

resource "aws_security_group" "nlb_sg" {
  description = "Allow connection between NLB and target"
  vpc_id      = aws_vpc.net_vpc.id
}

resource "aws_security_group_rule" "nlb_ingress" {
  for_each = var.ports

  security_group_id = aws_security_group.nlb_sg.id
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "nlb_listener" {
  for_each = var.ports
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = each.value
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg[each.key].arn
  }
}

resource "aws_route53_zone" "public_zone" {
  name = "${var.custom_domain}.com"
}

resource "aws_route53_record" "custom_zone_route" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = var.custom_domain
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.nlb.dns_name]
}

