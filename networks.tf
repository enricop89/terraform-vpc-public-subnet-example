# VPC 1

resource "aws_vpc" "vpc_main" {
  provider             = aws.region-main
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.region-main
  vpc_id   = aws_vpc.vpc_main.id
}

#Get all available AZ's in VPC for main region
data "aws_availability_zones" "azs" {
  provider = aws.region-main
  state    = "available"
}


#Create subnet # 1 
resource "aws_subnet" "subnet_1" {
  provider          = aws.region-main
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.1.0/24"
}


#Create subnet #2
resource "aws_subnet" "subnet_2" {
  provider          = aws.region-main
  vpc_id            = aws_vpc.vpc_main.id
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  cidr_block        = "10.0.2.0/24"
}

#Accept VPC peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept               = true
}

#Create route table
resource "aws_route_table" "internet_route" {
  provider = aws.region-main
  vpc_id   = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Main-Region-RT"
  }
}

#Overwrite default route table of VPC(Main) with our route table entries
resource "aws_main_route_table_association" "set-main-default-rt-assoc" {
  provider       = aws.region-main
  vpc_id         = aws_vpc.vpc_main.id
  route_table_id = aws_route_table.internet_route.id
}
