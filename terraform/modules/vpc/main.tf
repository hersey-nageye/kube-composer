# VPC
# Purpose: Primary network boundary for the cluster. CIDR is controlled by var.vpc_cidr
# and must not overlap with other environments.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}


# Public Subnets
# Purpose: Public IPs enabled subnets for resources that required both inbound and outbound internet access.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.subnet_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    local.public_subnet_tags,
    {
      Name = "${var.project_name}-public-subnet-${count.index}"
    }
  )
}

# Private Subnets
# Purpose: Private IPs only subnets for resources that do not need inbound internet access.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.subnet_availability_zones[count.index]

  tags = merge(
    var.common_tags,
    local.private_subnet_tags,
    {
      Name = "${var.project_name}-private-subnet-${count.index}"
    }
  )
}

# Internet Gateway
# Purpose: Provides internet access to public subnets.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Route Table for Public Subnets
# Purpose: Routes internet-bound traffic from public subnets to the Internet Gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-route-table"
    }
  )
}

# Route Table Association for Public Subnets
# Purpose: Associates public subnets with the public route table.
resource "aws_route_table_association" "public-rta" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT Gateway
# Purpose: Provides a static public IP for the NAT Gateway. 
# This prevents connection interruptions if infrastructure is recreated.
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

# NAT Gateway
# Purpose: Enables resources within private subnets outbound internet access for 
# updates, patches, etc.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-gw"
  })
}

# Route Table for Private Subnets
# Purpose: Routes internet-bound traffic from private subnets to the NAT Gateway.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-route-table"
  })
}

# Route within Private Route Table to NAT Gateway
# Purpose: Ensures private subnet resources have outbound internet access via the NAT Gateway.
resource "aws_route" "private_default_to_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id

  depends_on = [aws_nat_gateway.nat]
}

# Route Table Association for Private Subnets
# Purpose: Associates private subnets with the private route table.
resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
