# ==============================================================================
# Base Configuration
# ==============================================================================
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where firewall is deployed"
  type        = string
}

variable "network_firewall_name" {
  description = "Name of the Network Firewall"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = ""
}

# ==============================================================================
# Policy Versioning - Map-Based
# ==============================================================================
variable "policy_versions" {
  description = "Map of policy versions to create"
  type = map(object({
    name_suffix = string
    description = string
    tags        = optional(map(string), {})
  }))
  default = {
    primary = {
      name_suffix = ""
      description = "Primary firewall policy"
      tags        = {}
    }
  }
}

variable "active_policy_version" {
  description = "Which policy version should be active on the firewall"
  type        = string
  default     = "primary"

  validation {
    condition     = var.active_policy_version != ""
    error_message = "active_policy_version cannot be empty"
  }
}

# ==============================================================================
# Base Policy Configuration
# ==============================================================================
variable "network_firewall_policy_name" {
  description = "Base name for firewall policies"
  type        = string
}

variable "stateful_default_actions" {
  description = "Default actions for stateful traffic"
  type        = list(string)
  default     = ["aws:drop_established"]
}

variable "aws_managed_stateful_groups" {
  description = "List of AWS managed rule groups with priorities"
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

variable "custom_stateful_groups" {
  description = "List of custom stateful rule groups with priorities"
  type = list(object({
    arn      = string
    priority = number
  }))
  default = []
}

variable "tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
  default     = {}
}