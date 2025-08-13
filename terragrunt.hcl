# Root Terragrunt configuration

terraform {
  # This is a root configuration file
}

# Hooks for running scripts before terraform operations
before_hook "generate_hashes" {
  commands     = ["plan", "apply", "destroy"]
  execute      = ["bash", "-c", "cd ${get_terragrunt_dir()}/test-lambda-module && ./test-script.sh"]
  run_on_error = false
} 