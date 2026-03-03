###############################################
# Importing the already existing nfw #
###############################################
data "aws_networkfirewall_firewall" "existing_firewall" {
  name = var.network_firewall_name # "your-existing-firewall-name" imported using terragrunt as it was created using LZA
}

# Imported the existing NFW below as it was created using LZA
# example:
# terragrunt import aws_networkfirewall_firewall.existing_firewall arn:aws:network-firewall:eu-west-2:<aws-account-id>:firewall/<existing-nfw-name>

import {
  to = aws_networkfirewall_firewall.existing_firewall
  id = "arn:aws:network-firewall:eu-west-2:${var.account_id}:firewall/${var.network_firewall_name}"
}

resource "aws_networkfirewall_firewall" "existing_firewall" {
  name                   = var.network_firewall_name ## Existing firewall name
  vpc_id                 = var.vpc_id                ## Use the existing VPC ID
  firewall_policy_arn    = aws_networkfirewall_firewall_policy.policy.arn
  enabled_analysis_types = var.enabled_analysis_types
  delete_protection                 = true
  firewall_policy_change_protection = true
  subnet_change_protection          = true

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  # Subnet mappings (use the existing subnets here)
  dynamic "subnet_mapping" {
    for_each = data.aws_networkfirewall_firewall.existing_firewall.subnet_mapping
    content {
      subnet_id = subnet_mapping.value.subnet_id
    }
  }
  ## Keeping the old tags when it was created first time
  tags = {
    "Accelerator" = "AWSAccelerator"
    "Name"        = var.network_firewall_name
  }
  # Add other necessary attributes here
}

################
## nfw-policy  #
################

# Reading rule groups from text file supplied
locals {
  rule_group_arns = split("\n", trimspace(var.aws_managed_rule_groups))
}

resource "aws_networkfirewall_firewall_policy" "policy" {
  name = var.network_firewall_policy_name

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  firewall_policy {
    # Reference AWS managed or custom stateful rule groups

    # Specify stateful default actions
    stateful_default_actions = var.enabled_drop_stateful_default_actions ? ["aws:drop_established", "aws:alert_established"] : ["aws:alert_established"]

    # Configure stateful engine options
    stateful_engine_options {
      rule_order = "STRICT_ORDER" # Options: "STRICT_ORDER" or "DEFAULT_ACTION_ORDER"
    }

    dynamic "stateful_rule_group_reference" {
      for_each = local.rule_group_arns

      content {
        resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/${stateful_rule_group_reference.value}"
        priority     = 200 + index(local.rule_group_arns, stateful_rule_group_reference.value) + 1
      }
    }

    # custom rules defined by core-cloud-platform
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_domains_for_nonprod_01.arn
      priority     = 250
    }

    # Define the stateless default actions explicitly
    stateless_default_actions = ["aws:forward_to_sfe"]

    # Define the stateless fragment default actions explicitly
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }

  tags = {
    Name = var.network_firewall_policy_name
  }
}

