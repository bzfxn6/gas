# Create the policy for the IAM Role
resource "aws_iam_policy" "gss_policy" {
  for_each = {
    for k, v in var.iam_roles : k => v if contains(keys(v), "policy_config")
  }
  name        = "${var.prefix}-${each.key}-policy"
  description = "Instance profile policy for ${each.key}"
  policy      = jsonencode(lookup(each.value, "policy_config"))
  tags = merge(
    var.tags,
    {
      name = each.key
    },
  )
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "gss_attachment" {
  for_each = {
    for k, v in var.iam_roles : k => v if v.role_config != null && contains(keys(v), "policy_config")
  }
  role       = aws_iam_role.gss_role[each.key].name
  policy_arn = aws_iam_policy.gss_policy[each.key].arn
}

# Service permissions module
module "iam_services_permissions" {
  source      = "github.com/Global-Screening-Services/terraform-aws-iam-services-permissions?ref=v1.0.1"
  permissions = local.permissions
  # Remove the depends_on to prevent role recreation
}

# Output policy ARNs
output "policy_arns" {
  description = "ARNs of the created IAM policies"
  value = {
    for k, v in aws_iam_policy.gss_policy : k => v.arn
  }
} 