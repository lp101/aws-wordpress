data "aws_availability_zones" "available" {}
# VPC Definition
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"
  name                 = "TestVPC"
  cidr                 = "10.1.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  #public_subnets       = ["10.1.0.0/26", "10.1.0.64/26", "10.1.0.128/26"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}
# Internet gateway
resource "aws_internet_gateway" "vpc-igw" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "vpc-igw"
  }
}
# Nat gateway
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.vpc-igw]
}
resource "aws_nat_gateway" "testvpc_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat-subnet-a.id
  tags = {
    Name = "Test VPC NAT Gatewaty"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.vpc-igw]
}
# Public subnet for NAT Gateway
resource "aws_subnet" "nat-subnet-a" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.0.192/26"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "nat-subnet-a"
  }
}

# Routing table for public subnet
resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "testvpc-public-route-table"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.vpc-igw.id}"
}

# Routing table for private subnet
resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "testvpc-private-route-table"
  }
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.testvpc_nat_gateway.id}"
}

# Public subnets for Application LB
resource "aws_subnet" "lb-subnet-a" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.0.0/26"
  availability_zone = "eu-west-1a"
  #map_public_ip_on_launch = true
  tags = {
    Name = "lb-subnet-a"
  }
}
resource "aws_subnet" "lb-subnet-b" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.0.64/26"
  availability_zone = "eu-west-1b"
  #map_public_ip_on_launch = true
  tags = {
    Name = "lb-subnet-b"
  }
}
resource "aws_subnet" "lb-subnet-c" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.0.128/26"
  availability_zone = "eu-west-1c"
  #map_public_ip_on_launch = true
  tags = {
    Name = "lb-subnet-c"
  }
}

# Private subnets for EC2 instances
resource "aws_subnet" "ec2-subnet-a" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.1.0/26"
  availability_zone = "eu-west-1a"
  #map_public_ip_on_launch = true
  tags = {
    Name = "ec2-subnet-a"
  }
}
resource "aws_subnet" "ec2-subnet-b" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.1.64/26"
  availability_zone = "eu-west-1b"
  #map_public_ip_on_launch = true
  tags = {
    Name = "ec2-subnet-b"
  }
}
resource "aws_subnet" "ec2-subnet-c" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.1.128/26"
  availability_zone = "eu-west-1c"
  #map_public_ip_on_launch = true
  tags = {
    Name = "ec2-subnet-c"
  }
}

# Private subnets for RDS MySQL
resource "aws_subnet" "db-subnet-a" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.10.0/26"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "db-subnet-a"
  }
}
resource "aws_subnet" "db-subnet-b" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.10.64/26"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "db-subnet-b"
  }
}
resource "aws_subnet" "db-subnet-c" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.10.128/26"
  availability_zone = "eu-west-1c"
  tags = {
    Name = "db-subnet-c"
  }
}

# Private subnets for EFS
resource "aws_subnet" "efs-subnet-a" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.5.0/26"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "efs-subnet-a"
  }
}
resource "aws_subnet" "efs-subnet-b" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.5.64/26"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "efs-subnet-b"
  }
}
resource "aws_subnet" "efs-subnet-c" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.1.5.128/26"
  availability_zone = "eu-west-1c"
  tags = {
    Name = "efs-subnet-c"
  }
}

# Route table associations
# Public
resource "aws_route_table_association" "public_nata" {
  subnet_id      = aws_subnet.nat-subnet-a.id
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "public_lba" {
  subnet_id      = aws_subnet.lb-subnet-a.id
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "public_lbb" {
  subnet_id      = aws_subnet.lb-subnet-b.id
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "public_lbc" {
  subnet_id      = aws_subnet.lb-subnet-c.id
  route_table_id = "${aws_route_table.public.id}"
}
# Private
resource "aws_route_table_association" "private_ec2a" {
  subnet_id      = aws_subnet.ec2-subnet-a.id
  route_table_id = "${aws_route_table.private.id}"
}
resource "aws_route_table_association" "private_ec2b" {
  subnet_id      = aws_subnet.ec2-subnet-b.id
  route_table_id = "${aws_route_table.private.id}"
}
resource "aws_route_table_association" "private_ec2c" {
  subnet_id      = aws_subnet.ec2-subnet-c.id
  route_table_id = "${aws_route_table.private.id}"
}