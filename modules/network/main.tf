data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = var.name }
}

# Single public subnet, single AZ, no NAT gateway (kept cheap on purpose).
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 1, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false # the Elastic IP is the public address

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# No SSH: port 22 is intentionally absent. The instance is reached via SSM,
# which only needs outbound HTTPS.
resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "HTTP to the app; no SSH"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name}-app" }
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "App port from anywhere"
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
  cidr_ipv4         = "0.0.0.0/0"
}

# For the planned HTTPS reverse proxy on the instance. Port 80 above stays open
# for certificate issuance and the HTTP-to-HTTPS redirect. Nothing listens on
# 443 until the proxy is set up.
resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS from anywhere"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Outbound is open because there are no VPC endpoints or NAT: the instance
# must reach SSM, ECR, Docker/Compose downloads and OS repos over the internet.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
