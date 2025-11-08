# Changelog

All notable changes to this VPC module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-08

### Breaking Changes

#### NAT Gateway Resource Naming
- **Changed**: NAT Gateway resource naming scheme has been modified
- **Impact**: Existing NAT Gateways will be destroyed and recreated during upgrade
- **Migration**: Plan carefully and expect downtime for private subnet internet access
- **Before**: `aws_nat_gateway.main`
- **After**: `aws_nat_gateway.main[count.index]`

#### Route Table Structure
- **Changed**: Private route tables now use count-based indexing
- **Impact**: Route table associations may be recreated
- **Migration**: Review `terraform plan` output carefully before applying
- **Recommendation**: Consider using `terraform state mv` to avoid recreation

#### Output Value Changes
- **Changed**: Several outputs now return lists instead of single values
- **Affected Outputs**:
  - `nat_gateway_ids` - Now returns list (was single value)
  - `nat_gateway_public_ips` - Now returns list (was single value)
  - `private_route_table_ids` - Now returns list (was single value)
- **Migration**: Update consuming modules to handle list values using indexing or splat operators

#### Subnet CIDR Calculation
- **Changed**: Automatic subnet CIDR calculation using `cidrsubnet` function
- **Impact**: Manually specified subnet CIDRs are no longer supported
- **Before**: Variables `public_subnet_cidrs` and `private_subnet_cidrs` accepted as lists
- **After**: CIDRs automatically calculated from `vpc_cidr` and subnet counts
- **Migration**: 
  - Ensure your VPC CIDR can accommodate the number of subnets requested
  - Formula: `cidrsubnet(vpc_cidr, 8, index)` creates /24 subnets from /16 VPC
  - Maximum 6 public + 6 private subnets supported

### Added
- Multi-AZ NAT Gateway support via `nat_gateway_count` variable
- Input validation for all variables
- Automatic availability zone selection
- Enhanced tagging support with merge functionality
- DNS hostname and DNS support configuration options
- Comprehensive outputs for all created resources
- Architecture diagrams in README
- Cost considerations documentation

### Changed
- Improved resource naming with consistent `name_prefix` pattern
- Route table logic optimized for multi-NAT Gateway scenarios
- Documentation enhanced with examples and architecture diagrams

### Security Enhancements
- Public subnets properly isolated from private subnets
- NAT Gateway placement in public subnets only
- Route table isolation between public and private tiers

---

## [1.5.0] - 2025-10-15

### Added
- Optional NAT Gateway support for private subnets
- `enable_nat_gateway` variable (default: false)
- EIP allocation for NAT Gateways
- Private route tables with NAT Gateway routing

### Changed
- Private subnets now optional (default count: 2)
- Improved tagging consistency across resources

---

## [1.0.0] - 2025-09-01

### Initial Release

#### Features
- VPC creation with configurable CIDR block
- Internet Gateway for public internet access
- Public subnets with automatic public IP assignment
- Private subnets (internet access requires NAT Gateway)
- Route tables and associations
- Basic tagging support

#### Resources Created
- 1 VPC
- 1 Internet Gateway
- 2 Public Subnets (default)
- 2 Private Subnets (default)
- 1 Public Route Table
- 1 Private Route Table

#### Inputs
- `name_prefix` - Resource naming prefix
- `vpc_cidr` - VPC CIDR block
- `public_subnet_count` - Number of public subnets
- `private_subnet_count` - Number of private subnets
- `tags` - Resource tags

#### Outputs
- VPC ID, CIDR, and ARN
- Internet Gateway ID
- Subnet IDs and CIDRs
- Route table IDs

---

## Migration Guide: v1.x to v2.0

### Pre-Migration Steps

1. **Backup State File**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup-v1
   ```

2. **Review Current Infrastructure**
   ```bash
   terraform state list
   terraform show
   ```

3. **Document Current NAT Gateway IPs**
   - Save NAT Gateway Elastic IPs for reference
   - Update security group rules if they reference these IPs

### Migration Process

#### Option 1: Minimal Disruption (Recommended for Production)

1. **Create new VPC module instance alongside existing**
   ```hcl
   module "vpc_v2" {
     source = "./modules/vpc"  # v2.0
     # ... configuration
   }
   ```

2. **Migrate workloads to new VPC**
   - Update application configurations
   - Migrate databases with replication
   - Test thoroughly

3. **Decommission old VPC**
   ```bash
   terraform destroy -target=module.vpc_v1
   ```

#### Option 2: In-Place Upgrade (Dev/Test Environments)

1. **Update module source to v2.0**

2. **Run terraform plan**
   ```bash
   terraform plan -out=upgrade.tfplan
   ```

3. **Review plan carefully** - Look for:
   - Resources being destroyed/recreated (NAT Gateways, Route Tables)
   - Changed outputs in dependent modules

4. **Apply during maintenance window**
   ```bash
   terraform apply upgrade.tfplan
   ```

### Post-Migration Steps

1. **Verify Infrastructure**
   - Test internet connectivity from private subnets
   - Verify DNS resolution
   - Check all dependent services

2. **Update Terraform Outputs**
   - Modify consuming modules to use list outputs
   - Example: `module.vpc.nat_gateway_ids[0]` instead of `module.vpc.nat_gateway_id`

3. **Update Documentation**
   - Document new NAT Gateway IPs
   - Update network diagrams
   - Notify teams of changes

### Breaking Change Examples

#### Example 1: Accessing NAT Gateway ID

**Before (v1.x)**:
```hcl
resource "aws_route" "example" {
  nat_gateway_id = module.vpc.nat_gateway_id
}
```

**After (v2.0)**:
```hcl
resource "aws_route" "example" {
  nat_gateway_id = module.vpc.nat_gateway_ids[0]
}
```

#### Example 2: Multi-AZ NAT Gateway

**Before (v1.x)**: Single NAT Gateway
```hcl
module "vpc" {
  source             = "./modules/vpc"
  enable_nat_gateway = true
}
```

**After (v2.0)**: Multi-AZ NAT Gateway
```hcl
module "vpc" {
  source            = "./modules/vpc"
  enable_nat_gateway = true
  nat_gateway_count  = 3  # One per AZ for HA
}
```

### Known Issues

- NAT Gateway recreation causes temporary internet outage for private subnets (typically 2-5 minutes)
- Elastic IP addresses will change, requiring updates to allowlists
- Route table recreation may briefly interrupt routing

### Rollback Procedure

If issues occur during migration:

1. **Restore state file**
   ```bash
   cp terraform.tfstate.backup-v1 terraform.tfstate
   ```

2. **Revert module source to v1.x**

3. **Run terraform plan** to verify state

4. **Apply if necessary**
   ```bash
   terraform apply
   ```

---

## Support

For issues, questions, or feature requests related to version upgrades:
- Review this CHANGELOG for breaking changes
- Check the README for current usage examples
- Test upgrades in non-production environments first
- Plan maintenance windows for production upgrades

## Versioning Policy

- **Major version** (x.0.0): Breaking changes requiring migration
- **Minor version** (2.x.0): New features, backward compatible
- **Patch version** (2.0.x): Bug fixes, backward compatible
