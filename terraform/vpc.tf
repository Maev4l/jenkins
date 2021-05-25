resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr_block_prefix}.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1" {

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.vpc_cidr_block_prefix}.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current_region.name}a"
}

locals {
  my_ip = "78.193.217.31"
}

resource "aws_security_group" "sg" {
  name        = "${local.tags.application}-sg"
  description = "Allow inbound traffic via SSH and TLS"
  vpc_id      = aws_vpc.vpc.id

  ingress = [{
    description      = "Incoming traffic"
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["${local.my_ip}/32"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false

    },
    {
      description      = "Incoming traffic"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false

  }]

  egress = [{
    description      = "All traffic"
    protocol         = -1
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false

  }]

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}

resource "aws_route_table_association" "rt_subnet1_asso" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}
