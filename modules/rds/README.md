# RDS Module

## Overview
Creates a managed PostgreSQL database with automated backups, encryption, and high availability options.

## Features
- ✅ PostgreSQL 15.x
- ✅ Automated backups
- ✅ Encryption at rest
- ✅ Multi-AZ deployment (optional)
- ✅ Custom parameter group
- ✅ Subnet group for private subnets
- ✅ Secure password in Secrets Manager
- ✅ Configurable instance size

## Architecture

```
Backend Servers
    ↓
[RDS PostgreSQL]
    ↓
┌─────────────────────────────────┐
│  Primary Instance (AZ-1)        │
│  ↓ (if Multi-AZ enabled)        │
│  Standby Instance (AZ-2)        │
└─────────────────────────────────┘
    ↓
[Automated Backups to S3]
```

## Usage

```hcl
module "rds" {
  source = "./modules/rds"

  environment          = "dev"
  project              = "my-app"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.database_subnet_ids
  security_group_ids   = [module.security_groups.rds_sg_id]
  
  # Database configuration
  db_name              = "myappdb"
  db_username          = "postgres"
  db_password          = random_password.db_password.result
  
  # Instance configuration
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  engine_version       = "15.16"
  
  # High availability (production)
  multi_az             = false  # true for production
  
  # Backup configuration
  backup_retention_period = 7
  skip_final_snapshot     = true  # false for production
  
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| project | Project name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Database subnet IDs | list(string) | - | yes |
| security_group_ids | Security group IDs | list(string) | - | yes |
| db_name | Database name | string | - | yes |
| db_username | Master username | string | "postgres" | no |
| db_password | Master password | string | - | yes |
| instance_class | Instance type | string | "db.t3.micro" | no |
| allocated_storage | Storage in GB | number | 20 | no |
| engine_version | PostgreSQL version | string | "15.16" | no |
| multi_az | Enable Multi-AZ | bool | false | no |
| backup_retention_period | Backup retention days | number | 7 | no |
| skip_final_snapshot | Skip final snapshot | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | RDS instance ID |
| db_instance_arn | RDS instance ARN |
| db_endpoint | Database endpoint |
| db_port | Database port |
| db_name | Database name |
| db_username | Master username |

## Instance Classes

| Class | vCPU | RAM | Use Case | Cost/Month |
|-------|------|-----|----------|------------|
| db.t3.micro | 2 | 1 GB | Dev/Test | ~$15 |
| db.t3.small | 2 | 2 GB | Small apps | ~$30 |
| db.t3.medium | 2 | 4 GB | Medium apps | ~$60 |
| db.r6g.large | 2 | 16 GB | Production | ~$150 |

## Storage

- **Type:** General Purpose SSD (gp3)
- **Min:** 20 GB
- **Max:** 65,536 GB
- **IOPS:** 3000 baseline (configurable)
- **Throughput:** 125 MB/s baseline

## Backup & Recovery

### Automated Backups
- **Frequency:** Daily
- **Retention:** Configurable (1-35 days)
- **Window:** Automatic (can be customized)
- **Storage:** Free up to DB size

### Point-in-Time Recovery
- Restore to any second within retention period
- Creates new DB instance
- Original DB remains unchanged

### Final Snapshot
- Created when DB is deleted
- Disabled in dev (`skip_final_snapshot = true`)
- **Always enable in production!**

## Multi-AZ Deployment

### Single-AZ (Development)
```hcl
multi_az = false
```
- **Cost:** Lower
- **Availability:** ~99.5%
- **Failover:** Manual
- **Use:** Dev, test environments

### Multi-AZ (Production)
```hcl
multi_az = true
```
- **Cost:** 2x instance cost
- **Availability:** ~99.95%
- **Failover:** Automatic (1-2 minutes)
- **Use:** Production environments

## Security

✅ **Implemented:**
- Encryption at rest (AES-256)
- Encryption in transit (SSL/TLS)
- Private subnets only (no public access)
- Security group restrictions
- IAM database authentication (optional)

## Connection String

```bash
# From application
postgresql://postgres:password@endpoint:5432/dbname

# Example
postgresql://postgres:SecurePass123@dev-myapp-postgres.xxxxx.us-east-1.rds.amazonaws.com:5432/myappdb
```

## Parameter Group

Custom parameter group with optimizations:
- `shared_preload_libraries = 'pg_stat_statements'`
- Connection pooling settings
- Memory configuration
- Query optimization

## Monitoring

Available CloudWatch metrics:
- CPU utilization
- Database connections
- Free storage space
- Read/Write IOPS
- Network throughput
- Replication lag (Multi-AZ)

## Maintenance

- **Maintenance window:** Configurable
- **Auto minor version upgrade:** Enabled
- **Backup window:** Configurable
- **Downtime:** Minimal during maintenance

## Cost Optimization

### Development
```hcl
instance_class          = "db.t3.micro"
allocated_storage       = 20
multi_az                = false
backup_retention_period = 7
```
**Cost:** ~$15-20/month

### Production
```hcl
instance_class          = "db.t3.small"
allocated_storage       = 100
multi_az                = true
backup_retention_period = 30
```
**Cost:** ~$100-150/month

## Best Practices

✅ Use Multi-AZ in production
✅ Enable automated backups
✅ Use strong passwords (Secrets Manager)
✅ Enable encryption
✅ Monitor CloudWatch metrics
✅ Set up CloudWatch alarms
✅ Regular security patches
✅ Test restore procedures

## Troubleshooting

### Can't connect to database
1. Check security group rules
2. Verify endpoint and port
3. Check credentials
4. Ensure instance is in private subnet

### High CPU usage
1. Check slow queries
2. Add indexes
3. Optimize queries
4. Consider larger instance

### Storage full
1. Increase allocated storage
2. Enable storage autoscaling
3. Clean up old data
4. Archive logs
