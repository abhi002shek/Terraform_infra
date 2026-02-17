# Production-Ready Terraform Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.13+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Reusable, modular, production-ready Terraform infrastructure for deploying scalable web applications on AWS**

## 🎯 Overview

This repository contains enterprise-grade Terraform modules for deploying a complete 3-tier web application infrastructure on AWS. Built with best practices, security, and scalability in mind.

## 🏗️ Architecture

```
                                    Internet
                                       ↓
                            [Application Load Balancer]
                                       ↓
        ┌──────────────────────────────────────────────────────┐
        │                    VPC (10.0.0.0/16)                 │
        │                                                       │
        │  ┌─────────────┐              ┌─────────────┐       │
        │  │  Public     │              │  Public     │       │
        │  │  Subnet     │              │  Subnet     │       │
        │  │  (AZ-1)     │              │  (AZ-2)     │       │
        │  │  - Bastion  │              │  - NAT GW   │       │
        │  │  - ALB      │              │             │       │
        │  └──────┬──────┘              └──────┬──────┘       │
        │         │                            │               │
        │  ┌──────▼──────┐              ┌─────▼───────┐       │
        │  │  Frontend   │              │  Frontend   │       │
        │  │  Private    │◄────ASG─────►│  Private    │       │
        │  │  Subnet     │              │  Subnet     │       │
        │  └──────┬──────┘              └──────┬──────┘       │
        │         │                            │               │
        │  ┌──────▼──────┐              ┌─────▼───────┐       │
        │  │  Backend    │              │  Backend    │       │
        │  │  Private    │◄────ASG─────►│  Private    │       │
        │  │  Subnet     │              │  Subnet     │       │
        │  └──────┬──────┘              └──────┬──────┘       │
        │         │                            │               │
        │  ┌──────▼──────┐              ┌─────▼───────┐       │
        │  │  Database   │              │  Database   │       │
        │  │  Isolated   │◄──Multi-AZ──►│  Isolated   │       │
        │  │  Subnet     │              │  Subnet     │       │
        │  │  [RDS]      │              │  [RDS]      │       │
        │  └─────────────┘              └─────────────┘       │
        └──────────────────────────────────────────────────────┘
```

## ✨ Features

### 🔒 Security
- ✅ Multi-tier network isolation
- ✅ Security group chaining
- ✅ Secrets Manager for credentials
- ✅ IAM roles with least privilege
- ✅ Encrypted RDS storage
- ✅ Private subnets for applications
- ✅ Bastion host for secure access

### 🚀 High Availability
- ✅ Multi-AZ deployment
- ✅ Auto Scaling Groups
- ✅ Application Load Balancers
- ✅ RDS Multi-AZ (optional)
- ✅ Health checks and auto-recovery

### 📊 Monitoring & Logging
- ✅ CloudWatch metrics
- ✅ CloudWatch alarms
- ✅ Auto-scaling policies
- ✅ ALB access logs
- ✅ Application logs

### 💰 Cost Optimization
- ✅ Single NAT Gateway option (dev)
- ✅ T3 instances with burstable CPU
- ✅ Configurable instance sizes
- ✅ Auto-scaling based on demand

## 📦 Modules

