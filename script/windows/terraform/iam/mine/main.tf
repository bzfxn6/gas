# Create the base IAM roles
resource "aws_iam_role" "gss_role" {
  for_each = {
    for k, v in var.iam_roles : k => v if v.role_config != null
  }
  name               = "${var.prefix}-${each.key}-role"
  assume_role_policy = jsonencode(lookup(each.value, "role_config"))
  tags = merge(
    var.tags,
    {
      name = each.key
    },
  )
}

# Create the policy for the IAM Role, now we have two ways of creating a policy, need to check if there is one to create.
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

# Attach the policy to the IAM role, Need to check role config and policy config exist.
resource "aws_iam_role_policy_attachment" "gss_attachment" {
  for_each = {
    for k, v in var.iam_roles : k => v if v.role_config != null && contains(keys(v), "policy_config")
  }
  role       = aws_iam_role.gss_role[each.key].name
  policy_arn = aws_iam_policy.gss_policy[each.key].arn
}

# Create instance profiles if needed
resource "aws_iam_instance_profile" "gss_ec2_instance_profile" {
  for_each = {
    for key, role in var.iam_roles :
    key => role if lookup(role, "create_instance_profile", false) == true
  }
  name = "${var.prefix}-${each.key}-instance-profile"
  role = aws_iam_role.gss_role[each.key].name
  tags = merge(
    var.tags,
    {
      name = each.key
    },
  )
}

# Check to see if ssm_name is in the map file, if it is create a ssm paramaeter with the role name and using the name provided
# the ssm parameter will hold the role ARN, used within helm charts.
resource "aws_ssm_parameter" "service_role" {
  for_each = {
    for key, role in var.iam_roles :
    key => role if contains(keys(role), "ssm_name")
  }
 
  name  = var.custom_prefix != "" ? "/${var.custom_prefix}/iam_roles/${var.ssm_prefix}-${aws_iam_role.gss_role[each.key]}-role" : "/${var.prefix}-${each.value.ssm_name}/iam_roles/${var.ssm_prefix}-${each.key}-role"
 
  type  = "String"
  value = aws_iam_role.gss_role[each.key].arn
  tags = merge(
  var.tags,
  {
    name = each.key
  },
)
}

# Output role ARNs for use by other modules
output "role_arns" {
  description = "ARNs of the created IAM roles"
  value = {
    for k, v in aws_iam_role.gss_role : k => v.arn
  }
}

output "role_names" {
  description = "Names of the created IAM roles"
  value = {
    for k, v in aws_iam_role.gss_role : k => v.name
  }
}