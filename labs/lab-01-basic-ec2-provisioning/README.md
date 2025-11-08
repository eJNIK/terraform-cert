# Lab 01: Basic EC2 Provisioning with Terraform

## Lab Overview

Welcome to your first hands-on Terraform lab! In this lab, you'll learn the fundamentals of Infrastructure as Code (IaC) by provisioning a complete AWS networking stack including a VPC, subnet, internet gateway, security group, and EC2 instance using Terraform.

### Exam Objectives Covered

This lab aligns with the following HashiCorp Terraform Professional exam objectives:

- **1a**: Understand the purpose and benefits of Infrastructure as Code
- **2a**: Understand Terraform basics and workflow (init, plan, apply, destroy)
- **3a**: Configure providers
- **3b**: Create and manage resources
- **3c**: Understand resource dependencies and ordering
- **4a**: Use input variables with validation
- **4b**: Use output values
- **5a**: Understand data sources
- **6a**: Understand AWS VPC networking basics

### Lab Goals

By the end of this lab, you will:

1. Initialize a Terraform working directory
2. Configure the AWS provider
3. Create a VPC from scratch (no default VPC needed)
4. Set up networking components (subnet, internet gateway, route table)
5. Create a security group with ingress/egress rules
6. Launch an EC2 instance in your custom VPC
7. Use variables to parameterize your configuration
8. Extract information using outputs
9. Understand resource dependencies and the Terraform workflow
10. Understand the Terraform state management

### Time Estimate

30-45 minutes

---

## Prerequisites

### Required Tools

