# ==============================================================================
# Variables - Perimeter Rule Group
# ==============================================================================

variable "name" {
  description = "Name of the rule group"
  type        = string
}

variable "description" {
  description = "Description of the rule group"
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

variable "whitelisted_domains" {
  description = "List of domains to whitelist for egress traffic"
  type        = list(string)
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
  description = "Encryption configuration for the rule group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the rule group"
  type        = map(string)
  default     = {}
}