# ==============================================================================
# Variables - Perimeter Rule Group (with Versioning Support)
# ==============================================================================

variable "name" {
  description = "Base name for rule groups (version suffix will be added)"
  type        = string
}

variable "description" {
  description = "Base description for rule groups (version suffix will be added)"
  type        = string
}

variable "capacity" {
  description = "Maximum capacity (processing units) for the rule group"
  type        = number
  default     = 2000
}

variable "home_net_cidr_ranges" {
  description = "List of CIDR ranges that define HOME_NET (source traffic)"
  type        = list(string)
}

# ==============================================================================
# Versioning Configuration
# ==============================================================================

variable "rule_group_versions" {
  description = <<-EOT
    Map of rule group versions to create. Each version can have different domains.

    Structure:
    {
      "primary" = {
        name_suffix         = ""           # e.g., "" or "-v2"
        description_suffix  = ""           # e.g., "" or " (v2)"
        whitelisted_domains = ["..."]      # List of domains for this version
        tags                = {...}        # Additional tags for this version
      }
    }
  EOT
  type = map(object({
    name_suffix         = string
    description_suffix  = string
    whitelisted_domains = list(string)
    tags                = map(string)
  }))

  default = {
    primary = {
      name_suffix         = ""
      description_suffix  = ""
      whitelisted_domains = []
      tags                = {}
    }
  }
}

variable "enabled_analysis_types" {
  description = "Types of domain matching to enable (TLS_SNI, HTTP_HOST)"
  type        = list(string)
  default     = ["TLS_SNI", "HTTP_HOST"]
}

variable "stateful_rule_order" {
  description = "Rule evaluation order (STRICT_ORDER or DEFAULT_ACTION_ORDER)"
  type        = string
  default     = "STRICT_ORDER"
}

variable "encryption_configuration" {
  description = "Encryption configuration for the rule group. Set to null to disable encryption."
  type = object({
    key_id = string
    type   = string
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all rule group versions"
  type        = map(string)
  default     = {}
}