- **Terraform**: Version 1.0 or later ([Installation Guide](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI**: Configured with valid credentials ([Installation Guide](https://aws.amazon.com/cli/))
- **Git**: For version control
- **Text Editor**: VS Code, Vim, or your preferred editor

### AWS Prerequisites

1. **AWS Account**: Active AWS account (sandbox account in your case)
2. **AWS Credentials**: Configured via AWS CLI or environment variables
3. **IAM Permissions**: Ability to create VPCs, subnets, internet gateways, route tables, EC2 instances, security groups, and describe AMIs

### Verify Setup

```bash
# Check Terraform installation
terraform version

# Check AWS credentials
aws sts get-caller-identity

# Navigate to the lab directory
cd labs/lab-01-basic-ec2-provisioning
```

---

## Lab Architecture

This lab creates the following AWS resources (7 resources total):

```
┌────────────────────────────────────────────────────────────┐
│                    AWS Region (us-east-1)                  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           VPC (10.0.0.0/16)                          │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Public Subnet (10.0.1.0/24)                   │  │  │
│  │  │  AZ: us-east-1a                                │  │  │
│  │  │                                                │  │  │
│  │  │  ┌──────────────────────────────────────────┐  │  │  │
│  │  │  │  Security Group                          │  │  │  │
│  │  │  │  - Ingress: SSH (22)                     │  │  │  │
│  │  │  │  - Ingress: HTTP (80)                    │  │  │  │
│  │  │  │  - Egress: All traffic                   │  │  │  │
│  │  │  └──────────────────────────────────────────┘  │  │  │
│  │  │                    │                          │  │  │
│  │  │                    ▼                          │  │  │
│  │  │  ┌──────────────────────────────────────────┐  │  │  │
│  │  │  │  EC2 Instance (t2.micro)                 │  │  │  │
│  │  │  │  - Amazon Linux 2023                     │  │  │  │
│  │  │  │  - Apache Web Server                     │  │  │  │
│  │  │  │  - Public IP: Auto-assigned              │  │  │  │
│  │  │  └──────────────────────────────────────────┘  │  │  │
│  │  │                                                │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Route Table                                   │  │  │
│  │  │  Route: 0.0.0.0/0 → Internet Gateway          │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                          │                           │  │
│  └──────────────────────────┼───────────────────────────┘  │
│                             │                              │
│                             ▼                              │
│              ┌──────────────────────────┐                  │
│              │  Internet Gateway        │                  │
│              └──────────────────────────┘                  │
│                             │                              │
└─────────────────────────────┼──────────────────────────────┘
                              │
                              ▼
                         Internet
```

**Resource Breakdown:**
1. VPC
2. Internet Gateway
3. Public Subnet
4. Route Table
5. Route Table Association
6. Security Group
7. EC2 Instance

---

## File Structure

```
lab-01-basic-ec2-provisioning/
├── main.tf                    # Main configuration file
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── terraform.tfvars.example   # Example variable values
└── README.md                  # This file
```

---

## Step-by-Step Instructions

### Step 1: Review the Configuration Files

Before running any commands, take time to understand what each file does:

1. **main.tf**: Contains the provider configuration, data sources, and resource definitions
   - Review the `terraform` block and required providers
   - Examine the `aws_security_group` resource and its rules
   - Study the `aws_instance` resource and user data script

2. **variables.tf**: Defines input variables with descriptions, types, defaults, and validations
   - Notice how validation blocks ensure correct values
   - Understand the purpose of each variable

3. **outputs.tf**: Defines what information to display after deployment
   - See how outputs reference resource attributes

### Step 2: Configure Your Variables

Create your own variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize values (if needed):

```hcl
aws_region    = "us-east-1"
owner_tag     = "jakub.ejnik"
environment   = "dev"
instance_type = "t2.micro"
allowed_ssh_cidr = ["0.0.0.0/0"]  # Consider restricting to your IP
```

**Security Tip**: For better security, restrict SSH access to your IP address:
```bash
# Get your public IP
curl ifconfig.me

# Update terraform.tfvars
allowed_ssh_cidr = ["YOUR_IP/32"]
```

### Step 3: Initialize Terraform

Initialize your Terraform working directory. This downloads the AWS provider:

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

**What Happened?**
- Downloaded the AWS provider plugin
- Created `.terraform` directory
- Created `.terraform.lock.hcl` file for provider version locking

### Step 4: Format Your Code (Best Practice)

Format your Terraform files to follow standard conventions:

```bash
terraform fmt
```

This command automatically formats your `.tf` files with proper indentation and styling.

### Step 5: Validate Your Configuration

Check for syntax errors and configuration issues:

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

If you see errors, review the error messages and fix any issues before proceeding.

### Step 6: Preview Your Changes

Generate and review an execution plan:

```bash
terraform plan
```

**What to Look For:**
- Number of resources to be created (should be 7: VPC, IGW, subnet, route table, route table association, security group, and EC2 instance)
- The AMI ID that will be used (data source result)
- Security group rules
- Instance configuration details
- The `+` symbol indicates resources to be created

**Understanding the Output:**
```
Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block           = "10.0.0.0/16"
      ...
    }

  # aws_internet_gateway.main will be created
  # aws_subnet.public will be created
  # aws_route_table.public will be created
  # aws_route_table_association.public will be created

  # aws_security_group.web_sg will be created
  + resource "aws_security_group" "web_sg" {
      + name                   = "jakub.ejnik-web-server-sg"
      ...
    }

  # aws_instance.web_server will be created
  + resource "aws_instance" "web_server" {
      + ami                          = "ami-xxxxxxxxx"
      + instance_type                = "t2.micro"
      ...
    }

Plan: 7 to add, 0 to change, 0 to destroy.
```

### Step 7: Apply Your Configuration

Create the infrastructure:

```bash
terraform apply
```

Review the plan again, then type `yes` when prompted.

**Expected Output:**
```
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

ami_id = "ami-0c55b159cbfafe1f0"
instance_id = "i-0123456789abcdef"
instance_public_dns = "ec2-xx-xx-xx-xx.compute-1.amazonaws.com"
instance_public_ip = "xx.xx.xx.xx"
instance_state = "running"
internet_gateway_id = "igw-0123456789abcdef"
public_subnet_id = "subnet-0123456789abcdef"
security_group_id = "sg-0123456789abcdef"
security_group_name = "jakub.ejnik-web-server-sg"
ssh_command = "ssh -i <your-key.pem> ec2-user@xx.xx.xx.xx"
vpc_cidr = "10.0.0.0/16"
vpc_id = "vpc-0123456789abcdef"
web_server_url = "http://xx.xx.xx.xx"
```

**What Happened?**
- Terraform created the VPC
- Terraform created the Internet Gateway and attached it to the VPC
- Terraform created the public subnet
- Terraform created the route table and associated it with the subnet
- Terraform created the security group
- Terraform launched the EC2 instance in the public subnet
- Created `terraform.tfstate` file to track your infrastructure
- User data script installed Apache and created a web page

### Step 8: Verify Your Deployment

1. **Check the Web Server**:
   ```bash
   # Get the public IP from outputs
   terraform output instance_public_ip

   # Test the web server (may take 2-3 minutes for user data to complete)
   curl http://$(terraform output -raw instance_public_ip)
   ```

   Or open the URL in your browser:
   ```bash
   echo "http://$(terraform output -raw instance_public_ip)"
   ```

2. **View All Outputs**:
   ```bash
   terraform output
   ```

3. **View Specific Output**:
   ```bash
   terraform output instance_id
   terraform output web_server_url
   ```

4. **Verify in AWS Console**:
   - Navigate to EC2 Dashboard
   - Check your instance is running
   - Review the security group rules
   - Verify tags are applied correctly

### Step 9: Inspect the State File

View the current state:

```bash
terraform show
```

List resources in state:

```bash
terraform state list
```

**Expected Output:**
```
data.aws_ami.amazon_linux_2023
data.aws_availability_zones.available
aws_instance.web_server
aws_internet_gateway.main
aws_route_table.public
aws_route_table_association.public
aws_security_group.web_sg
aws_subnet.public
aws_vpc.main
```

View specific resource details:

```bash
terraform state show aws_instance.web_server
```

### Step 10: Make a Change (Experiment)

Try modifying your infrastructure to learn how Terraform handles changes:

**Option A: Update Tags**

Edit `main.tf` and add a custom tag to the EC2 instance:

```hcl
resource "aws_instance" "web_server" {
  # ... existing configuration ...

  tags = {
    Name        = "${var.owner_tag}-web-server"
    Description = "My first Terraform instance"  # Add this line
  }
}
```

Run:
```bash
terraform plan   # See the proposed change
terraform apply  # Apply the change
```

Notice how Terraform shows `~` (update in-place) instead of `+` (create).

**Option B: Change Instance Type** (This will recreate the instance)

Update `terraform.tfvars`:
```hcl
instance_type = "t2.small"
```

Run:
```bash
terraform plan
```

Notice the `-/+` symbol indicating the instance will be replaced. **Don't apply this if you want to stay in Free Tier!**

### Step 11: Clean Up

When you're done, destroy all resources to avoid charges:

```bash
terraform destroy
```

Review the destruction plan and type `yes` when prompted.

**Expected Output:**
```
Destroy complete! Resources: 7 destroyed.
```

Verify in AWS Console that resources are terminated/deleted.

---

## Validation and Testing

### Checklist

- [ ] `terraform init` completed successfully
- [ ] `terraform validate` shows no errors
- [ ] `terraform plan` shows 7 resources to create
- [ ] `terraform apply` completed without errors
- [ ] VPC created with correct CIDR block (10.0.0.0/16)
- [ ] Public subnet created in the VPC
- [ ] Internet Gateway attached to VPC
- [ ] Can access web page at the instance's public IP
- [ ] Web page displays "Hello from Terraform Lab 01!"
- [ ] All outputs display correct information
- [ ] Tags are properly applied (Owner: jakub.ejnik)
- [ ] `terraform destroy` removed all resources

### Common Issues and Troubleshooting

**Issue**: "Error: No valid credential sources found"
- **Solution**: Configure AWS credentials using `aws configure` or set environment variables:
  ```bash
  export AWS_ACCESS_KEY_ID="your_access_key"
  export AWS_SECRET_ACCESS_KEY="your_secret_key"
  ```

**Issue**: "Error: creating EC2 Instance: UnauthorizedOperation"
- **Solution**: Ensure your IAM user/role has the necessary permissions

**Issue**: Web server not responding
- **Solution**: Wait 2-3 minutes for user data script to complete. Check security group rules allow HTTP (port 80)

**Issue**: "Error: acquiring the state lock"
- **Solution**: Another process is using the state file. Wait for it to complete or break the lock if necessary

---

## Key Concepts Explained

### Terraform Workflow

The core Terraform workflow consists of:

1. **Write**: Author infrastructure as code
2. **Init**: Initialize the working directory
3. **Plan**: Preview changes before applying
4. **Apply**: Create or update infrastructure
5. **Destroy**: Remove infrastructure when no longer needed

### State Management

Terraform stores the state of your infrastructure in `terraform.tfstate`:
- Tracks resource mappings
- Stores resource attributes
- Enables collaboration (when using remote state)
- **Never manually edit this file!**

### Provider Configuration

The provider block tells Terraform which cloud provider to use:
- AWS in our case
- Requires authentication (credentials)
- Can be configured with default tags

### Resource Dependencies

Terraform automatically determines the correct order to create resources based on dependencies:
- **Implicit dependencies**: Terraform detects when one resource references another (e.g., security group references VPC ID)
- **Dependency chain**: VPC → Internet Gateway → Subnet → Route Table → Security Group → EC2 Instance
- **Parallel execution**: Resources without dependencies are created concurrently for efficiency
- **Explicit dependencies**: Use `depends_on` when Terraform can't automatically detect the relationship

**Example from our lab:**
```
EC2 Instance depends on → Security Group
Security Group depends on → VPC
Subnet depends on → VPC
Route Table depends on → Internet Gateway → VPC
```

### VPC Networking Basics

Understanding AWS VPC components created in this lab:
- **VPC**: Isolated virtual network in AWS (like your own data center)
- **CIDR Block**: IP address range for your VPC (10.0.0.0/16 = 65,536 addresses)
- **Subnet**: Segment of the VPC's IP range (10.0.1.0/24 = 256 addresses)
- **Internet Gateway**: Allows communication between VPC and the internet
- **Route Table**: Defines rules for routing network traffic
- **Public Subnet**: Subnet with a route to the internet gateway

### Data Sources

Data sources allow Terraform to fetch information from AWS:
- `aws_ami` data source finds the latest Amazon Linux AMI
- `aws_availability_zones` finds available AZs in the region
- Read-only operations
- Don't create or modify resources

### Variables

Variables make configurations reusable:
- **Input variables**: Parameterize your configuration
- **Variable types**: string, number, bool, list, map, object
- **Validation blocks**: Ensure correct values
- **Default values**: Optional fallback values

### Outputs

Outputs expose information about your infrastructure:
- Display after `terraform apply`
- Can be queried with `terraform output`
- Useful for passing data between modules

---

## Challenge Exercises

Ready to test your understanding? Try these challenges:

### Challenge 1: Add HTTPS Support

Modify the security group to allow HTTPS traffic (port 443).

**Hints:**
- Add a new `ingress` block to the `aws_security_group` resource
- Use port 443
- CIDR blocks should be `["0.0.0.0/0"]`

### Challenge 2: Parameterize the Security Group Rules

Create a variable for allowed HTTP CIDR blocks (similar to `allowed_ssh_cidr`).

**Hints:**
- Add a new variable in `variables.tf`
- Use `type = list(string)`
- Update the HTTP ingress rule to use this variable

### Challenge 3: Add More Outputs

Create outputs for:
- The availability zone where the instance is running
- The private IP address of the instance
- The ARN of the instance

**Hints:**
- Explore `aws_instance` resource attributes in Terraform docs
- Format: `aws_instance.web_server.<attribute>`

### Challenge 4: Explore the State File

Answer these questions by inspecting the state:
- What is the ID of your security group?
- What is the private IP of your instance?
- What are all the tags applied to your instance?

**Hints:**
- Use `terraform show` or `terraform state show <resource>`
- The state file is JSON and can be viewed with `cat terraform.tfstate | jq`

---

## Additional Resources

### Terraform Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EC2 Instance Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Security Group Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)

### AWS Documentation
- [Amazon EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)

---

## Next Steps

Congratulations on completing Lab 01! You've learned the fundamentals of Terraform and successfully provisioned AWS infrastructure.

**What's Next?**
- Lab 02 will cover Terraform modules and code organization
- Lab 03 will introduce state management and remote backends
- Lab 04 will explore workspaces and multi-environment deployments

**Before Moving On:**
- Ensure you've destroyed all resources (`terraform destroy`)
- Review any concepts that were unclear
- Try the challenge exercises
- Ask questions if you're stuck!

---

## Questions for Reflection

1. What's the difference between `terraform plan` and `terraform apply`?
2. Why do we use variables instead of hardcoding values?
3. What happens to the state file when you run `terraform destroy`?
4. How does Terraform know what resources already exist in AWS?
5. What's the purpose of the `data` block for the AMI?
6. Why does the EC2 instance need to be in a subnet, and why did we make it a public subnet?
7. What would happen if you tried to create the EC2 instance before the VPC was created?
8. How does Terraform determine the order in which to create resources?
9. What's the purpose of the Internet Gateway, and why is it necessary?
10. What's the difference between a VPC CIDR block and a subnet CIDR block?

Think about these questions and discuss with your tutor if you need clarification!
