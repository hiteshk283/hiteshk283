variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "control-center"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Database master user"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "control_center_db"
}

variable "frontend_bucket_name" {
  description = "The globally unique name for the S3 bucket hosting the frontend"
  type        = string
  default     = "control-center-frontend-hiteshk283"
}

variable "backend_port" {
  description = "Port the ECS container listens on"
  type        = number
  default     = 8000
}
