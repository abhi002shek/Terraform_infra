# 502 Bad Gateway - Troubleshooting Guide

## Root Cause

The 502 Bad Gateway error occurs because:

1. **Docker images don't exist** - The configured images `abhi00shek/goal-tracker-frontend:latest` and `abhi00shek/goal-tracker-backend:latest` haven't been built and pushed to Docker Hub yet
2. **Instances can't pull images** - EC2 instances try to pull non-existent images and fail
3. **No application running** - Without running containers, there's nothing listening on port 3000
4. **Health checks fail** - ALB marks targets as unhealthy
5. **502 error** - ALB has no healthy targets to route traffic to

## Solution: Build and Push Your Docker Images

### Step 1: Prepare Your Application Code

You need the actual Goal Tracker application source code with:
- Frontend (React/Next.js application)
- Backend (Node.js API)
- Dockerfiles for both

### Step 2: Build Docker Images

**Frontend:**
```bash
cd /path/to/your/frontend
docker build -t abhi00shek/goal-tracker-frontend:latest .
```

**Backend:**
```bash
cd /path/to/your/backend
docker build -t abhi00shek/goal-tracker-backend:latest .
```

### Step 3: Push to Docker Hub

```bash
# Login to Docker Hub
docker login
# Enter username: abhi00shek
# Enter password: (your Docker Hub password or access token)

# Push frontend
docker push abhi00shek/goal-tracker-frontend:latest

# Push backend
docker push abhi00shek/goal-tracker-backend:latest
```

### Step 4: Trigger Instance Refresh

Once images are pushed, refresh the ASG instances:

```bash
# Refresh frontend instances
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name dev-goal-tracker-frontend-asg \
  --region us-east-1

# Refresh backend instances
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name dev-goal-tracker-backend-asg \
  --region us-east-1
```

### Step 5: Wait and Test

Wait 3-5 minutes for:
- New instances to launch
- Docker images to pull
- Containers to start
- Health checks to pass

Then test: http://dev-goal-tracker-public-alb-785955905.us-east-1.elb.amazonaws.com

## Alternative: Use Demo Application

If you don't have the application code yet, you can test with a simple demo:

### Create Simple Frontend Dockerfile

```dockerfile
FROM nginx:alpine
RUN echo '<html><body><h1>Goal Tracker Frontend</h1><p>Infrastructure is working!</p></body></html>' > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Build and push:
```bash
docker build -t abhi00shek/goal-tracker-frontend:latest .
docker push abhi00shek/goal-tracker-frontend:latest
```

### Update terraform.tfvars

```hcl
frontend_docker_image = "abhi00shek/goal-tracker-frontend:latest"
target_group_port = 80  # nginx runs on port 80
```

## Debugging Commands

### Check if instances are running
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*frontend*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,State.Name]' \
  --output table \
  --region us-east-1
```

### Check target health
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:616919332376:targetgroup/dev-goal-tracker-public-tg/ebdd006afe63a870 \
  --region us-east-1
```

### SSH to instance (via bastion)
```bash
# SSH to bastion
ssh -i your-key.pem ubuntu@100.50.109.14

# From bastion, SSH to frontend instance
ssh ubuntu@<frontend-private-ip>

# Check Docker containers
sudo docker ps

# Check Docker logs
sudo docker logs goal-tracker-frontend

# Check user data logs
sudo cat /var/log/user-data.log
```

### Check user data execution
```bash
# On the EC2 instance
sudo cat /var/log/user-data.log
sudo docker ps -a
sudo docker logs goal-tracker-frontend
```

## Common Issues

### Issue 1: Docker image doesn't exist
**Symptom:** `docker pull` fails in user data logs
**Solution:** Build and push the image to Docker Hub

### Issue 2: Wrong port mapping
**Symptom:** Container runs but health check fails
**Solution:** Ensure container exposes the correct port (3000 for frontend, 8080 for backend)

### Issue 3: Application crashes on startup
**Symptom:** Container starts then stops
**Solution:** Check docker logs for application errors

### Issue 4: Backend can't connect to database
**Symptom:** Backend container crashes or returns 500 errors
**Solution:** Verify RDS endpoint and credentials in Secrets Manager

## Quick Fix: Use Working Test Image

To verify infrastructure is working, temporarily use a known-good image:

```hcl
# In terraform.tfvars
frontend_docker_image = "nginxdemos/hello:latest"
```

This will show a simple "Hello from nginx" page if infrastructure is working correctly.

## Expected Behavior When Working

1. **Healthy targets:** All instances show "healthy" in target group
2. **HTTP 200:** ALB returns successful response
3. **Application loads:** Frontend displays in browser
4. **No 502 errors:** ALB successfully routes to backend instances

## Next Steps

1. ✅ Infrastructure is deployed correctly
2. ⏳ **YOU ARE HERE** - Need to build and push Docker images
3. ⏳ Trigger instance refresh
4. ⏳ Wait for health checks to pass
5. ⏳ Test application URL

The infrastructure is working correctly. You just need to provide the actual Docker images!
