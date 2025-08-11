output "dashboard_count" {
  description = "Number of CloudWatch dashboards created"
  value       = length(var.dashboards)
}

output "dashboard_details" {
  description = "Detailed information about created CloudWatch dashboards"
  value = {
    for k, v in aws_cloudwatch_dashboard.dashboard : k => {
      name = v.dashboard_name
      arn  = v.dashboard_arn
    }
  }
} 