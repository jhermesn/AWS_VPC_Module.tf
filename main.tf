locals {
  # Determine if resources should be created based on input variables
  create_igw             = var.enable_internet_gateway && length(var.public_subnet_cidrs) > 0
  create_nat_gateway     = var.enable_nat_gateway && length(var.public_subnet_cidrs) > 0 && length(var.private_subnet_cidrs) > 0
  nat_gateway_count      = local.create_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  has_public_subnets     = length(var.public_subnet_cidrs) > 0
  has_private_subnets    = length(var.private_subnet_cidrs) > 0
  num_azs                = length(var.availability_zones)
  
  # Improved NAT gateway and routing logic
  create_per_az_nat_gateways = local.create_nat_gateway && !var.single_nat_gateway
  private_route_table_count = local.has_private_subnets ? (local.create_per_az_nat_gateways ? local.num_azs : 1) : 0

  # Common tags to assign to all resources
  common_tags = merge(var.tags, {
    "terraform-module" = "terraform-aws-vpc"
    "vpc-name"         = var.name
  })
}

# VPC Resource
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, {
    Name = var.name
  })
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "main" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(local.common_tags, var.dhcp_options_tags, {
    Name = "${var.name}-dhcp-options"
  })
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = local.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.internet_gateway_tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets & Route Table
resource "aws_subnet" "public" {
  count = local.has_public_subnets ? local.num_azs : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch_public

  tags = merge(local.common_tags, var.public_subnet_tags, {
    Name        = "${var.name}-public-subnet-${var.availability_zones[count.index]}"
    SubnetType  = "public"
  })
}

resource "aws_route_table" "public" {
  count = local.has_public_subnets ? 1 : 0 # Only create if public subnets exist

  vpc_id = aws_vpc.main.id

  route {
    # Route all traffic to the Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = local.create_igw ? aws_internet_gateway.main[0].id : null
  }

  tags = merge(local.common_tags, var.public_route_table_tags, {
    Name       = "${var.name}-public-rt"
    SubnetType = "public"
  })

  # IGW must be created before the public route table
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table_association" "public" {
  count = local.has_public_subnets ? local.num_azs : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id # Associate all public subnets with the single public RT
}

# NAT Gateway(s) & Elastic IPs
# Data source to find existing EIPs if reuse is enabled
data "aws_eip" "nat" {
  count = local.create_nat_gateway && var.reuse_nat_ips ? local.nat_gateway_count : 0
  tags = merge(var.nat_eip_tags, {
     Name = var.single_nat_gateway ? "${var.name}-nat-eip" : "${var.name}-nat-eip-${var.availability_zones[count.index]}"
  })
}

# Create new EIPs if reuse is disabled or data source didn't find them
resource "aws_eip" "nat" {
  count = local.create_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0
  
  domain = "vpc"

  tags = merge(local.common_tags, var.nat_eip_tags, {
    Name = var.single_nat_gateway ? "${var.name}-nat-eip" : "${var.name}-nat-eip-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main] # EIP needs IGW for NAT to function
}

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  # If single_nat_gateway, place in the first public subnet. Otherwise, place in the public subnet of the corresponding AZ.
  subnet_id = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  # Use existing EIP if found, otherwise use newly created one
  allocation_id = var.reuse_nat_ips ? tolist(data.aws_eip.nat.*.id)[count.index] : aws_eip.nat[count.index].id

  tags = merge(local.common_tags, var.nat_gateway_tags, {
    Name = var.single_nat_gateway ? "${var.name}-nat-gw" : "${var.name}-nat-gw-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main, aws_eip.nat, data.aws_eip.nat]
}


# Private Subnets & Route Tables
resource "aws_subnet" "private" {
  count = local.has_private_subnets ? local.num_azs : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch_private

  tags = merge(local.common_tags, var.private_subnet_tags, {
    Name        = "${var.name}-private-subnet-${var.availability_zones[count.index]}"
    SubnetType  = "private"
  })
}

resource "aws_route_table" "private" {
  count = local.private_route_table_count

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    # Add default route via NAT GW if enabled
    for_each = local.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      # If single NGW, route via the only one. If NGW per AZ, route via the NGW in the corresponding AZ (index).
      nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(local.common_tags, var.private_route_table_tags, {
    # Name differentiates if multiple private RTs are created
    Name       = local.create_nat_gateway && !var.single_nat_gateway ? "${var.name}-private-rt-${var.availability_zones[count.index]}" : "${var.name}-private-rt"
    SubnetType = "private"
  })

  depends_on = [aws_nat_gateway.main]
}

resource "aws_route_table_association" "private" {
  count = local.has_private_subnets ? local.num_azs : 0

  subnet_id = aws_subnet.private[count.index].id

  # If single NGW or no NGW, associate with the single private RT.
  # If NGW per AZ, associate subnet in AZ 'i' with private RT 'i'.
  route_table_id = aws_route_table.private[local.create_nat_gateway && !var.single_nat_gateway ? count.index : 0].id
}

# VPC Gateway Endpoints (S3, DynamoDB)
locals {
  # Collect all route table IDs that should get the gateway endpoints
  all_route_table_ids = concat(
    local.has_public_subnets ? [aws_route_table.public[0].id] : [],
    aws_route_table.private.*.id
  )
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3" # Dynamically gets region
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.all_route_table_ids

  tags = merge(local.common_tags, var.gateway_endpoint_tags, {
    Name = "${var.name}-s3-gw-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb" # Dynamically gets region
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.all_route_table_ids

  tags = merge(local.common_tags, var.gateway_endpoint_tags, {
    Name = "${var.name}-dynamodb-gw-endpoint"
  })
}

# Data source to get current region
data "aws_region" "current" {}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = var.flow_log_traffic_type
  log_destination_type = var.flow_log_destination_type
  log_destination = var.flow_log_destination_arn # ARN of CW Log Group or S3 Bucket
  iam_role_arn    = var.flow_log_destination_type == "cloud-watch-logs" ? var.flow_log_iam_role_arn : null # Only needed for CW logs
  max_aggregation_interval = var.flow_log_max_aggregation_interval

  tags = merge(local.common_tags, var.flow_log_tags, {
    Name = "${var.name}-flow-log"
  })

  lifecycle {
    precondition {
      condition     = var.flow_log_destination_arn != ""
      error_message = "flow_log_destination_arn must be provided when enable_flow_log is true."
    }
    precondition {
      condition     = var.flow_log_destination_type != "cloud-watch-logs" || var.flow_log_iam_role_arn != ""
      error_message = "flow_log_iam_role_arn must be provided when flow_log_destination_type is cloud-watch-logs."
    }
  }
}