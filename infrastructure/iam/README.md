# Identity and Access Management (IAM)

AWS IAM is used to securely manage access to the cloud infrastructure, following the principle of least privilege.

## Key Roles and Policies

### 1. ECS Task Execution Role
- A role assumed by the ECS agent to pull Docker images from Amazon ECR and push container logs to Amazon CloudWatch.
- Attached Policy: `AmazonECSTaskExecutionRolePolicy`.

### 2. ECS Task Role (Optional)
- A role assumed by the *running container itself* if the Python application needs to interact with other AWS services (like uploading files to S3 or reading from SQS).

### 3. GitHub Actions CI/CD User
- An IAM User (or OIDC Provider Role) used by GitHub Actions to deploy the application.
- Has strictly scoped permissions to:
  - `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, etc.
  - `ecs:DescribeTaskDefinition`, `ecs:RegisterTaskDefinition`, `ecs:UpdateService`.
  - `s3:PutObject`, `s3:ListBucket` (for the frontend bucket).
  - `cloudfront:CreateInvalidation`.

### 4. S3 Bucket Policy (OAC/OAI)
- The S3 bucket hosting the frontend is kept private.
- A Bucket Policy is applied granting `s3:GetObject` permissions **only** to the CloudFront Origin Access Control (OAC) or Origin Access Identity (OAI). This forces all users to access the site through the fast, secure CDN rather than the direct S3 URL.
