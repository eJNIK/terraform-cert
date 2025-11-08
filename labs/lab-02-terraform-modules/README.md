# Lab 02: Terraform Modules

## Lab Overview

Welcome to Lab 02! In this lab, you'll learn how to create and use Terraform modules - reusable components that are essential for managing infrastructure at scale. Modules are one of the most important concepts in Terraform and are heavily tested on the certification exam.

You'll create a reusable VPC module and use it to deploy infrastructure, learning how to organize code, pass data between modules, and build composable infrastructure.

### Exam Objectives Covered

This lab aligns with the following HashiCorp Terraform Professional exam objectives:

- **7a**: Understand module structure and requirements
- **7b**: Create and use modules from local and remote sources
- **7c**: Understand module inputs and outputs
- **7d**: Use module composition for complex infrastructure
- **7e**: Understand module versioning
- **4a**: Use input variables in modules
- **4b**: Use output values from modules
- **8a**: Code organization and reusability

### Lab Goals

By the end of this lab, you will:

1. Understand the concept and benefits of Terraform modules
2. Create a reusable VPC module with configurable parameters
3. Use the `cidrsubnet` function for automatic subnet calculation
4. Learn how to pass variables to modules
5. Access module outputs in the root configuration
6. Understand module composition (using modules within modules)
7. Deploy infrastructure using your custom module
8. Learn module best practices and patterns

### Time Estimate

45-60 minutes

---

## Prerequisites

### Required Tools

- **Terraform**: Version 1.0 or later
- **AWS CLI**: Configured with valid credentials
- **Git**: For version control
- **Text Editor**: VS Code, Vim, or your preferred editor

### AWS Prerequisites

1. **AWS Account**: Active AWS account (sandbox account)
2. **AWS Credentials**: Configured via AWS CLI or environment variables
3. **IAM Permissions**: Same as Lab 01 (VPC, subnets, EC2, etc.)

### Prerequisite Knowledge

- Completion of Lab 01 (or equivalent Terraform basics)
- Understanding of VPC networking concepts
- Familiarity with Terraform variables and outputs

### Verify Setup

```bash
# Navigate to the lab directory
cd labs/lab-02-terraform-modules

# Check directory structure
tree -L 2
```

---

## Lab Architecture

This lab creates a **reusable VPC module** and demonstrates its use:

```
┌────────────────────────────────────────────────────────────────┐
│                  Root Module Configuration                      │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │               VPC Module (Reusable)                      │  │
│  │                                                          │  │
│  │  VPC (10.0.0.0/16)                                       │  │
│  │  ├── Public Subnet 1 (10.0.0.0/24) - AZ 1              │  │
│  │  ├── Public Subnet 2 (10.0.1.0/24) - AZ 2              │  │
│  │  ├── Private Subnet 1 (10.0.2.0/24) - AZ 1             │  │
│  │  ├── Private Subnet 2 (10.0.3.0/24) - AZ 2             │  │
│  │  ├── Internet Gateway                                   │  │
│  │  ├── NAT Gateway (optional)                             │  │
│  │  └── Route Tables                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                  │
│                             ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Security Group + EC2 Instance                          │  │
│  │  (Uses VPC Module Outputs)                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

**Module Flow:**
```
Root Module Variables
        ↓
   VPC Module (modules/vpc/)
        ↓
 Module Outputs (vpc_id, subnet_ids, etc.)
        ↓
Root Module Resources (EC2, Security Groups)
        ↓
   Root Module Outputs
```

---

## File Structure

```
lab-02-terraform-modules/
├── main.tf                        # Root module - uses VPC module
├── variables.tf                   # Root module variables
├── outputs.tf                     # Root module outputs
├── terraform.tfvars.example       # Example variable values
├── README.md                      # This file
└── modules/
    └── vpc/                       # VPC module (reusable)
        ├── main.tf                # VPC module resources
        ├── variables.tf           # Module input variables
        ├── outputs.tf             # Module output values
        └── README.md              # Module documentation
