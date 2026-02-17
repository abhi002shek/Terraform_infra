# Terraform Backend Bootstrap

## Overview

This directory contains the **bootstrap configuration** that creates the S3 bucket and DynamoDB table required for Terraform remote state storage.

## Why a Separate Bootstrap?

**The Chicken-and-Egg Problem:**
- Main infrastructure needs S3 backend to store state
- But S3 backend itself needs to be created first
- Can't use S3 backend to create S3 backend!

**Solution:**
- Bootstrap uses **local state** (one-time only)
- Creates S3 + DynamoDB resources
- Main infrastructure then uses these resources for remote state

## Production-Ready Features

This bootstrap includes enterprise-grade features:

✅ **S3 Bucket:**
- Versioning enabled (state history)
- Encryption at rest (AES256)
- Public access blocked
- Access logging enabled
- Lifecycle policy (delete old versions after 90 days)
- Prevent destroy protection

✅ **DynamoDB Table:**
- Pay-per-request billing (cost-effective)
- Point-in-time recovery enabled
- Prevent destroy protection

✅ **Security:**
- No public access
- Encryption enabled
- Audit logging
- IAM-based access control

## Setup Instructions

### Step 1: Configure Bucket Name

Edit `terraform.tfvars` and set a **globally unique** bucket name:

```hcl
state_bucket_name = "your-company-terraform-state-2026"  # Must be unique!
```

**Naming conventions:**
- Use your company/project name
- Add year or random suffix
- Examples: `acme-terraform-state-2026`, `myapp-tf-state-prod`

### Step 2: Run Bootstrap

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

**Output will show:**
```
Outputs:

backend_config = 
    Add this to your providers.tf:
    
    backend "s3" {
      bucket         = "your-company-terraform-state-2026"
      key            = "goal-tracker/dev/terraform.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "terraform-state-lock"
    }

s3_bucket_name = "your-company-terraform-state-2026"
dynamodb_table_name = "terraform-state-lock"
```

### Step 3: Update Main Configuration

Copy the backend configuration from the output and add it to `environments/dev/providers.tf`:

```hcl
terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "your-company-terraform-state-2026"
    key            = "goal-tracker/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Step 4: Initialize Main Infrastructure

```bash
cd ../environments/dev
terraform init
```

Terraform will now use the S3 backend for state storage.

## What Gets Created

### 1. S3 Buckets (2 total)

**State Bucket:**
```
Name: your-company-terraform-state-2026
Purpose: Store terraform.tfstate files
Features: Versioning, Encryption, Lifecycle policy
```

**Logs Bucket:**
```
Name: your-company-terraform-state-2026-logs
Purpose: Audit logs for state bucket access
Features: Stores who accessed state and when
```

### 2. DynamoDB Table

```
Name: terraform-state-lock
Purpose: Prevent concurrent terraform operations
Features: Point-in-time recovery, Pay-per-request billing
```

## State File Organization

```
s3://your-company-terraform-state-2026/
├── goal-tracker/
│   ├── dev/
│   │   └── terraform.tfstate
│   ├── staging/
│   │   └── terraform.tfstate
│   └── prod/
│       └── terraform.tfstate
└── other-projects/
    └── ...
```

Each environment has its own state file path (controlled by the `key` parameter).

## Bootstrap State Management

**Important:** The bootstrap itself uses **local state** stored in this directory:

```
bootstrap/
├── terraform.tfstate       # Local state (DO NOT DELETE)
├── terraform.tfstate.backup
└── .terraform/
```

**Why local state for bootstrap?**
- Bootstrap creates the remote backend
- Can't use remote backend before it exists
- Local state is acceptable here (one-time setup)

**Best practices:**
1. ✅ Commit bootstrap code to Git
2. ❌ Don't commit `terraform.tfstate` (in `.gitignore`)
3. ✅ Keep bootstrap state file backed up separately
4. ✅ Rarely need to modify bootstrap after initial setup

## For Multiple Environments

The same S3 bucket and DynamoDB table can be used for all environments (dev, staging, prod).

**Dev environment:**
```hcl
backend "s3" {
  key = "goal-tracker/dev/terraform.tfstate"
}
```

**Prod environment:**
```hcl
backend "s3" {
  key = "goal-tracker/prod/terraform.tfstate"
}
```

Different `key` values keep states separate.

## Cost Estimate

- **S3 Storage**: ~$0.023/GB/month (state files typically < 1MB)
- **S3 Requests**: Minimal (only during terraform operations)
- **DynamoDB**: Pay-per-request (~$0.01/month for typical usage)
- **S3 Logging**: ~$0.01/month

**Total: Less than $1/month**

## Destroying Bootstrap (Caution!)

**⚠️ WARNING:** Destroying bootstrap resources will delete all Terraform state!

If you really need to destroy:

1. First, migrate all environments to local state
2. Remove `prevent_destroy` from `main.tf`
3. Run `terraform destroy`

**In production, you should NEVER destroy the backend.**

## Troubleshooting

### Error: Bucket name already taken
S3 bucket names are globally unique. Try:
- Add your company name
- Add random suffix
- Add year: `myapp-terraform-state-2026`

### Error: Access Denied
Ensure your AWS credentials have permissions:
- `s3:CreateBucket`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`
- `dynamodb:CreateTable`

### Viewing Resources

```bash
# List S3 buckets
aws s3 ls | grep terraform-state

# View DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock

# View state files
aws s3 ls s3://your-company-terraform-state-2026/goal-tracker/
```

## Security Best Practices

✅ **Implemented:**
- Encryption at rest
- Versioning enabled
- Public access blocked
- Access logging
- Point-in-time recovery

⚠️ **Additional recommendations:**
- Use AWS KMS for encryption (instead of AES256)
- Set up bucket replication to another region
- Enable MFA delete on S3 bucket
- Use IAM policies to restrict access
- Set up CloudWatch alarms for unauthorized access

## Comparison: Bootstrap vs Shell Script

| Aspect | Shell Script | Terraform Bootstrap |
|--------|--------------|---------------------|
| **Declarative** | ❌ Imperative commands | ✅ Declarative IaC |
| **Idempotent** | ⚠️ Requires checks | ✅ Built-in |
| **State tracking** | ❌ No state | ✅ Tracks resources |
| **Versioning** | ❌ Manual | ✅ Git + Terraform |
| **Destroy** | ❌ Manual cleanup | ✅ `terraform destroy` |
| **Production-ready** | ⚠️ Basic | ✅ Enterprise-grade |
| **Logging** | ❌ Not included | ✅ S3 access logs |
| **Lifecycle policies** | ❌ Manual | ✅ Automated |

**Verdict:** Terraform bootstrap is the production-standard approach.
