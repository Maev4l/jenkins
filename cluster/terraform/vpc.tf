locals {
  public_subnets_cidr = [
    "172.16.1.0/24",
    "172.16.2.0/24",
    "172.16.3.0/24",
  ]
  private_subnets_cidr = [
    "172.16.101.0/24",
    "172.16.102.0/24",
    "172.16.103.0/24",
  ]
}

resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "jenkins-vpc"
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "jenkins-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = length(local.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.public_subnets_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  tags = {
    Name = "jenkins-public-subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "jenkins-public-rt"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = length(local.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.private_subnets_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  tags = {
    Name = "jenkins-private-subnet"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "jenkins-private-rt"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(local.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

/*
// Make ECR service accessible from the subnets with VPC endpoints
// see: https://aws.amazon.com/blogs/compute/setting-up-aws-privatelink-for-amazon-ecs-and-amazon-ecr/
resource "aws_security_group" "sg_vpc_endpoint" {
  name        = "jenkins-vpc-endpoint-sg"
  description = "Security group VPC endpoints"
  vpc_id      = aws_vpc.main.id
}

// Allow only incoming requests from the subnets, where the application is hosted
// and only for HTTPS protocol
resource "aws_vpc_security_group_ingress_rule" "ingress_rule_https_vpc_endpoint" {
  count = var.enable ? length(local.private_subnets_cidr) : 0

  security_group_id = aws_security_group.sg_vpc_endpoint.id
  cidr_ipv4         = element(local.private_subnets_cidr, count.index)
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_endpoint" "ecr_docker" {
  count             = var.enable ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-central-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnet[*].id
  security_group_ids  = [aws_security_group.sg_vpc_endpoint.id]

  tags = {
    Name = "jenkins-vpc-endpoint-ecr-docker"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count             = var.enable ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-central-1.ecr.api"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnet[*].id
  security_group_ids  = [aws_security_group.sg_vpc_endpoint.id]

  tags = {
    Name = "jenkins-vpc-endpoint-ecr-api"
  }
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_route_table.id]
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect : "Allow",
      Action : "*",
      Principal : "*",
      Resource : "*"
    }]
  })

  tags = {
    Name = "jenkins-vpc-endpoint-s3"
  }
}
*/