```

---

## Understanding Modules

### What is a Terraform Module?

A **module** is a container for multiple resources that are used together. Every Terraform configuration has at least one module, called the **root module**, which consists of the `.tf` files in the main working directory.

### Benefits of Modules

1. **Reusability**: Write once, use many times
2. **Organization**: Group related resources together
3. **Encapsulation**: Hide complexity behind a simple interface
4. **Consistency**: Ensure standard configurations across environments
5. **Testing**: Test modules independently
6. **Collaboration**: Share modules across teams

### Module Types

1. **Local Modules**: Stored in subdirectories (like our `./modules/vpc`)
2. **Registry Modules**: From Terraform Registry (`terraform-aws-modules/vpc/aws`)
3. **Git Modules**: From Git repositories
4. **HTTP Modules**: From HTTP URLs

### Module Structure

A basic module contains:
- **main.tf**: Resource definitions
- **variables.tf**: Input variables
- **outputs.tf**: Output values
- **README.md**: Documentation (best practice)

---

## Step-by-Step Instructions

### Step 1: Explore the Module Structure

Before running anything, understand the code structure:

1. **Review the VPC Module** (`modules/vpc/`):
   ```bash
   cat modules/vpc/variables.tf    # See what inputs the module accepts
   cat modules/vpc/outputs.tf      # See what data the module exposes
   cat modules/vpc/main.tf         # See the resources it creates
   ```

2. **Review the Root Module**:
   ```bash
   cat main.tf                     # See how the module is used
   cat variables.tf                # Root level variables
   cat outputs.tf                  # How we access module outputs
   ```

**Key Concepts to Notice:**
- How `main.tf` uses `module "vpc" { source = "./modules/vpc" }`
- How variables are passed to the module
- How module outputs are referenced: `module.vpc.vpc_id`
- The `cidrsubnet` function for automatic subnet calculation

### Step 2: Understand the cidrsubnet Function

The VPC module uses `cidrsubnet` to automatically calculate subnet CIDRs:

```hcl
cidrsubnet(var.vpc_cidr, 8, count.index)
```

**How it works:**
- **VPC**: `10.0.0.0/16` (65,536 IPs)
- **Calculation**: Extends /16 to /24 (adding 8 bits)
- **Result**:
  - Index 0: `10.0.0.0/24`
  - Index 1: `10.0.1.0/24`
  - Index 2: `10.0.2.0/24`
  - Index 3: `10.0.3.0/24`

**Try it in terraform console:**
```bash
terraform console
> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
> exit
```

### Step 3: Configure Your Variables

Create your variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

For a **cost-effective deployment** (recommended for learning):
```hcl
enable_nat_gateway = false
private_subnet_count = 0  # Or keep at 2 if you want to practice
```

For a **full production-like setup** (costs ~$32/month):
```hcl
enable_nat_gateway = true
nat_gateway_count = 2
```

### Step 4: Initialize Terraform

Initialize the working directory. This will download providers and initialize modules:

```bash
terraform init
```

**What Happened?**
- Downloaded AWS provider
- Initialized the local VPC module
- Created `.terraform/modules` directory

**Examine module initialization:**
```bash
ls -la .terraform/modules/
cat .terraform/modules/modules.json
```

### Step 5: Validate and Format

```bash
terraform fmt -recursive    # Format all .tf files including modules
terraform validate          # Validate configuration
```

### Step 6: Preview the Plan

```bash
terraform plan
```

**What to Look For:**

**Without NAT Gateway** (default):
- Should show approximately **10-11 resources** to create:
  - 1 VPC
  - 1 Internet Gateway
  - 2 Public Subnets
  - 2 Private Subnets
  - 1 Public Route Table
  - 2 Private Route Tables
  - 5 Route Table Associations
  - 1 Security Group
  - 1 EC2 Instance

**With NAT Gateway** (if enabled):
- Add 2 NAT Gateways + 2 Elastic IPs = **13-14 resources**

### Step 7: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Expected Output:**
```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

deployment_summary = {
  vpc_id = "vpc-xxxxx"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_count = 2
  private_subnet_count = 2
  nat_gateways = 0
  instance_id = "i-xxxxx"
  web_url = "http://xx.xx.xx.xx"
}
instance_public_ip = "xx.xx.xx.xx"
public_subnet_azs = [
  "us-east-1a",
  "us-east-1b",
]
vpc_id = "vpc-xxxxx"
web_server_url = "http://xx.xx.xx.xx"
```

### Step 8: Verify Module Outputs

Modules expose data through outputs. See how to access them:

```bash
# View all outputs
terraform output

