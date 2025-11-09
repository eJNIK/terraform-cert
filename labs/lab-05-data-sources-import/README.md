# Lab 05: Data Sources, Import, and For_Each

## Overview

Learn how to query existing AWS resources with data sources, import unmanaged resources into Terraform, and understand when to use for_each vs count.

**Time Estimate:** 30 minutes

### Exam Objectives Covered

- **12a**: Understand and use data sources
- **12b**: Query AWS resources dynamically
- **13a**: Import existing infrastructure into state
- **13b**: Generate import configuration
- **14a**: Understand for_each meta-argument
- **14b**: Understand count meta-argument
- **14c**: Know when to use for_each vs count
- **15a**: Use depends_on for explicit dependencies

---

## Key Concepts

### Data Sources

**Query existing resources without managing them:**

```hcl
# Query AWS account info
data "aws_caller_identity" "current" {}

# Use in resources
resource "aws_s3_bucket" "example" {
  bucket = "bucket-${data.aws_caller_identity.current.account_id}"
}
```

**Common data sources:**
- `aws_caller_identity` - Account ID, user ARN
- `aws_region` - Current region
- `aws_availability_zones` - Available AZs
- `aws_ami` - AMI lookup
- `aws_vpc` - Existing VPC
- `aws_subnet` - Existing subnet

---

### For_Each vs Count

| Feature | for_each | count |
|---------|----------|-------|
| **Input** | Map or set of strings | Number |
| **Reference** | `resource[key]` | `resource[index]` |
| **Removal** | Safe (by key) | Risky (shifts indexes) |
| **Best for** | Named resources | Identical resources |

**for_each with map:**
```hcl
locals {
  buckets = {
    logs    = { purpose = "Logs" }
    data    = { purpose = "Data" }
    backups = { purpose = "Backups" }
  }
}

resource "aws_s3_bucket" "example" {
  for_each = local.buckets

  bucket = "my-${each.key}-bucket"  # logs, data, backups

  tags = {
    Purpose = each.value.purpose
  }
}

# Reference specific bucket
aws_s3_bucket.example["logs"].id
```

**count with list:**
```hcl
variable "user_names" {
  default = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}

# Reference specific user
aws_iam_user.example[0].name  # alice
```

**When to use what:**
- **for_each**: When resources have distinct identities (environments, services)
- **count**: When creating identical resources (multiple instances of same config)

---

## Lab Steps

### Part 1: Data Sources

**1. Query existing AWS info**
```bash
cd labs/lab-05-data-sources-import
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

**2. View data source outputs**
```bash
terraform apply
terraform output account_id
terraform output available_azs
terraform output amazon_linux_ami
```

**Data sources are read during plan/apply** - no actual resources created for these!

---

### Part 2: For_Each with Maps

**3. Examine S3 buckets with for_each**

Check `main.tf` lines 90-109:
- Creates 3 buckets from map
- Each has unique key (logs, data, backups)
- Selective versioning using filtered for_each

**4. View created buckets**
```bash
terraform output s3_bucket_names
```

Result:
```
{
  "backups" = "jakub.ejnik-backups-us-east-1"
  "data"    = "jakub.ejnik-data-us-east-1"
  "logs"    = "jakub.ejnik-logs-us-east-1"
}
```

**5. Remove one bucket from code**

Edit `main.tf`, remove "data" from buckets map:
```hcl
locals {
  buckets = {
    logs    = { purpose = "Logs", versioning = true }
    # data removed
    backups = { purpose = "Backups", versioning = true }
  }
}
```

```bash
terraform plan
```

Notice: **Only "data" bucket will be destroyed**. "logs" and "backups" remain!

This is why for_each is safer than count.

---

### Part 3: Count with Lists

**6. Examine IAM users**

Check `main.tf` lines 180-190:
- Creates users from list
- Uses count.index to iterate

**7. Add a user**

Edit `terraform.tfvars`:
```hcl
user_names = ["alice", "bob", "charlie", "david"]
```

```bash
terraform plan
```

Only 1 new user created.

**8. Remove middle user (don't apply!)**

Edit to remove "bob":
```hcl
user_names = ["alice", "charlie", "david"]
```

```bash
terraform plan
```

**Problem**: Count shifts indexes!
- Index 1 changes from "bob" → "charlie"
- Index 2 changes from "charlie" → "david"
- Terraform sees this as destroying bob and recreating charlie & david

This is the **count problem**. Don't apply this!

Reset `terraform.tfvars` back.

---

### Part 4: Dynamic Blocks

**9. Examine security groups**

Check `main.tf` lines 148-179:
- for_each creates 3 security groups
- dynamic ingress block creates multiple rules per SG

```hcl
dynamic "ingress" {
  for_each = each.value.ingress_ports  # [80, 443] or [8080, 8443]

  content {
    from_port = ingress.value
    to_port   = ingress.value
    # ...
  }
}
```

**View security groups:**
```bash
terraform output security_group_ids
```

---

### Part 5: Terraform Import

**10. Manually create an S3 bucket**

```bash
BUCKET_NAME="${OWNER_TAG:-jakub.ejnik}-imported-bucket-us-east-1"
aws s3 mb s3://$BUCKET_NAME
aws s3api put-bucket-tagging \
  --bucket $BUCKET_NAME \
  --tagging 'TagSet=[{Key=Owner,Value=jakub.ejnik},{Key=Name,Value=jakub.ejnik-imported-bucket}]'
