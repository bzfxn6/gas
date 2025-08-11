locals {
  permissions = {
    for role, role_config in var.iam_roles :
    "${var.prefix}-${role}-role" =>
    role_config.permissions if contains(keys(role_config), "permissions")
  }
}
 
# If this role is used with helm charts, there is module to configure services they require.
# We pass local.permissions to the module to add the extra configuration they need.
# This will come from the permissions in the map file.
module "iam_services_permissions" {
  source      = "github.com/Global-Screening-Services/terraform-aws-iam-services-permissions?ref=v1.0.1"
  permissions = local.permissions
  depends_on = [ aws_iam_role.gss_role ]
}