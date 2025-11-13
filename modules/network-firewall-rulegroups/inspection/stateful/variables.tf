# ==============================================================================
# Base Configuration
# ==============================================================================
variable "name" {
  description = "Base name of the rule group"
  type        = string
}

variable "description" {
  description = "Base description of the rule group"
  type        = string
}

variable "capacity" {
  description = "Capacity of the rule group"
  type        = number
}

variable "stateful_rule_order" {
  description = "Rule order (STRICT_ORDER or DEFAULT_ACTION_ORDER)"
  type        = string
  default     = "STRICT_ORDER"
}

# ==============================================================================
# Rule Group Versioning - Map-Based
# ==============================================================================
variable "rule_group_versions" {
  description = "Map of rule group versions to create"
  type = map(object({
    name_suffix         = string
    description_suffix  = string
    suricata_rules_path = string
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "active_rule_group_version" {
  description = "Which rule group version should be active"
  type        = string
  default     = "primary"

  validation {
    condition     = var.active_rule_group_version != ""
    error_message = "active_rule_group_version cannot be empty"
  }
}

# ==============================================================================
# Rule Configuration
# ==============================================================================
variable "suricata_rules" {
  description = "Default suricata rules path or string"
  type        = string
  default     = ""
}

variable "suricata_rules_file" {
  description = "Name of the suricata rules file (used by Terragrunt)"
  type        = string
  default     = "suricata.rules"
}

variable "rule_variables" {
  description = "Rule variables (IP sets and port sets)"
  type = object({
    ipSets   = optional(map(object({
      key    = string
      values = list(string)
    })), {})
    portSets = optional(map(object({
      key    = string
      values = list(string)
    })), {})
  })
  default = {
    ipSets   = {}
    portSets = {}
  }
}

variable "domain_targets" {
  description = "List of domain targets for domain list rule groups"
  type        = list(string)
  default     = []
}

variable "domain_rule_type" {
  description = "Type of rules to generate (ALLOWLIST or DENYLIST)"
  type        = string
  default     = "ALLOWLIST"
}

variable "domain_target_type" {
  description = "Target types for domain rules"
  type        = list(string)
  default     = ["HTTP_HOST", "TLS_SNI"]
}

variable "stateful_rules" {
  description = "List of stateful rules"
  type        = any
  default     = []
}

variable "encryption_configuration" {
  description = "Encryption configuration"
  type        = any
  default     = []
}

variable "tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
  default     = {}
}