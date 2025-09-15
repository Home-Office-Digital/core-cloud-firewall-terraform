############################################
# Variables
############################################

variable "account_id" {
  type        = string
}

variable "region" {
  description = "AWS region for Network Firewall ARNs"
  type        = string
  default     = "eu-west-2"
}


variable "network_firewall_name" {
  description = "Existing Network Firewall name (created by LZA)"
  type        = string
}

variable "network_firewall_policy_name" {
  description = "Firewall policy name to apply"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID of the existing firewall"
  type        = string
}

# AWS-managed stateful rule groups (names + priorities)
variable "aws_managed_stateful_groups" {
  description = "List of AWS-managed stateful rule groups by name with priorities."
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

#  Custom stateful rule groups (full ARNs + priorities)
variable "custom_stateful_groups" {
  description = "List of custom stateful rule groups (full ARNs) with priorities."
  type = list(object({
    arn      = string
    priority = number
  }))
  default = []
}

variable "stateful_default_actions" {
  description = "Stateful default actions for NFW policy."
  type        = list(string)

  validation {
    condition = alltrue([
      for a in var.stateful_default_actions :
      contains(["aws:drop_established", "aws:alert_established"], a)
    ])
    error_message = "Only 'aws:drop_established' and 'aws:alert_established' are allowed."
  }
}
