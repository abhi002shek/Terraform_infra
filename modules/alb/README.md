# ALB (Application Load Balancer) Module

## Overview
Creates an Application Load Balancer with target group, health checks, and listeners. Supports both public and internal load balancers.

## Features
- ✅ HTTP and HTTPS listeners
- ✅ Configurable health checks
- ✅ Session stickiness
- ✅ Cross-zone load balancing
- ✅ HTTP/2 support
- ✅ Optional HTTPS with ACM certificate
- ✅ Automatic HTTP to HTTPS redirect

## Architecture

```
Internet/VPC
    ↓
[Application Load Balancer]
    ↓
[Target Group]
    ↓
[EC2 Instances in ASG]
```

## Usage

### Public ALB (Frontend)
```hcl
module "public_alb" {
  source = "./modules/alb"

  environment       = "dev"
  project           = "my-app"
  name_prefix       = "public-"
  internal          = false
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  target_group_port = 3000
  health_check_path = "/health"
  
  # Optional HTTPS
  certificate_arn = "arn:aws:acm:region:account:certificate/xxx"
  
  tags = {
    Environment = "dev"
  }
}
```

### Internal ALB (Backend)
```hcl
module "internal_alb" {
  source = "./modules/alb"

  environment       = "dev"
  project           = "my-app"
  name_prefix       = "internal-"
  internal          = true  # Not accessible from internet
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.backend_subnet_ids
  security_group_id = module.security_groups.internal_alb_sg_id
  target_group_port = 8080
  health_check_path = "/health"
  
  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| project | Project name | string | - | yes |
| name_prefix | ALB name prefix | string | "" | no |
| internal | Is internal ALB | bool | false | no |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs for ALB | list(string) | - | yes |
| security_group_id | Security group ID | string | - | yes |
| target_group_port | Target port | number | 3000 | no |
| health_check_path | Health check path | string | "/" | no |
| certificate_arn | ACM certificate ARN | string | "" | no |
| enable_deletion_protection | Enable deletion protection | bool | false | no |
| tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_id | ALB ID |
| alb_arn | ALB ARN |
| alb_dns_name | ALB DNS name |
| alb_zone_id | ALB Route53 zone ID |
| target_group_arn | Target group ARN |
| target_group_name | Target group name |

## Health Check Configuration

Default health check settings:
- **Path:** Configurable (default: `/`)
- **Interval:** 30 seconds
- **Timeout:** 5 seconds
- **Healthy threshold:** 2 consecutive successes
- **Unhealthy threshold:** 3 consecutive failures
- **Matcher:** HTTP 200-299

## Session Stickiness

Enabled by default:
- **Type:** Load balancer cookie
- **Duration:** 24 hours (86400 seconds)
- **Purpose:** Maintains user session on same instance

## HTTPS Configuration

To enable HTTPS:
1. Create ACM certificate for your domain
2. Validate the certificate
3. Pass certificate ARN to module
4. HTTP traffic automatically redirects to HTTPS

```hcl
certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
```

## Cost

- **ALB:** ~$16-22/month (base cost)
- **Data processing:** ~$0.008/GB
- **LCU (Load Balancer Capacity Units):** Variable based on traffic

## Best Practices

✅ Use internal ALB for backend services
✅ Enable deletion protection in production
✅ Use HTTPS with valid certificates
✅ Configure appropriate health check paths
✅ Enable access logs for troubleshooting
✅ Use multiple AZs for high availability
