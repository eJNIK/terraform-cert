# Lab 04: Terraform Workspaces

## Overview

Learn how to manage multiple environments (dev, staging, prod) using Terraform workspaces - a lightweight way to maintain separate state files without duplicating code.

**Time Estimate:** 25 minutes

### Exam Objectives Covered

- **11a**: Understand Terraform workspaces
- **11b**: Create and switch between workspaces
- **11c**: Use workspace-specific configuration
- **11d**: Understand workspace state isolation
- **11e**: Know when to use workspaces vs separate configurations

---

## What Are Workspaces?

**Workspaces** allow you to manage multiple instances of the same infrastructure with separate state files.

### Default Workspace

Every Terraform configuration starts with the `default` workspace.

```bash
terraform workspace show
# Output: default
```

### Additional Workspaces

Create workspaces for different environments:

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

Each workspace has its own state file!

---

## Workspaces vs Other Approaches

| Approach | Pros | Cons | Use Case |
|----------|------|------|----------|
| **Workspaces** | Same code, lightweight | Limited customization | Similar environments |
| **Directories** | Full isolation | Code duplication | Different architectures |
| **Branches** | Git-based | Complex workflow | Experimental changes |
| **Terragrunt** | DRY, powerful | Extra tool | Complex multi-env |

**This lab uses workspaces** - best for environments with minor differences.

---

## How This Lab Works

### Environment Configuration

The lab uses a **map** in locals to define environment-specific settings:

```hcl
locals {
  workspace_config = {
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
      vpc_cidr       = "10.0.0.0/16"
      enable_monitoring = false
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
      vpc_cidr       = "10.1.0.0/16"
      enable_monitoring = true
    }
    prod = {
      instance_type  = "t2.medium"
      instance_count = 3
      vpc_cidr       = "10.2.0.0/16"
      enable_monitoring = true
    }
  }

  # Select config based on current workspace
  env = lookup(local.workspace_config, terraform.workspace, local.workspace_config.dev)
}
```

### Workspace-Aware Naming

```hcl
locals {
  name_prefix = "${var.owner_tag}-${terraform.workspace}"
}

# Results in: jakub.ejnik-dev, jakub.ejnik-staging, jakub.ejnik-prod
```

### Dynamic Resource Creation

```hcl
resource "aws_instance" "web" {
  count         = local.env.instance_count  # 1 for dev, 2 for staging, 3 for prod
  instance_type = local.env.instance_type   # t2.micro, t2.small, or t2.medium
  # ...
}
```

---

## Lab Steps

### 1. Initialize and Deploy Default Workspace

```bash
cd labs/lab-04-workspaces
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

You're in the `default` workspace. Check the deployment:

```bash
terraform output deployment_summary
```

You'll see the **dev configuration** (1 instance, t2.micro).

### 2. Create and Switch to Dev Workspace

```bash
# Create dev workspace
terraform workspace new dev

# Deploy dev environment
terraform apply
```

Same configuration as default, but **separate state file**.

### 3. Create Staging Workspace

```bash
terraform workspace new staging
terraform apply
```

This creates:
- **2 instances** (not 1)
- **t2.small** (not t2.micro)
- **10.1.0.0/16 VPC** (not 10.0.0.0/16)
- **Monitoring enabled**

```bash
terraform output deployment_summary
```

### 4. Create Production Workspace

```bash
terraform workspace new prod
terraform apply
```

This creates:
- **3 instances**
- **t2.medium**
- **10.2.0.0/16 VPC**
- **Monitoring enabled**

### 5. List All Workspaces

```bash
terraform workspace list
```

Output:
```
  default
  dev
  staging
* prod
```

The `*` shows current workspace.

### 6. Switch Between Workspaces

```bash
# Switch to dev
terraform workspace select dev
terraform output deployment_summary

# Switch to staging
terraform workspace select staging
terraform output deployment_summary

# Switch to prod
terraform workspace select prod
terraform output deployment_summary
```

Notice each has different configuration!

### 7. View Workspace State Files

```bash
# State files are stored separately
ls -la terraform.tfstate.d/

# Output:
# dev/
# staging/
# prod/
```

Each directory has its own `terraform.tfstate`.

### 8. Inspect AWS Console

Login to AWS Console and see:
- **3 separate VPCs** (10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16)
- **6 total instances** (1 + 2 + 3)
- Resources tagged with workspace name

### 9. Test Workspace Isolation

```bash
# In staging workspace
terraform workspace select staging
terraform destroy  # Only destroys staging resources!

# Dev and prod remain untouched
terraform workspace select dev
terraform state list  # Still has resources
```

### 10. Cleanup All Workspaces

```bash
# Must destroy each workspace separately
terraform workspace select prod
terraform destroy

terraform workspace select staging
terraform destroy  # Already destroyed in step 9

terraform workspace select dev
terraform destroy

terraform workspace select default
terraform destroy

# Delete empty workspaces
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod
```

---

## Key Workspace Commands

```bash
# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new <name>

# Switch to workspace
terraform workspace select <name>