# View specific module output
terraform output vpc_id
terraform output public_subnet_ids

# View the summary
terraform output deployment_summary
```

**Understanding Output References:**
- In `outputs.tf`, notice: `value = module.vpc.vpc_id`
- This accesses the `vpc_id` output from the VPC module
- Format: `module.<module_name>.<output_name>`

### Step 9: Test the Web Server

```bash
# Get the web URL
terraform output web_server_url

# Test the server
curl $(terraform output -raw instance_public_ip)
```

You should see HTML showing the module was successfully deployed!

### Step 10: Explore the State

```bash
# List all resources including module resources
terraform state list

# Notice module resources are prefixed with module.vpc
# For example: module.vpc.aws_vpc.main
```

**Expected Resources:**
```
module.vpc.aws_internet_gateway.main
module.vpc.aws_route_table.public
module.vpc.aws_route_table.private[0]
module.vpc.aws_route_table.private[1]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_vpc.main
aws_instance.web_server
aws_security_group.web_sg
```

### Step 11: Inspect Module Resources

```bash
# View module VPC details
terraform state show module.vpc.aws_vpc.main

# View module subnet details
terraform state show 'module.vpc.aws_subnet.public[0]'

# Compare with root resource
terraform state show aws_instance.web_server
```

Notice how module resources are namespaced under `module.vpc`.

### Step 12: Experiment with Module Parameters

Try modifying the module configuration to see how it adapts:

**Option A: Change Subnet Count**

Edit `terraform.tfvars`:
```hcl
public_subnet_count = 3
```

Then run:
```bash
terraform plan
```

You'll see Terraform plans to add another public subnet!

**Option B: Enable NAT Gateway** (if you want to spend ~$32/month)

Edit `terraform.tfvars`:
```hcl
enable_nat_gateway = true
nat_gateway_count = 1
```

Run `terraform plan` to see what would be added.

**Don't apply** unless you want the costs. Just seeing the plan demonstrates module flexibility!

### Step 13: Clean Up

When you're done exploring:

```bash
terraform destroy
```

Type `yes` when prompted.

**Expected Output:**
```
Destroy complete! Resources: 11 destroyed.
```

---

## Validation and Testing

### Checklist

- [ ] `terraform init` completed successfully
- [ ] Module initialized (check `.terraform/modules/`)
- [ ] `terraform validate` shows no errors
- [ ] `terraform fmt -recursive` formats all files
- [ ] `terraform plan` shows correct resource count
- [ ] Can see module resources in plan output
- [ ] `terraform apply` completed without errors
- [ ] All module outputs accessible
- [ ] VPC created with correct CIDR
- [ ] Subnets created in multiple AZs
- [ ] EC2 instance deployed to module subnet
- [ ] Can access web page
- [ ] Module resources visible in `terraform state list`
- [ ] Tags properly applied
- [ ] `terraform destroy` removed all resources

### Common Issues and Troubleshooting

**Issue**: "Module not found"
- **Solution**: Run `terraform init` to initialize the module
- Ensure the `source` path in main.tf is correct: `./modules/vpc`

**Issue**: "Error: Reference to undeclared output value"
- **Solution**: Check that the output exists in `modules/vpc/outputs.tf`
- Verify you're using correct syntax: `module.vpc.<output_name>`

**Issue**: "Too many subnets requested"
- **Solution**: Reduce subnet count in terraform.tfvars
- Ensure total subnets fit within VPC CIDR range

**Issue**: Module changes not applied
- **Solution**: Run `terraform init -upgrade` to reinitialize modules
- Run `terraform get` to update module code

---

## Key Concepts Explained

### Module Syntax

**Declaring a Module:**
```hcl
module "vpc" {
  source = "./modules/vpc"  # Required

  # Input variables
  name_prefix = var.owner_tag
  vpc_cidr    = var.vpc_cidr

  # ... other inputs
}
```

**Accessing Module Outputs:**
```hcl
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
  # Format: module.<name>.<output>
}
```

### Module Source Types

```hcl
# Local path
module "vpc" {
  source = "./modules/vpc"
}

# Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}

# GitHub
module "vpc" {
  source = "github.com/your-org/terraform-vpc-module"
}

