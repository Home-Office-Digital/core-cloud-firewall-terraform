# ==============================================================================
# Variables - Perimeter Policy (with Versioning)
# ==============================================================================

variable "network_firewall_name" {
  description = "Name of the existing network firewall (created by LZA)"
  type        = string
}

variable "network_firewall_policy_name" {
  description = "Base name for the firewall policy (version suffix will be added)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the firewall is deployed"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

# ==============================================================================
# Versioning Configuration
# ==============================================================================

variable "active_policy_version" {
  description = <<-EOT
    Which policy version the firewall should actively use.
    Must match a key in policy_versions map.
    Examples: "primary", "secondary"
  EOT
  type        = string
  default     = "primary"
}

variable "policy_versions" {
  description = <<-EOT
    Map of policy versions to create. Each version can reference different rule group versions.

    Structure:
    {
      "primary" = {
        name_suffix             = ""           # e.g., "" or "-v2"
        description             = "..."
        custom_stateful_groups  = [...]        # Version-specific rule group ARNs
        tags                    = {...}
      }
    }
  EOT
  type = map(object({
    name_suffix            = string
    description            = string
    custom_stateful_groups = list(object({
      resource_arn = string
      priority     = number
    }))
    tags = map(string)
  }))

  default = {
    primary = {
      name_suffix            = ""
      description            = "Primary perimeter firewall policy"
      custom_stateful_groups = []
      tags                   = {}
    }
  }
}

# ==============================================================================
# Stateful Configuration
# ==============================================================================

variable "stateful_default_actions" {
  description = "Default actions for stateful traffic"
  type        = list(string)
  default     = ["aws:drop_established", "aws:alert_established"]
}

variable "stateful_rule_order" {
  description = "Rule evaluation order (STRICT_ORDER or DEFAULT_ACTION_ORDER)"
  type        = string
  default     = "STRICT_ORDER"
}

variable "aws_managed_stateful_groups" {
  description = "List of AWS managed stateful rule groups to attach (shared across all policy versions)"
  type = list(object({
    resource_arn = string
    priority     = number
  }))
  default = []
}

# ==============================================================================
# Stateless Configuration
# ==============================================================================

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

variable "tags" {
  description = "Tags to apply to all policy versions"
  type        = map(string)
  default     = {}
}