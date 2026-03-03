# variables
variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "Network Firewall Account-id"
  type        = string
}

variable "network_firewall_name" {
  description = "Network Firewall name to be supplied"
  type        = string
}

variable "network_firewall_policy_name" {
  description = "Network Firewall Policy name to be supplied"
  type        = string
}

variable "vpc_id" {
  description = "VPC associated with Network Firewall"
  type        = string
}

variable "home_net_cidr_ranges" {
  description = "A set of CIDR ranges used fro the `HOME_NET` rule variable."
  type        = set(string)
}

variable "whitelisted_domains" {
  description = "Network Firewall - whitelisted domains file"
  type        = string
}

variable "aws_managed_rule_groups" {
  description = "Network Firewall - A list of AWS managed stateful rule group arns"
  type        = string
}

variable "enabled_analysis_types" {
  description = "Types of analysis metrics (TLS_SNI, HTTP_HOST) to collect"
  type        = list(string)
  default     = []
}

variable "network_firewall_rule_group_name" {
  description = "Network Firewall Rule Group name to be supplied"
  type        = string
}

variable "enabled_drop_stateful_default_actions" {
  description = "Give the stateful rule the permission aws:drop_established"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Customer managed KMS key ARN for Network Firewall encryption"
  type        = string
}
