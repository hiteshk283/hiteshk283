# Networking Infrastructure

The application relies on a secure and highly available Virtual Private Cloud (VPC) setup on AWS.

## Components

### 1. Virtual Private Cloud (VPC)
- Provides an isolated network environment for the ECS cluster and RDS database.
- Split into **Public Subnets** (for the Load Balancer) and **Private Subnets** (for the ECS Tasks and RDS instance).

### 2. Application Load Balancer (ALB)
- Acts as the single entry point for all API and WebSocket traffic from the Flutter clients.
- Sits in the Public Subnet and listens on Port 80 (HTTP) or 443 (HTTPS).
- Routes traffic to a **Target Group** containing the ephemeral IP addresses of the running ECS Fargate tasks.

### 3. Security Groups
Security groups act as virtual firewalls for the resources:
- **ALB Security Group**: Allows inbound HTTP/HTTPS traffic from the internet (`0.0.0.0/0`).
- **ECS Security Group**: Allows inbound traffic on Port `8000` **only** from the ALB Security Group. This ensures the containers cannot be accessed directly from the internet.
- **RDS Security Group**: Allows inbound traffic on Port `5432` (PostgreSQL) **only** from the ECS Security Group (and potentially from a bastion host for debugging).
