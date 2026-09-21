# Infrastructure Recreation Guide

This guide explains how to recreate your entire AWS infrastructure from scratch. You can choose to do this automatically using Terraform (recommended) or manually via the AWS Console.

---

## Option 1: Automated Recreation using Terraform (Recommended)

This is the fastest and least error-prone method.

### Prerequisites
1. [Download and install Terraform](https://developer.hashicorp.com/terraform/downloads).
2. Ensure you are logged into the AWS CLI (`aws configure`).

### Deployment Steps

1. **Initialize Terraform:**
   Open your terminal, navigate to the terraform directory, and run `init` to download the AWS plugins:
   ```bash
   cd infrastructure/terraform
   terraform init
   ```

2. **Preview Changes:**
   Run a plan to see exactly what AWS resources Terraform is about to create. You must provide a secure password for your database:
   ```bash
   terraform plan -var="db_password=YourSuperSecretPassword!"
   ```

3. **Apply and Create:**
   Deploy the infrastructure:
   ```bash
   terraform apply -var="db_password=YourSuperSecretPassword!"
   ```
   *(Type `yes` when prompted. This will take roughly 5-10 minutes as the RDS database and CloudFront distribution take time to spin up).*

4. **Note the Outputs:**
   When finished, Terraform will print the URLs you need in green text:
   - `alb_dns_name`: Your backend API URL.
   - `cloudfront_domain_name`: Your frontend website URL.

5. **CRITICAL FINAL STEP: Deploy Application Code:**
   Terraform only creates the *empty containers* (ECR, S3, ECS). You must now push your code into them!
   - Go to your GitHub repository.
   - Run your **Backend GitHub Action Pipeline** to build and push the Docker image to ECR.
   - Run your **Frontend GitHub Action Pipeline** to build and push the Flutter web app to S3.
   - Once the code is uploaded, your ECS tasks will automatically start running!

---

## Option 2: Manual Recreation via AWS Console (ClickOps)

If you prefer not to use Terraform, you can recreate everything by clicking through the AWS Management Console. Follow these steps in exact order to satisfy dependencies.

### Step 1: Networking & Security
1. **VPC:** Go to VPC Dashboard -> Create VPC. Use the "VPC and more" wizard. Select 2 Availability Zones, 2 Public subnets, 2 Private subnets, and 1 NAT Gateway.
2. **Security Groups:** 
   - Create `alb-sg`: Inbound HTTP (80) from `0.0.0.0/0`.
   - Create `ecs-sg`: Inbound Custom TCP (8000) with source set to `alb-sg`.
   - Create `rds-sg`: Inbound PostgreSQL (5432) with source set to `ecs-sg`.

### Step 2: Database (RDS)
1. Go to RDS -> Subnet Groups. Create a subnet group selecting your two Private subnets.
2. Go to RDS -> Databases -> Create Database.
3. Select PostgreSQL. Choose the `db.t3.micro` instance type.
4. Set the master username (e.g., `postgres`) and password.
5. In Connectivity, select your VPC and the `rds-sg` Security Group. Make sure "Public access" is **No**.

### Step 3: Container Registry & Initial Image Push
1. Go to ECR (Elastic Container Registry) -> Create repository named `control-center-backend`.
2. **Important:** Before you can create the ECS Service, there *must* be an image in this repository. Trigger your Backend CI/CD Pipeline (GitHub Action) now so it pushes the first Docker image.

### Step 4: Application Load Balancer (ALB)
1. Go to EC2 -> Target Groups. Create a target group: Type `IP addresses`, Protocol `HTTP`, Port `8000`. Health check path `/docs`.
2. Go to EC2 -> Load Balancers. Create an Application Load Balancer.
3. Select Internet-facing. Select your VPC and the two Public Subnets.
4. Select the `alb-sg` Security Group.
5. Add a Listener on Port 80 that forwards traffic to the Target Group you just created.

### Step 5: Compute (ECS Fargate)
1. Go to IAM -> Roles. Ensure `ecsTaskExecutionRole` exists with the `AmazonECSTaskExecutionRolePolicy` attached.
2. Go to ECS -> Clusters. Create a cluster named `control-center-cluster`.
3. Go to Task Definitions -> Create new Task Definition. Name it `control-center-backend-task`, select AWS Fargate.
4. Add a container named `backend`, paste your ECR Image URI, and set port mapping to `8000`.
5. Under Environment variables, add `DATABASE_URL` with your RDS connection string.
6. Go back to your Cluster -> Services -> Create Service.
7. Select Fargate, your task definition, desired count `1`.
8. Under Networking, select your VPC, your Private Subnets, and the `ecs-sg`.
9. Under Load Balancing, select your ALB and target group.

### Step 6: Frontend Hosting (S3 & CloudFront)
1. Go to S3 -> Create a private bucket for your frontend.
2. Go to CloudFront -> Create Distribution.
3. Select your S3 bucket as the Origin.
4. For Origin access, select "Origin access control settings" (OAC). Create a new control setting.
5. Finish creating the distribution. CloudFront will give you a Bucket Policy JSON.
6. Go back to S3 -> Permissions -> Edit Bucket Policy, and paste the JSON CloudFront gave you.
7. **Important:** Trigger your Frontend CI/CD Pipeline (GitHub Action) to build your Flutter app and push the files to this new S3 bucket.

Your infrastructure is now fully recreated!
