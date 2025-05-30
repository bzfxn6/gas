variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    name = string
    path = optional(string, "/")
    assume_role_policy = string
    tags = optional(map(string), {})
  }))
}

# Create the IAM roles
resource "aws_iam_role" "role" {
  for_each = var.roles
  
  name               = each.value.name
  path               = each.value.path
  assume_role_policy = each.value.assume_role_policy
  tags               = each.value.tags
}

# Output the role ARNs for use by other modules
output "role_arns" {
  description = "ARNs of the created IAM roles"
  value = {
    for k, v in aws_iam_role.role : k => v.arn
  }
}

output "role_names" {
  description = "Names of the created IAM roles"
  value = {
    for k, v in aws_iam_role.role : k => v.name
  }
} 