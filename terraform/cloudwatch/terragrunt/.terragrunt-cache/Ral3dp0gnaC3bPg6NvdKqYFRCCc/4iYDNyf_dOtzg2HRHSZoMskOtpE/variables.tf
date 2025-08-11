variable "dashboards" {
  description = "Map of CloudWatch dashboards to create"
  type = map(object({
    name = string
    dashboard_body = string
  }))
}



 