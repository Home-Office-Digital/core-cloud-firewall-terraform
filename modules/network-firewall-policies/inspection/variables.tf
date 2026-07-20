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
# Policy Versioning - Map-Based with Per-Policy Rule Groups
# ==============================================================================
variable "policy_versions" {
  description = "Map of policy versions to create, each with its own rule group references"
  type = map(object({
    name_suffix = string
    description = string
    tags        = optional(map(string), {})

    # Each policy version specifies which rule groups it uses
    custom_stateful_groups = list(object({
      arn      = string
      priority = number
    }))

    custom_stateless_groups = list(object({
      resource_arn = string
      priority     = number
    }))
  }))

  default = {
    primary = {
      name_suffix             = ""
      description             = "Primary firewall policy"
      tags                    = {}
      custom_stateful_groups  = []
      custom_stateless_groups = []
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
  description = "Base name for firewall policies (version suffix will be appended)"
  type        = string
}

variable "stateful_default_actions" {
  description = "Default actions for stateful traffic"
  type        = list(string)
  default     = ["aws:drop_established"]
}

variable "stateful_rule_order" {
  description = "Rule evaluation order (STRICT_ORDER or DEFAULT_ACTION_ORDER)"
  type        = string
  default     = "STRICT_ORDER"
}

variable "stateless_default_actions" {
  description = "Default actions for stateless traffic"
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_fragment_default_actions" {
  description = "Default actions for stateless fragmented packets"
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}

variable "aws_managed_stateful_groups" {
  description = "List of AWS managed rule groups with priorities (shared across all policy versions)"
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

variable "tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
  default     = {}
}