output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the default security group created with the VPC."
  value       = aws_vpc.main.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL created with the VPC."
  value       = aws_vpc.main.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the main route table created with the VPC."
  value       = aws_vpc.main.main_route_table_id
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created."
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets."
  value       = aws_subnet.public.*.id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets."
  value       = aws_subnet.public.*.cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets."
  value       = aws_subnet.private.*.id
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks for the private subnets."
  value       = aws_subnet.private.*.cidr_block
}

output "public_route_table_ids" {
  description = "List of IDs of the public route tables (typically one)."
  value       = aws_route_table.public.*.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables."
  value       = aws_route_table.private.*.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = one(aws_internet_gateway.main.*.id) # Using one() safely extracts ID if created, null otherwise
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways."
  value       = aws_nat_gateway.main.*.id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IP addresses allocated for the NAT Gateways."
  value = var.reuse_nat_ips ? flatten(data.aws_eip.nat.*.public_ip) : flatten(aws_eip.nat.*.public_ip)
}

output "dhcp_options_id" {
  description = "The ID of the DHCP Options Set, if created."
  value       = one(aws_vpc_dhcp_options.main.*.id)
}

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC Gateway Endpoint, if created."
  value       = one(aws_vpc_endpoint.s3.*.id)
}

output "dynamodb_endpoint_id" {
  description = "The ID of the DynamoDB VPC Gateway Endpoint, if created."
  value       = one(aws_vpc_endpoint.dynamodb.*.id)
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log configuration, if created."
  value       = one(aws_flow_log.main.*.id)
}