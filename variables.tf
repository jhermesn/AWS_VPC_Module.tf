# General VPC Configuration
variable "name" {
  description = "Name prefix for VPC and associated resources."
  type        = string
}

variable "cidr_block" {
  description = "The primary IPv4 CIDR block for the VPC."
  type        = string
}

variable "instance_tenancy" {
  description = "The allowed tenancy of instances launched into the VPC. Options: 'default', 'dedicated'."
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Allowed values for instance_tenancy are 'default' or 'dedicated'."
  }
}

variable "enable_dns_support" {
  description = "Specifies whether DNS resolution is supported for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Specifies whether instances launched in the VPC get public DNS hostnames."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

# Subnet Configuration
variable "availability_zones" {
  description = "A list of Availability Zones to use for the subnets in the VPC."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets. Must match the number/order of availability_zones if specified."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.public_subnet_cidrs) == 0 || length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of public_subnet_cidrs must match the number of availability_zones."
  }
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for private subnets. Must match the number/order of availability_zones if specified."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.private_subnet_cidrs) == 0 || length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of private_subnet_cidrs must match the number of availability_zones."
  }
}

variable "map_public_ip_on_launch_public" {
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address."
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch_private" {
  description = "Specify true to indicate that instances launched into the private subnet should be assigned a public IP address (Not recommended for private subnets)."
  type        = bool
  default     = false
}

variable "public_subnet_tags" {
  description = "Additional tags to apply only to public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags to apply only to private subnets."
  type        = map(string)
  default     = {}
}

# Internet Gateway Configuration
variable "enable_internet_gateway" {
  description = "Set to true to create an Internet Gateway and attach it to the VPC. Required for public subnets."
  type        = bool
  default     = true
}

variable "internet_gateway_tags" {
  description = "Additional tags to apply to the Internet Gateway."
  type        = map(string)
  default     = {}
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Set to true to create NAT Gateway(s) to allow outbound internet access for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Set to true to create a single NAT Gateway in the first public subnet. Set to false for one NAT Gateway per AZ (requires public subnets in those AZs)."
  type        = bool
  default     = false # Default to HA configuration (one per AZ)
}

variable "reuse_nat_ips" {
  description = "Set to true to reuse existing EIPs for NAT Gateways based on tags. Requires `nat_eip_tags` to be set."
  type        = bool
  default     = false
}

variable "nat_gateway_tags" {
  description = "Additional tags to apply to the NAT Gateway(s)."
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Tags to apply to the Elastic IPs used for the NAT Gateway(s). Used for identifying EIPs if `reuse_nat_ips` is true."
  type        = map(string)
  default     = {}
}

# Route Table Configuration
variable "public_route_table_tags" {
  description = "Additional tags to apply to the public route table(s)."
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags to apply to the private route table(s)."
  type        = map(string)
  default     = {}
}

# VPC Endpoint Configuration (Gateway Endpoints)
variable "enable_s3_endpoint" {
  description = "Set to true to create a VPC Gateway Endpoint for S3."
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Set to true to create a VPC Gateway Endpoint for DynamoDB."
  type        = bool
  default     = false
}

variable "gateway_endpoint_tags" {
  description = "Additional tags to apply to the VPC Gateway Endpoints."
  type        = map(string)
  default     = {}
}

# VPC Flow Logs Configuration
variable "enable_flow_log" {
  description = "Set to true to enable VPC Flow Logs."
  type        = bool
  default     = false
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL."
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "Allowed values for flow_log_traffic_type are ACCEPT, REJECT, ALL."
  }
}

variable "flow_log_destination_type" {
  description = "The type of destination for Flow Logs. Valid values: cloud-watch-logs, s3."
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Allowed values for flow_log_destination_type are cloud-watch-logs, s3."
  }
}

variable "flow_log_destination_arn" {
  description = "The ARN of the CloudWatch Logs Log Group or S3 Bucket where Flow Logs will be published. Required if enable_flow_log is true."
  type        = string
  default     = ""
}

variable "flow_log_iam_role_arn" {
  description = "The ARN of the IAM role that allows VPC Flow Logs to publish logs to your destination. Required if enable_flow_log is true and destination is cloud-watch-logs."
  type        = string
  default     = ""
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval (in seconds) during which a flow of packets is captured and aggregated into a flow log record. Valid values: 60, 600."
  type        = number
  default     = 600
  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "Allowed values for flow_log_max_aggregation_interval are 60 or 600."
  }
}

variable "flow_log_tags" {
  description = "Additional tags to apply to the VPC Flow Log resource."
  type        = map(string)
  default     = {}
}

# DHCP Options Set Configuration
variable "enable_dhcp_options" {
  description = "Set to true to create a DHCP Options Set and associate it with the VPC."
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name forDHCP options set (e.g. 'us-west-2.compute.internal', 'mycompany.local')."
  type        = string
  default     = null # Defaults to region specific zone based on AWS provider region if null
}

variable "dhcp_options_domain_name_servers" {
  description = "List of name servers to configure in DHCP options set."
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP servers to configure in DHCP options set."
  type        = list(string)
  default     = null # Defaults to no NTP servers
}

variable "dhcp_options_netbios_name_servers" {
  description = "List of NetBIOS name servers."
  type        = list(string)
  default     = null # Defaults to no NetBIOS name servers
}

variable "dhcp_options_netbios_node_type" {
  description = "The NetBIOS node type (1, 2, 4, or 8). Recommended to leave blank unless thoroughly understood."
  type        = string
  default     = null # Defaults to no NetBIOS node type
}

variable "dhcp_options_tags" {
  description = "Additional tags to apply to the DHCP Options Set."
  type        = map(string)
  default     = {}
}