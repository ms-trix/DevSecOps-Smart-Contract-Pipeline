output "reports_bucket_name" {
  description = "S3 bucket name for security reports"
  value       = aws_s3_bucket.reports.bucket
}

output "reports_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.reports.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — add this as AWS_ROLE_ARN secret in GitHub"
  value       = aws_iam_role.github_actions.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.pipeline.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.pipeline.dashboard_name}"
}