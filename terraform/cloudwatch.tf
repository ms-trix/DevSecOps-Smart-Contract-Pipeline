resource "aws_cloudwatch_log_group" "pipeline" {
  name              = "/devsecops/pipeline"
  retention_in_days = 90

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "high_findings" {
  name           = "HighSeverityFindings"
  log_group_name = aws_cloudwatch_log_group.pipeline.name
  pattern        = "FAILED"

  metric_transformation {
    name          = "HighSeverityFindings"
    namespace     = "DevSecOps/Pipeline"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "pipeline_pass" {
  name           = "PipelinePass"
  log_group_name = aws_cloudwatch_log_group.pipeline.name
  pattern        = "PASSED"

  metric_transformation {
    name          = "PipelinePass"
    namespace     = "DevSecOps/Pipeline"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_findings_alarm" {
  alarm_name          = "${var.project_name}-high-severity-findings"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HighSeverityFindings"
  namespace           = "DevSecOps/Pipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Triggered when high severity findings are detected in smart contracts"

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "ai_remediation_success" {
  name           = "AIRemediationSuccess"
  log_group_name = aws_cloudwatch_log_group.pipeline.name
  pattern        = "AI remediation report generated successfully"

  metric_transformation {
    name          = "AIRemediationSuccess"
    namespace     = "DevSecOps/Pipeline"
    value         = "1"
    default_value = "0"
  }
}