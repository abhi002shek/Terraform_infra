# IAM Module

## Overview
Creates IAM roles and policies for EC2 instances to securely access AWS services without hardcoded credentials.

## What It Creates

### 1. IAM Role
- **Name:** `{environment}-{project}-ec2-role`
- **Trust Policy:** Allows EC2 service to assume this role
- **Purpose:** Identity for EC2 instances

### 2. Instance Profile
- **Name:** `{environment}-{project}-ec2-instance-profile`
- **Purpose:** Attaches IAM role to EC2 instances

### 3. Managed Policies (AWS)

#### SSM Managed Instance Core
- **ARN:** `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`
- **Permissions:**
  - Connect via Session Manager (no SSH keys needed)
  - Run commands remotely
  - Manage patches
- **Use:** Secure shell access through AWS console

#### CloudWatch Agent Server Policy
- **ARN:** `arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy`
- **Permissions:**
  - Send logs to CloudWatch
  - Send metrics to CloudWatch
  - Create log streams
- **Use:** Application monitoring and logging

### 4. Custom Policy: Secrets Manager Access
- **Name:** `{environment}-{project}-secrets-manager-policy`
- **Permissions:**
  - `secretsmanager:GetSecretValue`
  - `secretsmanager:DescribeSecret`
- **Scope:** Only specified secret ARNs
- **Use:** Fetch database credentials securely

## Architecture

```
EC2 Instance
    ↓
[Instance Profile]
    ↓
[IAM Role]
    ↓
┌─────────────────────────────────┐
│  Attached Policies:             │
│  1. SSM Managed Instance Core   │
│  2. CloudWatch Agent            │
│  3. Secrets Manager (Custom)    │
└─────────────────────────────────┘
    ↓
AWS Services (SSM, CloudWatch, Secrets Manager)
```

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  environment  = "dev"
  project      = "my-app"
  secrets_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789:secret:db-credentials-xxx"
  ]
  
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Attach to EC2 instances
resource "aws_instance" "app" {
  iam_instance_profile = module.iam.ec2_instance_profile_name
  # ... other config
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| project | Project name | string | - | yes |
| secrets_arns | Secrets Manager ARNs | list(string) | ["*"] | no |
| tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| ec2_role_arn | IAM role ARN |
| ec2_role_name | IAM role name |
| ec2_instance_profile_arn | Instance profile ARN |
| ec2_instance_profile_name | Instance profile name |

## What EC2 Instances Can Do

### ✅ With This IAM Role

**1. Connect via Session Manager**
```bash
# No SSH keys needed!
aws ssm start-session --target i-xxxxx
```

**2. Send Logs to CloudWatch**
```bash
# Application logs automatically sent
aws logs put-log-events --log-group-name /app/logs
```

**3. Fetch Database Credentials**
```bash
# Securely retrieve secrets
aws secretsmanager get-secret-value --secret-id db-credentials
```

**4. Send Custom Metrics**
```bash
# Monitor application performance
aws cloudwatch put-metric-data --namespace MyApp --metric-name RequestCount
```

### ❌ Cannot Do (Security)

- Access other AWS accounts
- Modify IAM policies
- Delete S3 buckets
- Terminate other EC2 instances
- Access secrets not in the allowed list

## Security Best Practices

✅ **Implemented:**
- Principle of least privilege
- Specific secret ARNs (not wildcard)
- No inline policies (uses managed policies)
- Trust policy limited to EC2 service

⚠️ **Recommendations:**
- Restrict `secrets_arns` to specific secrets
- Avoid using `["*"]` in production
- Regularly audit IAM permissions
- Use AWS IAM Access Analyzer

## Real-World Example

**Application startup script:**
```bash
#!/bin/bash

# Fetch database password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id dev-myapp-db-credentials \
  --query SecretString \
  --output text | jq -r .password)

# Start application with credentials
docker run -e DB_PASSWORD="$DB_PASSWORD" myapp:latest
```

**No hardcoded credentials needed!** ✅

## Troubleshooting

### Issue: "Access Denied" when fetching secrets
**Solution:** Verify secret ARN is in `secrets_arns` list

### Issue: Can't connect via Session Manager
**Solution:** Ensure SSM agent is running on instance

### Issue: Logs not appearing in CloudWatch
**Solution:** Check CloudWatch agent configuration

## Cost

IAM roles and policies are **FREE**. No charges for:
- Creating roles
- Attaching policies
- Using instance profiles

You only pay for the AWS services you use (CloudWatch, Secrets Manager, etc.)
