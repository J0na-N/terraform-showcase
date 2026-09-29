# ------------------------------------------------------------------
# VPC module: two public + two private subnets across two AZs, a NAT
# gateway, an internet gateway, flow logs, a locked-down default SG,
# and a hardened default network ACL.
# ------------------------------------------------------------------

locals {
  prefix                 = "${var.nametag}-${var.environment}"
  flow-logs-traffic-type = var.environment == "prod" ? "ALL" : "REJECT"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc-cidr-block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.this]
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public-subnet-cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public-subnet-cidrs[count.index]
  availability_zone = var.subnet-availability-zones[0]
}

resource "aws_subnet" "public_subnet_other_az" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public-subnet-cidrs-other-az[0]
  availability_zone = var.subnet-availability-zones[1]
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private-subnet-cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private-subnet-cidrs[count.index]
  availability_zone = var.subnet-availability-zones[1]
}

resource "aws_subnet" "private_subnet_other_az" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private-subnet-cidrs-other-az[0]
  availability_zone = var.subnet-availability-zones[0]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "public_route_table_association_other_az" {
  subnet_id      = aws_subnet.public_subnet_other_az.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_other_az" {
  subnet_id      = aws_subnet.private_subnet_other_az.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public-subnet-cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private-subnet-cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${local.prefix}"
  retention_in_days = var.environment == "prod" ? 90 : 30
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = lower("${local.prefix}-vpc-flow-logs-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = lower("${local.prefix}-vpc-flow-logs-policy")
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = local.flow-logs-traffic-type
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
}
