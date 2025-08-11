# Create CloudWatch dashboards
resource "aws_cloudwatch_dashboard" "dashboard" {
  for_each = var.dashboards
  
  dashboard_name = each.value.name
  dashboard_body = each.value.dashboard_body
} 