| Module | Description | Resources |
|--------|-------------|-----------|
| [**VPC**](modules/vpc/README.md) | Multi-tier VPC with public/private subnets | VPC, Subnets, IGW, NAT GW, Route Tables |
| [**Security Groups**](modules/security-groups/README.md) | Security groups for all tiers | 6 Security Groups with proper rules |
| [**ALB**](modules/alb/README.md) | Application Load Balancer | ALB, Target Groups, Listeners |
| [**IAM**](modules/iam/README.md) | IAM roles for EC2 instances | Roles, Policies, Instance Profiles |
| [**RDS**](modules/rds/README.md) | PostgreSQL database | RDS Instance, Subnet Group, Parameter Group |
| [**Bastion**](modules/bastion/README.md) | SSH jump server | EC2 Instance, Elastic IP |
| [**Frontend ASG**](modules/frontend-asg/README.md) | Frontend auto-scaling | Launch Template, ASG, Scaling Policies |
| [**Backend ASG**](modules/backend-asg/README.md) | Backend auto-scaling | Launch Template, ASG, Scaling Policies |
| [**Secrets**](modules/secrets/README.md) | Secrets Manager | Database credentials |

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.13
- [AWS CLI](https://aws.amazon.com/cli/) configured
- AWS account with appropriate permissions
- Docker images pushed to Docker Hub

### 1. Clone Repository

```bash
git clone https://github.com/abhi002shek/Terraform_infra.git
cd Terraform_infra
```

### 2. Create S3 Backend (One-time setup)

```bash
cd bootstrap
terraform init
terraform apply
```

### 3. Configure Environment

```bash
cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Required changes
ssh_key_name          = "your-key-pair-name"
allowed_ssh_cidr      = "your-ip/32"
frontend_docker_image = "your-dockerhub/frontend:v1"
backend_docker_image  = "your-dockerhub/backend:v1"
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 5. Access Application

```bash
# Get application URL
terraform output application_url

# Get bastion IP for SSH access
terraform output bastion_public_ip
```

## 📁 Project Structure

```
terraform-infra/
├── bootstrap/              # S3 backend setup
│   ├── main.tf
│   ├── variables.tf
│   └── README.md
├── environments/           # Environment-specific configs
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── providers.tf
│   │   └── outputs.tf
│   └── prod/              # Production environment
├── modules/               # Reusable modules
│   ├── vpc/
│   ├── security-groups/
│   ├── alb/
│   ├── iam/
│   ├── rds/
│   ├── bastion/
│   ├── frontend-asg/
│   ├── backend-asg/
│   └── secrets/
└── scripts/              # User data scripts
    ├── frontend_user_data.sh
    └── backend_user_data.sh
```

## 🔧 Configuration

### Environment Variables

Create `terraform.tfvars` in `environments/dev/`:

```hcl
# Network
region             = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# SSH Access
ssh_key_name     = "your-key-pair"
allowed_ssh_cidr = "1.2.3.4/32"  # Your IP

# Application
frontend_docker_image = "dockerhub-user/frontend:v1"
backend_docker_image  = "dockerhub-user/backend:v1"

# Instance Sizes
frontend_instance_type = "t3.micro"
backend_instance_type  = "t3.micro"
db_instance_class      = "db.t3.micro"

# High Availability
single_nat_gateway = true   # false for production
db_multi_az        = false  # true for production
```

### Scaling Configuration

```hcl
# Frontend Auto Scaling
frontend_min_size         = 2
frontend_max_size         = 4
frontend_desired_capacity = 2

# Backend Auto Scaling
backend_min_size         = 2
backend_max_size         = 6
backend_desired_capacity = 2
```


## 🔐 Security Best Practices

✅ **Implemented in this infrastructure:**

1. **Network Security**
   - Private subnets for applications
   - Security group chaining
   - No direct internet access to backend

2. **Access Control**
   - IAM roles instead of access keys
   - Bastion host for SSH access
   - Restricted SSH CIDR blocks

3. **Data Protection**
   - RDS encryption at rest
   - Secrets Manager for credentials
   - SSL/TLS for data in transit

4. **Monitoring**
   - CloudWatch alarms
   - Auto-scaling based on metrics
   - Health checks on all tiers

## 📊 Monitoring

### CloudWatch Alarms

Automatically created alarms:
- Frontend high CPU (>80%)
- Backend high CPU (>80%)
- Unhealthy target count
- RDS CPU utilization
- RDS storage space

### Viewing Logs

```bash
# Frontend logs
aws logs tail /aws/ec2/dev-goal-tracker/frontend --follow

# Backend logs
aws logs tail /aws/ec2/dev-goal-tracker/backend --follow
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        
      - name: Terraform Init
        run: terraform init
        working-directory: ./environments/dev
        
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./environments/dev
        
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: ./environments/dev
```

## 🛠️ Maintenance

### Updating Docker Images

```bash
# Build and push new images
docker build --platform linux/amd64 -t user/frontend:v2 --push .

# Update terraform.tfvars
frontend_docker_image = "user/frontend:v2"

# Apply changes
terraform apply

# Trigger instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name dev-goal-tracker-frontend-asg
```

### Scaling Resources

```bash
# Update terraform.tfvars
frontend_desired_capacity = 4

# Apply changes
terraform apply
```

### Database Backup & Restore

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier dev-goal-tracker-postgres \
  --db-snapshot-identifier manual-backup-2024-01-01

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier manual-backup-2024-01-01
```

## 🐛 Troubleshooting

### 502 Bad Gateway
1. Check target health: `aws elbv2 describe-target-health`
2. Verify Docker containers are running
3. Check application logs
4. Verify health check endpoint

### Can't SSH to Instances
1. Verify bastion is running
2. Check security group rules
3. Verify SSH key pair
4. Use Session Manager as alternative

### Database Connection Issues
1. Check security group rules
2. Verify RDS endpoint
3. Check credentials in Secrets Manager
4. Ensure backend can reach database subnet

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Abhishek**
- GitHub: [@abhi002shek](https://github.com/abhi002shek)
- LinkedIn: [Connect with me](https://www.linkedin.com/in/abhishek-singh-2b96961a0/)

## ⭐ Show Your Support

Give a ⭐️ if this project helped you!

---

**Built with ❤️ using Terraform and AWS**
