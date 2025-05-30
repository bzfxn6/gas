variable "oidc_url" {
  description = "The OIDC provider URL from your EKS cluster"
  type        = string
}

variable "namespace" {
  description = "The Kubernetes namespace where the service account will be created"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "The name of the Kubernetes service account"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 