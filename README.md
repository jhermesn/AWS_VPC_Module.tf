# AWS VPC Module in Terraform
This Terraform module creates a highly customizable Virtual Private Cloud (VPC) on AWS. It follows AWS best practices and allows for the configuration of common networking components, including:
* VPC with configurable CIDR, tenancy, and DNS settings.
* Public Subnets across specified Availability Zones.
* Private Subnets across specified Availability Zones.
* Internet Gateway (IGW) for public subnet internet access.
* NAT Gateway(s) (Single or High-Availability Per-AZ) for private subnet outbound internet access.
* Elastic IPs (EIPs) for NAT Gateways (optionally reuse existing EIPs).
* Route Tables for public and private subnets.
* VPC Gateway Endpoints for S3 and DynamoDB (optional).
* VPC Flow Logs to CloudWatch Logs or S3 (optional).
* Custom DHCP Options Set (optional).
* Consistent Tagging across all resources.

## Features
* **Customizable:** Configure most aspects of your VPC via input variables.
* **HA Ready:** Option to create NAT Gateways in each Availability Zone for high availability.
* **Standard Structure:** Follows Terraform module conventions.
* **Tagging:** Apply common tags and resource-specific tags.
* **Optional Components:** Easily enable/disable features like NAT Gateways, Endpoints, and Flow Logs.

## Prerequisites
* Terraform v1.11.0 or later.
* AWS Provider configured with appropriate credentials.

## Inputs
|Name|Description|Type|Default|Required|
|-|-|-|-|-|
|`name`|Name prefix for VPC and associated resources.|`string`|n/a|yes|
|`cidr_block`|The primary IPv4 CIDR block for the VPC.|`string`|n/a|yes|
|`instance_tenancy`|The allowed tenancy of instances launched into the VPC. Options: 'default', 'dedicated'.|`string`|`"default"`|no|
|`enable_dns_support`|Specifies whether DNS resolution is supported for the VPC.|`bool`|`true`|no|
|`enable_dns_hostnames`|Specifies whether instances launched in the VPC get public DNS hostnames.|`bool`|`true`|no|
|`tags`|A map of tags to apply to all resources created by this module.|`map(string)`|`{}`|no|
|`availability_zones`|A list of Availability Zones to use for the subnets in the VPC.|`list(string)`|n/a|yes|
|`public_subnet_cidrs`|A list of CIDR blocks for public subnets. Must match the number/order of `availability_zones`.|`list(string)`|`[]`|no|
|`private_subnet_cidrs`|A list of CIDR blocks for private subnets. Must match the number/order of `availability_zones`.|`list(string)`|`[]`|no|
|`map_public_ip_on_launch_public`|Specify true to assign public IP to instances in public subnets.|`bool`|`true`|no|
|`map_public_ip_on_launch_private`|Specify true to assign public IP to instances in private subnets (Not Recommended).|`bool`|`false`|no|
|`public_subnet_tags`|Additional tags to apply only to public subnets.|`map(string)`|`{}`|no|
|`private_subnet_tags`|Additional tags to apply only to private subnets.|`map(string)`|`{}`|no|
|`enable_internet_gateway`|Set to true to create an Internet Gateway. Required for public subnets.|`bool`|`true`|no|
|`internet_gateway_tags`|Additional tags to apply to the Internet Gateway.|`map(string)`|`{}`|no|
|`enable_nat_gateway`|Set to true to create NAT Gateway(s) for private subnets.|`bool`|`true`|no|
|`single_nat_gateway`|Set to true for a single NAT Gateway, false for one per AZ (HA).|`bool`|`false`|no|
|`reuse_nat_ips`|Set to true to reuse existing EIPs for NAT Gateways based on tags. Requires `nat_eip_tags`.|`bool`|`false`|no|
|`nat_gateway_tags`|Additional tags to apply to the NAT Gateway(s).|`map(string)`|`{}`|no|
|`nat_eip_tags`|Tags for NAT Gateway EIPs. Used for reuse identification.|`map(string)`|`{}`|no|
|`public_route_table_tags`|Additional tags for the public route table(s).|`map(string)`|`{}`|no|
|`private_route_table_tags`|Additional tags for the private route table(s).|`map(string)`|`{}`|no|
|`enable_s3_endpoint`|Set to true to create a VPC Gateway Endpoint for S3.|`bool`|`false`|no|
|`enable_dynamodb_endpoint`|Set to true to create a VPC Gateway Endpoint for DynamoDB.|`bool`|`false`|no|
|`gateway_endpoint_tags`|Additional tags for VPC Gateway Endpoints.|`map(string)`|`{}`|no|
|`enable_flow_log`|Set to true to enable VPC Flow Logs.|`bool`|`false`|no|
|`flow_log_traffic_type`|Traffic type for Flow Logs (ACCEPT, REJECT, ALL).|`string`|`"ALL"`|no|
|`flow_log_destination_type`|Flow Log destination type (cloud-watch-logs, s3).|`string`|`"cloud-watch-logs"`|no|
|`flow_log_destination_arn`|ARN of the CloudWatch Log Group or S3 Bucket for Flow Logs. Required if `enable_flow_log` is true.|`string`|`""`|no|
|`flow_log_iam_role_arn`|IAM role ARN for Flow Logs to publish. Required for `cloud-watch-logs` destination.|`string`|`""`|no|
|`flow_log_max_aggregation_interval`|Max aggregation interval in seconds (60 or 600).|`number`|`600`|no|
|`flow_log_tags`|Additional tags for the VPC Flow Log resource.|`map(string)`|`{}`|no|
|`enable_dhcp_options`|Set to true to create a custom DHCP Options Set.|`bool`|`false`|no|
|`dhcp_options_domain_name`|Domain name for DHCP options set.|`string`|`null`|no|
|`dhcp_options_domain_name_servers`|List of DNS servers for DHCP options set.|`list(string)`|`["AmazonProvidedDNS"]`|no|
|`dhcp_options_ntp_servers`|List of NTP servers for DHCP options set.|`list(string)`|`null`|no|
|`dhcp_options_netbios_name_servers`|List of NetBIOS name servers.|`list(string)`|`null`|no|
|`dhcp_options_netbios_node_type`|NetBIOS node type (1, 2, 4, or 8).|`string`|`null`|no|
|`dhcp_options_tags`|Additional tags for the DHCP Options Set.|`map(string)`|`{}`|no|

