# VPC Module

A reusable Terraform module for creating AWS VPC infrastructure with public and private subnets across multiple availability zones.

## Version

**Current Version**: 2.0.0

**Terraform Compatibility**: >= 1.0.0

**AWS Provider Compatibility**: >= 4.0.0

For version history and breaking changes, see [CHANGELOG.md](./CHANGELOG.md).

## Features

- VPC with configurable CIDR block
- Multiple public subnets with Internet Gateway
- Multiple private subnets (optional)
- NAT Gateway for private subnet internet access (optional)
- Automatic subnet CIDR calculation using `cidrsubnet`
- Multi-AZ support for high availability
- Flexible tagging system

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix          = "my-app"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_count  = 2
  private_subnet_count = 2
  enable_nat_gateway   = true
  nat_gateway_count    = 1

  tags = {
    Owner       = "your.name"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix to use for resource names | string | n/a | yes |
| vpc_cidr | CIDR block for the VPC | string | n/a | yes |
| public_subnet_count | Number of public subnets to create | number | 2 | no |
| private_subnet_count | Number of private subnets to create | number | 2 | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | bool | false | no |
| nat_gateway_count | Number of NAT Gateways for HA | number | 1 | no |
| enable_dns_hostnames | Enable DNS hostnames in VPC | bool | true | no |
| enable_dns_support | Enable DNS support in VPC | bool | true | no |
| tags | Map of tags to add to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| vpc_arn | The ARN of the VPC |
| internet_gateway_id | The ID of the Internet Gateway |
| public_subnet_ids | List of IDs of public subnets |
| public_subnet_cidrs | List of CIDR blocks of public subnets |
| public_subnet_azs | List of AZs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| private_subnet_cidrs | List of CIDR blocks of private subnets |
| private_subnet_azs | List of AZs of private subnets |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of IDs of private route tables |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of NAT Gateway public IPs |
| availability_zones | List of AZs used |

## Subnet CIDR Calculation

This module automatically calculates subnet CIDRs using the `cidrsubnet` function:

- **VPC CIDR**: `10.0.0.0/16` (65,536 addresses)
- **Public Subnet 1**: `10.0.0.0/24` (256 addresses)
- **Public Subnet 2**: `10.0.1.0/24` (256 addresses)
- **Private Subnet 1**: `10.0.2.0/24` (256 addresses)
- **Private Subnet 2**: `10.0.3.0/24` (256 addresses)

Formula: `cidrsubnet(vpc_cidr, 8, index)`

## Examples

### Basic VPC with Public Subnets Only

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix          = "simple"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_count  = 2
  private_subnet_count = 0

  tags = {
    Owner = "your.name"
  }
}
```

### Full VPC with NAT Gateway

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix          = "production"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_count  = 3
  private_subnet_count = 3
  enable_nat_gateway   = true
  nat_gateway_count    = 3  # One per AZ for HA

  tags = {
    Owner       = "your.name"
    Environment = "prod"
  }
}
```

## Architecture

### Without NAT Gateway (Cost-Effective)
```
VPC (10.0.0.0/16)
├── Public Subnet 1 (10.0.0.0/24) - AZ 1
├── Public Subnet 2 (10.0.1.0/24) - AZ 2
├── Private Subnet 1 (10.0.2.0/24) - AZ 1 (no internet)
└── Private Subnet 2 (10.0.3.0/24) - AZ 2 (no internet)
```

### With NAT Gateway (High Availability)
```
VPC (10.0.0.0/16)
├── Public Subnet 1 (10.0.0.0/24) - AZ 1
│   └── NAT Gateway 1
├── Public Subnet 2 (10.0.1.0/24) - AZ 2
│   └── NAT Gateway 2
├── Private Subnet 1 (10.0.2.0/24) - AZ 1 → NAT GW 1
└── Private Subnet 2 (10.0.3.0/24) - AZ 2 → NAT GW 2
```

## Cost Considerations

**NAT Gateway Pricing** (us-east-1):
- $0.045 per hour per NAT Gateway
- $0.045 per GB data processed
- **Monthly cost**: ~$32.40 per NAT Gateway + data transfer

For dev/test environments, consider:
- Setting `enable_nat_gateway = false`
- Using a single NAT Gateway (`nat_gateway_count = 1`)
- Deploying a NAT instance instead (not covered in this module)

## Notes

- Subnets are distributed across availability zones automatically
- Public subnets have `map_public_ip_on_launch = true`
- Private subnets require NAT Gateway for internet access
- All resources are tagged with the provided tags plus a Name tag