# Git with specific ref
module "vpc" {
  source = "git::https://github.com/your-org/vpc.git?ref=v1.0.0"
}
```

### Module Variables vs Root Variables

**Module Variables** (`modules/vpc/variables.tf`):
- Define what inputs the module accepts
- Used within the module

**Root Variables** (`variables.tf`):
- Define configuration for the entire deployment
- Can be passed to modules

**Example Flow:**
```
terraform.tfvars → Root variables.tf → Module variables
```

### Module Outputs

**Purpose:**
1. Expose resource attributes to calling module
2. Pass data between modules
3. Display information to users

**Example:**
```hcl
# In modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

# In root outputs.tf
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

### The count Meta-Argument with Modules

The VPC module uses `count` to create multiple subnets:

```hcl
resource "aws_subnet" "public" {
  count = var.public_subnet_count

  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  # count.index: 0, 1, 2, ...
}
```

**Accessing with Splat Expression:**
```hcl
output "public_subnet_ids" {
  value = aws_subnet.public[*].id  # Returns a list
}
```

### Module Composition

Modules can use other modules (not shown in this lab but important for exam):

```hcl
module "vpc" {
  source = "./modules/vpc"
}

module "app" {
  source = "./modules/application"

  vpc_id     = module.vpc.vpc_id      # Pass output from one module
  subnet_ids = module.vpc.subnet_ids  # to another module
}
```

---

## Challenge Exercises

### Challenge 1: Add a Bastion Module

Create a new module `modules/bastion` that:
- Accepts VPC ID and public subnet ID as inputs
- Creates a bastion host security group
- Launches a bastion EC2 instance
- Outputs the bastion's public IP

**Hints:**
- Copy the module structure from `modules/vpc`
- Define clear input variables
- Use the module in main.tf

### Challenge 2: Modify Subnet CIDR Calculation

Change the `cidrsubnet` function to create /25 subnets instead of /24.

**Hints:**
- Modify `modules/vpc/main.tf`
- Change the second argument to `cidrsubnet`
- Run `terraform plan` to see the changes

### Challenge 3: Add Module Version

Document the module version and create a CHANGELOG.

**Hints:**
- Add version info to `modules/vpc/README.md`
- Create `modules/vpc/CHANGELOG.md`
- Document breaking changes

### Challenge 4: Use a Registry Module

Replace the local VPC module with one from the Terraform Registry.

**Hints:**
- Find the official AWS VPC module on registry.terraform.io
- Update the `source` and `version` in main.tf
- Map your variables to the module's expected inputs

### Challenge 5: Create a Database Subnet Group Module

Create a module that creates database subnet groups for RDS.

**Hints:**
- Use `aws_db_subnet_group` resource
- Accept private subnet IDs as input
- Output the subnet group name

---

## Additional Resources

### Terraform Documentation
- [Modules Overview](https://developer.hashicorp.com/terraform/language/modules)
- [Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
- [Publishing Modules](https://developer.hashicorp.com/terraform/registry/modules/publish)
- [Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)

### Terraform Registry
- [Browse Public Modules](https://registry.terraform.io/browse/modules)
- [AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

### Functions Used
- [cidrsubnet](https://developer.hashicorp.com/terraform/language/functions/cidrsubnet)
- [merge](https://developer.hashicorp.com/terraform/language/functions/merge)
- [distinct](https://developer.hashicorp.com/terraform/language/functions/distinct)

---

## Next Steps

Congratulations on completing Lab 02! You now understand:
- How to create reusable modules
- Module inputs and outputs
- Module composition and organization
- Using functions like `cidrsubnet` for dynamic configuration

**What's Next?**
- Lab 03 will cover Remote State Management (S3 + DynamoDB)
- Lab 04 will introduce Workspaces for multi-environment deployments
- Lab 05 will build on modules with more advanced networking

---

## Questions for Reflection

1. What are the main benefits of using modules?
2. How do you reference a module output in the root configuration?
3. What does the `cidrsubnet` function do, and why is it useful?
4. What's the difference between module variables and root variables?
5. How would you version a module for team collaboration?
6. What happens when you run `terraform init` with modules?
7. How do you update a module after making changes to its code?
8. What's the difference between local modules and registry modules?
9. When would you use `count` vs `for_each` in a module?
10. How can you test a module independently before using it?

Think about these questions and discuss with your tutor if you need clarification!
