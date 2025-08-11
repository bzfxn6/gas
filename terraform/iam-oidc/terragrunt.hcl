include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "."
}

# Test configuration
terraform {
  before_hook "test" {
    commands = ["test"]
    execute  = ["bash", "${get_terragrunt_dir()}/tests/set_test_env.sh"]
  }
} 