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

# ==============================================================================
# Rule Group Versioning - Map-Based
# ==============================================================================
variable "rule_group_versions" {
  description = "Map of rule group versions to create"
  type = map(object({
    name_suffix        = string
    description_suffix = string
    stateless_rules    = any
    custom_actions     = optional(any, {})
    tags               = optional(map(string), {})
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

variable "prevent_deletion" {
  description = "Prevent deletion of specific rule group versions"
  type        = map(bool)
  default     = {}
}

# ==============================================================================
# Default Rule Configuration
# ==============================================================================
variable "stateless_rules" {
  description = "Default stateless rules configuration"
  type        = any
  default     = {}
}

variable "custom_actions" {
  description = "Default custom actions"
  type        = any
  default     = {}
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