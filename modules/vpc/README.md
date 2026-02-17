# VPC Module

## Overview
Creates a production-ready, multi-tier VPC architecture with public and private subnets across multiple availability zones.

## Architecture
```
Internet
    ↓
[Internet Gateway]
    ↓
┌─────────────────────────────────────┐
│              VPC                    │
│         (10.0.0.0/16)              │
│                                     │
│  Public Subnets (2 AZs)            │
│  - Bastion Host                     │
│  - Load Balancers                   │
│  - NAT Gateways                     │
│         ↓                           │
│  Frontend Private Subnets           │
│  - Frontend Application Servers     │
│         ↓                           │
│  Backend Private Subnets            │
│  - Backend API Servers              │
│         ↓                           │
│  Database Isolated Subnets          │
│  - RDS PostgreSQL (No Internet)     │
└─────────────────────────────────────┘
```

## Features
- ✅ Multi-AZ deployment for high availability
- ✅ 4-tier network architecture (Public, Frontend, Backend, Database)
- ✅ NAT Gateway for private subnet internet access
- ✅ Configurable single or multi-NAT Gateway (cost optimization)
- ✅ Isolated database subnets with no internet access
- ✅ Proper route tables for each tier

## Resources Created
- 1 VPC
- 1 Internet Gateway
- 8 Subnets (2 per tier × 2 AZs)
- 1-2 NAT Gateways (configurable)
- 1-2 Elastic IPs (for NAT Gateways)
- 6 Route Tables
- Route table associations

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  environment          = "dev"
  project              = "my-app"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  frontend_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  backend_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
  database_subnet_cidrs = ["10.0.31.0/24", "10.0.32.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # false for HA (costs more)
  
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" | no |
| environment | Environment name | string | - | yes |
| project | Project name | string | - | yes |
| availability_zones | List of AZs | list(string) | - | yes |
| public_subnet_cidrs | Public subnet CIDRs | list(string) | - | yes |
| frontend_subnet_cidrs | Frontend subnet CIDRs | list(string) | - | yes |
| backend_subnet_cidrs | Backend subnet CIDRs | list(string) | - | yes |
| database_subnet_cidrs | Database subnet CIDRs | list(string) | - | yes |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT Gateway | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| frontend_subnet_ids | List of frontend subnet IDs |
| backend_subnet_ids | List of backend subnet IDs |
| database_subnet_ids | List of database subnet IDs |
| nat_gateway_ips | Elastic IPs of NAT Gateways |
| internet_gateway_id | Internet Gateway ID |

## Cost Optimization

**Single NAT Gateway (Dev):**
- Cost: ~$32/month
- Use for: Development, testing

**Multi NAT Gateway (Prod):**
- Cost: ~$64/month
- Use for: Production (high availability)

## Security

- Public subnets: Direct internet access via Internet Gateway
- Private subnets: Outbound internet via NAT Gateway
- Database subnets: No internet access (fully isolated)
- Each tier has dedicated route tables
