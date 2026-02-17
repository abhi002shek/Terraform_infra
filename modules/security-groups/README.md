# Security Groups Module

## Overview
Creates all security groups for the application with proper ingress/egress rules following the principle of least privilege.

## Security Groups Created

### 1. ALB Security Group
**Purpose:** Public-facing Application Load Balancer
- **Ingress:** HTTP (80), HTTPS (443) from Internet (0.0.0.0/0)
- **Egress:** All traffic
- **Use:** Routes traffic to frontend servers

### 2. Internal ALB Security Group
**Purpose:** Internal Load Balancer for backend API
- **Ingress:** HTTP (80) from Frontend Security Group only
- **Egress:** All traffic
- **Use:** Routes traffic from frontend to backend

### 3. Bastion Security Group
**Purpose:** SSH jump server
- **Ingress:** SSH (22) from allowed CIDR blocks
- **Egress:** All traffic
- **Use:** Secure access to private instances

### 4. Frontend Security Group
**Purpose:** Frontend application servers
- **Ingress:** 
  - Port 3000 from ALB Security Group
  - SSH (22) from Bastion Security Group
- **Egress:** All traffic
- **Use:** Hosts frontend application

### 5. Backend Security Group
**Purpose:** Backend API servers
- **Ingress:**
  - Port 8080 from Internal ALB Security Group
  - SSH (22) from Bastion Security Group
- **Egress:** All traffic
- **Use:** Hosts backend API

### 6. RDS Security Group
**Purpose:** PostgreSQL database
- **Ingress:** PostgreSQL (5432) from Backend Security Group only
- **Egress:** None (no outbound traffic)
- **Use:** Database isolation

## Traffic Flow

```
Internet → ALB SG → Frontend SG → Internal ALB SG → Backend SG → RDS SG
                         ↑                                ↑
                    Bastion SG                      Bastion SG
```

## Usage

```hcl
module "security_groups" {
  source = "./modules/security-groups"

  environment        = "dev"
  project            = "my-app"
  vpc_id             = module.vpc.vpc_id
  allowed_ssh_cidrs  = ["1.2.3.4/32"]  # Your IP only
  
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
| allowed_ssh_cidrs | CIDRs allowed to SSH | list(string) | ["0.0.0.0/0"] | no |
| tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_sg_id | ALB security group ID |
| internal_alb_sg_id | Internal ALB security group ID |
| bastion_sg_id | Bastion security group ID |
| frontend_sg_id | Frontend security group ID |
| backend_sg_id | Backend security group ID |
| rds_sg_id | RDS security group ID |

## Security Best Practices

✅ **Implemented:**
- Principle of least privilege
- Security group chaining (no direct internet to backend)
- SSH access only via bastion
- Database completely isolated
- No unnecessary egress restrictions (allows updates)

⚠️ **Important:**
- Always restrict `allowed_ssh_cidrs` to your IP
- Never use `0.0.0.0/0` for SSH in production
- Review security group rules regularly

## Port Reference

| Service | Port | Protocol |
|---------|------|----------|
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| SSH | 22 | TCP |
| Frontend App | 3000 | TCP |
| Backend API | 8080 | TCP |
| PostgreSQL | 5432 | TCP |
