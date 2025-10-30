# ==============================================================================
# Variables - Perimeter Policy
# ==============================================================================

variable "network_firewall_name" {
  description = "Name of the existing network firewall (created by LZA)"
  type        = string
}

variable "network_firewall_policy_name" {
  description = "Name for the firewall policy"
  type        = string
}

variable "description" {
  description = "Description of the firewall policy"
  type        = string
  default     = "Perimeter network firewall policy"
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

# Stateful configuration
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
  description = "List of AWS managed stateful rule groups to attach"
  type = list(object({
    resource_arn = string
    priority     = number
  }))
  default = []
}

variable "custom_stateful_groups" {
  description = "List of custom stateful rule groups to attach"
  type = list(object({
    resource_arn = string
    priority     = number
  }))
  default = []
}

# Stateless configuration
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
  description = "Tags to apply to the policy"
  type        = map(string)
  default     = {}
}