# Delete workspace (must be empty)
terraform workspace delete <name>
```

---

## Using terraform.workspace

The `terraform.workspace` variable contains the current workspace name:

```hcl
# In tags
tags = {
  Environment = terraform.workspace
}

# In resource names
name = "${var.prefix}-${terraform.workspace}-instance"

# In conditionals
count = terraform.workspace == "prod" ? 3 : 1

# In locals
locals {
  env_config = var.environment_configs[terraform.workspace]
}
```

---

## Best Practices

### ✅ DO

- Use workspaces for **similar environments** with minor differences
- Keep workspace configuration in **maps or objects**
- Use `terraform.workspace` for naming and tagging
- Document which workspaces exist
- Have a clear workspace naming convention

### ❌ DON'T

- Use workspaces for **completely different infrastructure**
- Rely on workspace names in critical logic (easy to forget which workspace you're in)
- Share workspaces across teams
- Use workspaces as a substitute for version control
- Forget which workspace you're in before running `apply` or `destroy`

---

## Workspace Limitations

1. **No variables in workspace selection** - Can't parameterize which workspace to use
2. **Human error prone** - Easy to apply to wrong workspace
3. **Limited differences** - Best for minor variations, not major architectural changes
4. **State storage** - All workspace states stored in same backend (just different paths)
5. **Visibility** - Hard to see all workspaces at once

---

## Alternative Patterns

### Pattern 1: Directory per Environment

```
terraform/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

**Better for:** Completely different configurations per environment.

### Pattern 2: Modules with Different Inputs

```
terraform/
├── modules/
│   └── app/
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

```bash
terraform apply -var-file=environments/dev.tfvars
```

**Better for:** Shared modules with environment-specific variables.

### Pattern 3: Terragrunt

Uses DRY principles with directory structure + workspace isolation.

**Better for:** Large, complex multi-environment setups.

---

## Remote State with Workspaces

When using remote state (S3), each workspace gets a separate state file:

```
s3://bucket/
├── env:/dev/terraform.tfstate
├── env:/staging/terraform.tfstate
└── env:/prod/terraform.tfstate
```

Backend configuration:
```hcl
backend "s3" {
  bucket = "terraform-state"
  key    = "app/terraform.tfstate"  # Workspace appended automatically
  region = "us-east-1"
}
```

---

## Advanced: Conditional Resources by Workspace

```hcl
# Only create in prod
resource "aws_cloudwatch_alarm" "high_cpu" {
  count = terraform.workspace == "prod" ? 1 : 0
  # ...
}

# Different counts per workspace
resource "aws_instance" "app" {
  count = terraform.workspace == "prod" ? 5 : terraform.workspace == "staging" ? 2 : 1
  # ...
}

# Map-based approach (cleaner)
locals {
  instance_counts = {
    dev     = 1
    staging = 2
    prod    = 5
  }
}

resource "aws_instance" "app" {
  count = local.instance_counts[terraform.workspace]
  # ...
}
```

---

## Troubleshooting

**Issue**: "Workspace X already exists"
**Solution**: `terraform workspace select X` to switch to it

**Issue**: "Cannot delete non-empty workspace"
**Solution**: `terraform destroy` first, then delete workspace

**Issue**: Applied to wrong workspace
**Solution**: Switch to correct workspace, review carefully before applying

**Issue**: Can't see workspace in outputs
**Solution**: Use `output "workspace" { value = terraform.workspace }`

**Issue**: Workspaces not showing in remote backend
**Solution**: Check S3 - they're stored as `env:/workspace-name/terraform.tfstate`

---

## Challenge Exercises

### Challenge 1: Add a QA Workspace

Add a `qa` environment between staging and prod with:
- 2 instances
- t2.small
- 10.3.0.0/16 VPC

### Challenge 2: Workspace-Specific Security Groups

Make SSH only allowed in dev/staging, blocked in prod.

**Hint:** Use `terraform.workspace` in security group rules.

### Challenge 3: Cost Tagging by Workspace

Add cost center tags that vary by workspace.

### Challenge 4: Workspace Guard Rails

Add validation to prevent deployment to prod workspace unless explicitly confirmed.

**Hint:** Use `variable` with validation and `terraform.workspace`.

---

## Key Takeaways

1. **Workspaces = separate state files, same code**
2. Each workspace is completely isolated
3. Use `terraform.workspace` to access current workspace
4. Great for similar environments with minor differences
5. Not suitable for completely different architectures
6. Always check current workspace before applying
7. Each workspace must be destroyed separately
8. Workspace state stored in `terraform.tfstate.d/`

---

## Exam Tips

- Know workspace commands (`list`, `new`, `select`, `show`, `delete`)
- Understand `terraform.workspace` interpolation
- Know when to use workspaces vs separate directories
- Remember: workspaces share backend, just different state paths
- Understand state isolation between workspaces
- Know that default workspace always exists

---

## Additional Resources

- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [When to Use Workspaces](https://developer.hashicorp.com/terraform/cli/workspaces)
- [Managing Multiple Environments](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration)
