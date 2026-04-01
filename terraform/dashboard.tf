resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project_name}-pipeline"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "High Severity Findings"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [
            ["DevSecOps/Pipeline", "HighSeverityFindings"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "Pipeline Pass Rate"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [
            ["DevSecOps/Pipeline", "PipelinePass"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "AI Remediation Success"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [
            ["DevSecOps/Pipeline", "AIRemediationSuccess"]
          ]
        }
      }
    ]
  })
}