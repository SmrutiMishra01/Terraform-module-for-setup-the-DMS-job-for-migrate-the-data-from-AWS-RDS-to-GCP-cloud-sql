# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "dms-migration-vpc"
    Purpose = "DMS Migration AWS Source Network"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------
# Required so RDS (publicly accessible) can be reached by Google Cloud DMS
# over the public internet. For production, consider AWS Direct Connect or a
# VPN tunnel, but for a cross-cloud demo, public access is the simplest path.
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dms-migration-igw"
  }
}

# ---------------------------------------------------------------------------
# Public Subnets (2 required by AWS RDS DB Subnet Groups)
# AWS mandates subnets in at least 2 different Availability Zones.
# ---------------------------------------------------------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_a
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = {
    Name = "dms-migration-subnet-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_b
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"

  tags = {
    Name = "dms-migration-subnet-public-b"
  }
}

# ---------------------------------------------------------------------------
# Route Table – default route via IGW (shared by both subnets)
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "dms-migration-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security Group – MySQL access for Google Cloud DMS
# ---------------------------------------------------------------------------
# PRODUCTION NOTE: Replace 0.0.0.0/0 with the specific GCP DMS egress IP
# ranges for asia-south1 to restrict access:
# https://cloud.google.com/database-migration/docs/mysql/network
#
# For the demo, 0.0.0.0/0 allows DMS to connect without IP pre-configuration.
# ---------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "dms-migration-rds-sg"
  description = "Allow MySQL (3306) ingress from Google Cloud DMS static IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MySQL from anywhere - restrict to GCP DMS IPs in production"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "dms-migration-rds-sg"
    Purpose = "Allow GCP DMS to reach RDS on port 3306"
  }
}
