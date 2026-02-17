# Terraform Remote State Backend Setup

This project uses **S3** for storing Terraform state and **DynamoDB** for state locking.

## Why Remote State?

- **Team Collaboration**: Multiple people can work on the same infrastructure
- **State Locking**: Prevents concurrent modifications (via DynamoDB)
- **Versioning**: S3 versioning allows state recovery
- **Encryption**: State is encrypted at rest
- **Backup**: Automatic backups in S3

## Production-Ready Approach

This project uses a **Terraform bootstrap** configuration (not shell scripts) to create backend resources. This is the industry-standard, production-ready approach.

## Setup Instructions

### Step 1: Configure Bootstrap

Edit `bootstrap/terraform.tfvars` and set a globally unique bucket name:

```hcl
state_bucket_name = "your-company-terraform-state-2026"  # Must be globally unique
```

### Step 2: Create Backend Resources

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket with versioning, encryption, and logging
- DynamoDB table with point-in-time recovery
- Production-grade security settings

### Step 3: Update Main Configuration

The bootstrap output will show the exact backend configuration. Copy it to `environments/dev/providers.tf`:

**Uncomment and update:**
```hcl
# backend "s3" {
#   bucket         = "your-terraform-state-bucket"
#   key            = "goal-tracker/dev/terraform.tfstate"
#   region         = "us-east-1"
#   encrypt        = true
#   dynamodb_table = "terraform-state-lock"
# }
```

**Uncomment and update the bucket name:**
```hcl
backend "s3" {
  bucket         = "your-company-terraform-state-bucket"  # Use your unique name
  key            = "goal-tracker/dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### Step 4: Initialize Main Infrastructure

```bash
cd environments/dev
terraform init
```

Terraform will:
- Configure the S3 backend
- Create the state file in S3
- Enable state locking with DynamoDB

## Backend Configuration Explained

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"      # S3 bucket name
  key            = "goal-tracker/dev/terraform.tfstate"  # Path within bucket
  region         = "us-east-1"                        # AWS region
  encrypt        = true                               # Encrypt state file
  dynamodb_table = "terraform-state-lock"             # Table for locking
}
```

### Key Structure

The `key` parameter organizes state files:

```
s3://your-terraform-state-bucket/
├── goal-tracker/
│   ├── dev/
│   │   └── terraform.tfstate
│   ├── staging/
│   │   └── terraform.tfstate
│   └── prod/
│       └── terraform.tfstate
```

This allows multiple environments to share the same bucket.

## What Gets Created

### 1. S3 Bucket
- **Name**: `your-terraform-state-bucket` (globally unique)
- **Versioning**: Enabled (keeps history of state changes)
- **Encryption**: AES256 (state encrypted at rest)
- **Public Access**: Blocked (security best practice)

### 2. DynamoDB Table
- **Name**: `terraform-state-lock`
- **Primary Key**: `LockID` (String)
- **Billing**: Pay-per-request (cost-effective)
- **Purpose**: Prevents concurrent `terraform apply` operations

## State Locking in Action

When you run `terraform apply`:

1. Terraform acquires a lock in DynamoDB
2. Reads current state from S3
3. Makes infrastructure changes
4. Writes new state to S3
5. Releases the lock

If another person tries to run `terraform apply` simultaneously:
```
Error: Error acquiring the state lock

Lock Info:
  ID:        abc123-def456-ghi789
  Path:      goal-tracker/dev/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2026-02-17 15:30:00 UTC
```

## Migrating Existing Local State

If you already have a local `terraform.tfstate` file:

1. Set up the backend (steps above)
2. Run `terraform init`
3. Terraform will ask: "Do you want to copy existing state to the new backend?"
4. Type `yes`
5. Local state is migrated to S3

## Production Environment

For production, create a separate backend configuration:

**environments/prod/providers.tf:**
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "goal-tracker/prod/terraform.tfstate"  # Different key!
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"  # Same table is fine
}
```

## Troubleshooting

### Error: Bucket name already taken
S3 bucket names are globally unique. Change to something like:
```
your-company-terraform-state-2026
```

### Error: State locked
Someone else is running terraform, or a previous run crashed:

```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### View state in S3
```bash
aws s3 ls s3://your-terraform-state-bucket/goal-tracker/dev/
```

### View lock table
```bash
aws dynamodb scan --table-name terraform-state-lock
```

## Cost Estimate

- **S3 Storage**: ~$0.023/GB/month (state files are typically < 1MB)
- **S3 Requests**: Minimal (only during terraform operations)
- **DynamoDB**: Pay-per-request (typically < $0.01/month)

**Total**: Less than $1/month for most projects

## Security Best Practices

✅ **Enabled in this setup:**
- Encryption at rest (S3)
- Versioning (recovery from mistakes)
- Public access blocked
- State locking (prevents corruption)

⚠️ **Additional recommendations:**
- Use IAM roles with least privilege
- Enable S3 bucket logging
- Set up lifecycle policies for old versions
- Use AWS KMS for encryption (optional)

## Commands Reference

```bash
# Initialize backend
terraform init

# View current state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Pull state to local file (backup)
terraform state pull > backup.tfstate

# Reconfigure backend
terraform init -reconfigure

# Migrate to different backend
terraform init -migrate-state
```
