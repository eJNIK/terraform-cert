# Lab 03: Remote State Management

## Overview

Learn how to configure remote state storage with S3 and state locking with DynamoDB - essential for team collaboration and production Terraform usage.

**Time Estimate:** 30 minutes

### Exam Objectives Covered

- **9a**: Understand backends and remote state
- **9b**: Configure S3 backend
- **9c**: Implement state locking with DynamoDB
- **9d**: Migrate state from local to remote
- **9e**: State security and encryption
- **10a**: Understand team collaboration workflows

---

## Why Remote State?

### Problems with Local State

- ❌ Single point of failure (laptop crash = lost state)
- ❌ No team collaboration (can't share state)
- ❌ No locking (concurrent runs corrupt state)
- ❌ No versioning (mistakes are permanent)
- ❌ State contains secrets (stored unencrypted locally)

### Benefits of Remote State

- ✅ **Centralized**: Team shares single source of truth
- ✅ **Locked**: DynamoDB prevents concurrent modifications
- ✅ **Versioned**: S3 versioning enables rollback
- ✅ **Encrypted**: State encrypted at rest and in transit
- ✅ **Backed up**: S3 provides durability and availability

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Developer 1          Developer 2               │
│  terraform apply      terraform apply (BLOCKED) │
└──────────┬────────────────────┬─────────────────┘
           │                    │
           ▼                    ▼
    ┌──────────────────────────────────┐
    │   DynamoDB Table                 │
    │   terraform-state-lock           │
    │   (Prevents concurrent access)   │
    └──────────────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────┐
    │   S3 Bucket                      │
    │   - State files encrypted        │
    │   - Versioning enabled           │
    │   - Public access blocked        │
    └──────────────────────────────────┘
```

---

## Lab Steps

### Phase 1: Create Backend Infrastructure

**1. Deploy S3 + DynamoDB**
```bash
cd labs/lab-03-remote-state
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

**2. Note the outputs**
```bash
terraform output backend_config
```

You'll see:
```hcl
{
  bucket         = "jakub.ejnik-terraform-state-us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
  key            = "lab-03/terraform.tfstate"
  region         = "us-east-1"
}
```

---

### Phase 2: Migrate to Remote Backend

**3. Update backend configuration**

Edit `main.tf` and uncomment the backend block:
```hcl
backend "s3" {
  bucket         = "jakub.ejnik-terraform-state-us-east-1"  # Use your bucket name
  key            = "lab-03/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

**4. Reinitialize with migration**
```bash
terraform init -migrate-state
```

You'll be asked:
```
Do you want to copy existing state to the new backend?
  Enter a value: yes
```

**5. Verify remote state**
```bash
# Check S3
aws s3 ls s3://jakub.ejnik-terraform-state-us-east-1/lab-03/

# Local state should be minimal now
cat terraform.tfstate
```

Local state now just points to remote backend!

---

### Phase 3: Test State Locking

**6. Simulate concurrent access**

Terminal 1:
```bash
terraform plan
# Leave it running or use terraform console
terraform console
```

Terminal 2 (while Terminal 1 is active):
```bash
terraform plan
```

You'll see:
```
Error: Error acquiring the state lock

Lock Info:
  ID:        xxx-xxx-xxx
  Path:      jakub.ejnik-terraform-state-us-east-1/lab-03/terraform.tfstate
  Operation: OperationTypePlan
  Who:       user@hostname
  Version:   1.x.x
  Created:   2024-XX-XX XX:XX:XX UTC
```

**This is working correctly!** The lock prevents corruption.

---

### Phase 4: State Versioning

**7. Make a change**
```bash
# Modify something
terraform apply
```

**8. Check S3 versions**
```bash
aws s3api list-object-versions \
  --bucket jakub.ejnik-terraform-state-us-east-1 \
  --prefix lab-03/terraform.tfstate
```

You'll see multiple versions! Can rollback if needed.

---

## Backend Configuration Options

### Method 1: In terraform block (current approach)
```hcl
terraform {
  backend "s3" {
    bucket = "my-bucket"
    key    = "path/to/state"
    region = "us-east-1"
  }
}
```

**Pros:** Explicit, version-controlled
**Cons:** Can't use variables

### Method 2: Backend config file
```bash
# backend.hcl
bucket         = "my-bucket"
key            = "path/to/state"
region         = "us-east-1"
dynamodb_table = "terraform-lock"
encrypt        = true
```

```bash
terraform init -backend-config=backend.hcl
```

**Pros:** Reusable, can be environment-specific
**Cons:** Extra file to manage

### Method 3: Command-line flags
```bash
terraform init \
  -backend-config="bucket=my-bucket" \
  -backend-config="key=path/to/state" \
  -backend-config="region=us-east-1"
```

**Pros:** Scriptable, CI/CD friendly
**Cons:** Verbose

---

## Best Practices

### S3 Bucket Configuration

✅ **Enable versioning** - Allows state rollback
✅ **Enable encryption** - Protects sensitive data
✅ **Block public access** - Prevents exposure
✅ **Enable logging** - Audit access
✅ **Use lifecycle policies** - Manage old versions

### DynamoDB Table

✅ **Use PAY_PER_REQUEST** - Cost-effective for intermittent use
✅ **Hash key must be `LockID`** - Required by Terraform
✅ **No other attributes needed** - Keep it simple

### State Organization

```
s3://bucket/
├── prod/
│   ├── vpc/terraform.tfstate
│   ├── app/terraform.tfstate
│   └── database/terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── dev/
    └── terraform.tfstate
```

**Separate state files by:**
- Environment (prod/staging/dev)
- Component (vpc/app/database)
- Team/service

---

## Important Commands

```bash
# Initialize with backend
terraform init

# Migrate existing state
terraform init -migrate-state

# Reconfigure backend
terraform init -reconfigure

# Change backend config
terraform init -backend-config=backend.hcl

# View state
terraform show

# List state resources
terraform state list

# Pull remote state to local (for inspection only)
terraform state pull > remote-state.json

# Force unlock (if lock is stuck)
terraform force-unlock LOCK_ID
```

---

## Security Considerations

### State Files Contain Secrets

Terraform state may include:
- Database passwords
- API keys
- SSH private keys
- Certificate data

**Mitigation:**
- ✅ Use S3 encryption
- ✅ Restrict IAM access
- ✅ Enable S3 bucket logging
- ✅ Use separate state files per environment
- ✅ Never commit state files to git
- ✅ Use AWS Secrets Manager/Parameter Store for secrets

### IAM Policy for State Access

```hcl
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::terraform-state-bucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::terraform-state-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

---

## Troubleshooting

**Issue**: "Backend initialization required"
**Solution**: Run `terraform init`

**Issue**: "Error acquiring the state lock"
**Solution**: Wait for other operation to complete, or force-unlock if stale

**Issue**: "Failed to get existing workspaces"
**Solution**: Check S3 bucket permissions and existence

**Issue**: "NoSuchBucket" error
**Solution**: Ensure bucket exists and region is correct

**Issue**: Can't switch back to local backend
**Solution**: Comment out backend block, run `terraform init -migrate-state`

---

## Challenge Exercises

### Challenge 1: Multi-Environment Setup

Create separate backend configs for dev/staging/prod using backend config files.

**Hint:** Create `backend-dev.hcl`, `backend-staging.hcl`, `backend-prod.hcl` with different key paths.

### Challenge 2: State Rollback

Intentionally break something, then rollback using S3 versioning.

**Hint:** Download previous version from S3, then `terraform state push`

### Challenge 3: State Locking Timeout

Configure custom timeout for state locking.

**Hint:** Research `-lock-timeout` flag

### Challenge 4: Workspace with Remote State

Combine workspaces with remote state to manage multiple environments.

**Hint:** Each workspace gets its own state file in S3

---

## Cleanup

```bash
# IMPORTANT: First migrate back to local state
# 1. Comment out backend block in main.tf
# 2. Run terraform init -migrate-state

# Then destroy resources
terraform destroy

# Manually delete S3 bucket versions
aws s3api delete-object --bucket BUCKET --key KEY --version-id VERSION_ID

# Or use AWS Console to empty and delete bucket
```

**Note:** S3 buckets with versioning require emptying all versions before deletion.

---

## Key Takeaways

1. **Remote state enables team collaboration**
2. **S3 provides durable, encrypted storage**
3. **DynamoDB prevents concurrent state modifications**
4. **State files contain sensitive data - protect them**
5. **Versioning enables rollback and audit trails**
6. **Backend configuration cannot use variables**
7. **Each environment should have separate state**

---

## Exam Tips

- Know the difference between local and remote backends
- Understand state locking and why it's critical
- Remember: backend blocks don't support variables
- Know how to migrate state between backends
- Understand security implications of state files
- Be familiar with `terraform state` commands

---

## Additional Resources

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [State Locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [Terraform State](https://developer.hashicorp.com/terraform/language/state)