## Outputs
|Name|Description|
|-|-|
|`vpc_id`|The ID of the created VPC.|
|`vpc_cidr_block`|The primary CIDR block of the VPC.|
|`default_security_group_id`|The ID of the default security group created with the VPC.|
|`default_network_acl_id`|The ID of the default network ACL created with the VPC.|
|`default_route_table_id`|The ID of the main route table created with the VPC.|
|`availability_zones`|List of Availability Zones where subnets were created.|
|`public_subnet_ids`|List of IDs of the public subnets.|
|`public_subnet_cidrs`|List of CIDR blocks for the public subnets.|
|`private_subnet_ids`|List of IDs of the private subnets.|
|`private_subnet_cidrs`|List of CIDR blocks for the private subnets.|
|`public_route_table_ids`|List of IDs of the public route tables (typically one).|
|`private_route_table_ids`|List of IDs of the private route tables.|
|`internet_gateway_id`|The ID of the Internet Gateway, if created.|
|`nat_gateway_ids`|List of IDs of the NAT Gateways, if created.|
|`nat_gateway_public_ips`|List of public Elastic IP addresses allocated for the NAT Gateways.|
|`dhcp_options_id`|The ID of the DHCP Options Set, if created.|
|`s3_endpoint_id`|The ID of the S3 VPC Gateway Endpoint, if created.|
|`dynamodb_endpoint_id`|The ID of the DynamoDB VPC Gateway Endpoint, if created.|
|`flow_log_id`|The ID of the VPC Flow Log configuration, if created.|

## Usage
```terraform
module "dev_vpc" {
  source = "https://github.com/jhermesn/AWS_VPC_Module.tf"

  name       = "dev-vpc"
  cidr_block = "10.0.0.0/16"
  
  # Create in 3 availability zones
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Define CIDR blocks for subnets
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  
  # Create Internet Gateway and NAT Gateway
  enable_internet_gateway = true
  enable_nat_gateway      = true
  single_nat_gateway      = true  # Use single NAT Gateway for cost savings
  
  # Add common tags to all resources
  tags = {
    Environment = "Development"
    Terraform   = "true"
  }
}
```

## License
This project is licensed under the [MIT License](LICENSE).