```

**11. Uncomment import resource in main.tf**

Uncomment lines ~200-209:
```hcl
resource "aws_s3_bucket" "imported" {
  bucket = "${var.owner_tag}-imported-bucket-${data.aws_region.current.name}"

  tags = {
    Name      = "${var.owner_tag}-imported-bucket"
    Imported  = "true"
    CreatedBy = "Manual-Then-Imported"
  }
}
```

**12. Import the bucket**

```bash
terraform import aws_s3_bucket.imported $BUCKET_NAME
```

**13. Verify import**

```bash
terraform state show aws_s3_bucket.imported
terraform plan
```

Plan shows tag updates (Terraform wants to manage tags now).

```bash
terraform apply  # Apply tag updates
```

**14. Now it's fully managed**

```bash
terraform destroy  # Will remove the imported bucket too
```

---

## Import Methods Comparison

### Old Method (what we just did)
```bash
# 1. Write resource config
# 2. Import manually
terraform import aws_s3_bucket.imported bucket-name
```

### New Method (Terraform 1.5+)
```hcl
import {
  to = aws_s3_bucket.imported
  id = "bucket-name"
}
```

```bash
terraform plan -generate-config-out=imported.tf
```

Terraform generates the resource config automatically!

---

## For_Each Advanced Patterns

### Filter with for expression
```hcl
# Only buckets needing versioning
resource "aws_s3_bucket_versioning" "example" {
  for_each = { for k, v in local.buckets : k => v if v.versioning }
  # ...
}
```

### Transform map keys
```hcl
# Create from set of strings
resource "aws_s3_bucket" "example" {
  for_each = toset(["logs", "data", "backups"])

  bucket = "${each.key}-bucket"  # each.value == each.key for sets
}
```

### Nested for_each
```hcl
# Create subnets in multiple AZs
locals {
  subnets = {
    for idx, az in data.aws_availability_zones.available.names :
    "subnet-${idx}" => {
      cidr = cidrsubnet("10.0.0.0/16", 8, idx)
      az   = az
    }
  }
}

resource "aws_subnet" "example" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}
```

---

## Depends_On

**Explicit dependencies** when Terraform can't infer:

```hcl
resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json

  # Explicit: wait for role to be fully created
  depends_on = [aws_iam_role.example]
}
```

**When to use:**
- Resource A needs resource B but doesn't reference it
- Timing issues (IAM eventual consistency)
- Module dependencies

**When NOT to use:**
- If there's already an attribute reference (implicit dependency exists)

---

## Key Differences Summary

### Data Sources vs Resources

| Data Source | Resource |
|-------------|----------|
| Read-only | Managed by Terraform |
| Queries existing | Creates/updates/deletes |
| `data` block | `resource` block |
| No lifecycle | Has lifecycle |

### For_Each vs Count

**Use for_each when:**
- Resources have names/identities
- May add/remove specific items
- Order doesn't matter

**Use count when:**
- Creating N identical things
- Simple numeric loop
- Resources are truly interchangeable

---

## Common Patterns

### Data source for AMI lookup
```hcl
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}
```

### Data source for VPC lookup
```hcl
data "aws_vpc" "selected" {
  tags = {
    Name = "production"
  }
}
```

### For_each with conditions
```hcl
resource "aws_instance" "web" {
  for_each = { for k, v in var.instances : k => v if v.enabled }
  # ...
}
```

---

## Exam Tips

**Data Sources:**
- Understand `data` vs `resource` blocks
- Know common AWS data sources
- Data sources are read during refresh/plan

**Import:**
- Know the import command syntax
- Understand you must write config first
- Aware of new `import` block (1.5+)
- Import only adds to state, doesn't generate config (old method)

**For_Each:**
- Use with maps or sets
- Access via `each.key` and `each.value`
- Safer for removals than count

**Count:**
- Simple numeric iteration
- Access via `count.index`
- Beware of index shifting on removal

**Depends_On:**
- Creates explicit dependencies
- Use sparingly (implicit better)
- Module-level dependencies

---

## Cleanup

```bash
# Remove imported bucket first if needed
aws s3 rb s3://$BUCKET_NAME --force

# Destroy all
terraform destroy
```

---

## Challenge Exercises

### Challenge 1: Data Source Chain
Use `aws_subnet_ids` data source to find all subnets in default VPC, then create security groups in each.

### Challenge 2: Convert Count to For_Each
Convert the IAM users from count to for_each. Compare the difference when removing a user.

### Challenge 3: Conditional Resources
Use for_each with a condition to only create S3 buckets for production environment.

### Challenge 4: Import Existing Security Group
Manually create a security group, then import it into Terraform management.

---

## Key Takeaways

1. **Data sources query, resources manage**
2. **for_each is safer than count for named resources**
3. **Import requires writing config first**
4. **Use dynamic blocks for repeated nested blocks**
5. **depends_on for explicit dependencies only**
6. **For expressions filter and transform collections**

---

## Additional Resources

- [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)
- [For_Each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- [Count](https://developer.hashicorp.com/terraform/language/meta-arguments/count)
- [Import](https://developer.hashicorp.com/terraform/cli/import)
- [Depends_On](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on)
