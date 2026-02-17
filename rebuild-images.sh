#!/bin/bash

# Fix for Docker Architecture Mismatch
# EC2 instances are linux/amd64, but your images were built for different architecture

echo "Building Docker images for linux/amd64 platform..."

# Frontend
echo "Building frontend..."
cd /path/to/your/frontend
docker buildx build --platform linux/amd64 -t abhi00shek/goal-tracker-frontend:v1 --push .

# Backend
echo "Building backend..."
cd /path/to/your/backend
docker buildx build --platform linux/amd64 -t abhi00shek/goal-tracker-backend:v1 --push .

echo "✅ Images rebuilt and pushed for linux/amd64"
echo ""
echo "Now trigger instance refresh:"
echo "aws autoscaling start-instance-refresh --auto-scaling-group-name dev-goal-tracker-frontend-asg --region us-east-1"
echo "aws autoscaling start-instance-refresh --auto-scaling-group-name dev-goal-tracker-backend-asg --region us-east-1"
