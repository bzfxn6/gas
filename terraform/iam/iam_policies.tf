variable "role_arns" {
  description = "Map of role ARNs to attach policies to"
  type = map(string)
}

variable "policies" {
  description = "Map of policies to attach to roles"
  type = map(object({
    name = string
    policy = string
    role_key = string  # Key in role_arns map to attach this policy to
  }))
}

# Create the IAM policies
resource "aws_iam_policy" "policy" {
  for_each = var.policies
  
  name        = each.value.name
  policy      = each.value.policy
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each = var.policies
  
  role       = var.role_arns[each.value.role_key]
  policy_arn = aws_iam_policy.policy[each.key].arn
}

# Output the policy ARNs
output "policy_arns" {
  description = "ARNs of the created IAM policies"
  value = {
    for k, v in aws_iam_policy.policy : k => v.arn
  }
} 