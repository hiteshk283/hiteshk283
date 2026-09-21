# export_aws_state.ps1
# This script uses the AWS CLI to export the current configuration of your manually created infrastructure.
# It saves the output into JSON files so you have a complete reference when recreating it later.

$ExportDir = "aws_infra_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Force -Path $ExportDir | Out-Null

Write-Host "Exporting infrastructure state to folder: $ExportDir..."

# 1. ECS (Elastic Container Service)
Write-Host "Exporting ECS configuration..."
aws ecs describe-clusters --clusters control-center-cluster > "$ExportDir\ecs_cluster.json"
aws ecs describe-services --cluster control-center-cluster --services control-center-backend-task-service > "$ExportDir\ecs_service.json"
aws ecs describe-task-definition --task-definition control-center-backend-task > "$ExportDir\ecs_task_def.json"

# 2. ECR (Elastic Container Registry)
Write-Host "Exporting ECR configuration..."
aws ecr describe-repositories --repository-names control-center-backend > "$ExportDir\ecr_repo.json"

# 3. Frontend Hosting (S3 & CloudFront)
Write-Host "Exporting Frontend configuration..."
aws s3api get-bucket-policy --bucket control-center-frontend-hiteshk283 > "$ExportDir\s3_bucket_policy.json" 2>$null
aws s3api get-public-access-block --bucket control-center-frontend-hiteshk283 > "$ExportDir\s3_public_access_block.json" 2>$null
aws cloudfront get-distribution --id E2ALGJR4OOW90A > "$ExportDir\cloudfront_distribution.json"

# 4. Networking (VPC, Subnets, ALB, Security Groups)
# Note: Since we don't have the exact IDs, we export all for reference. 
# You can filter by name if you tagged them!
Write-Host "Exporting Networking configuration..."
aws ec2 describe-vpcs > "$ExportDir\vpcs.json"
aws ec2 describe-subnets > "$ExportDir\subnets.json"
aws ec2 describe-security-groups > "$ExportDir\security_groups.json"
aws elbv2 describe-load-balancers > "$ExportDir\load_balancers.json"
aws elbv2 describe-target-groups > "$ExportDir\target_groups.json"

# 5. RDS Database
Write-Host "Exporting RDS configuration..."
aws rds describe-db-instances > "$ExportDir\rds_instances.json"

# 6. CloudWatch Logs
Write-Host "Exporting CloudWatch configuration..."
aws logs describe-log-groups --log-group-name-prefix /ecs/control-center-backend > "$ExportDir\cloudwatch_log_groups.json"

# 7. IAM Roles (ECS Execution & GitHub Actions)
Write-Host "Exporting IAM Roles..."
aws iam list-roles > "$ExportDir\iam_roles_all.json"
aws iam list-users > "$ExportDir\iam_users_all.json"

Write-Host "✅ Export complete! All your infrastructure details are saved in the '$ExportDir' folder."
Write-Host "You can now safely refer to these JSON files later to recreate your exact configuration."
