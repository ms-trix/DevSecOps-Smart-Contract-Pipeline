variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "358344803500"
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "ms-trix/DevSecOps-Smart-Contract-Pipeline"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "devsecops-smart-contract"
}