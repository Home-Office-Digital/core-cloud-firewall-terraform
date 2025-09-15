
############################################
# Read the existing Network Firewall (LZA-made)
############################################

data "aws_networkfirewall_firewall" "imported" {
  name = var.network_firewall_name
}

import {
  to = aws_networkfirewall_firewall.existing
  id = "arn:aws:network-firewall:eu-west-2:${var.account_id}:firewall/${var.network_firewall_name}"
}

############################################
# Take ownership of the existing firewall
############################################

resource "aws_networkfirewall_firewall" "existing" {
  name                = var.network_firewall_name
  vpc_id              = var.vpc_id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn

  # Mirror the existing subnet mappings so plans stay clean
  dynamic "subnet_mapping" {
    for_each = data.aws_networkfirewall_firewall.imported.subnet_mapping
    content {
      subnet_id = subnet_mapping.value.subnet_id
    }
  }

  # Preserve original tags
  tags = {
    Accelerator = "AWSAccelerator"
    Name        = var.network_firewall_name
  }

  # Keep LZA-driven drift on tags quiet:
  lifecycle {
     ignore_changes = [tags]
   }
}

############################################
# Firewall Policy
############################################
resource "aws_networkfirewall_firewall_policy" "policy" {
  name = var.network_firewall_policy_name

  firewall_policy {
    stateful_default_actions = var.stateful_default_actions

    # Stateful engine behavior
    stateful_engine_options {
      rule_order = "STRICT_ORDER" 
    }

    #  AWS-managed stateful rule groups (names -> ARNs)
    dynamic "stateful_rule_group_reference" {
      for_each = var.aws_managed_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.name
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Custom stateful rule groups (full ARNs)
    dynamic "stateful_rule_group_reference" {
      for_each = var.custom_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Stateless defaults (explicit)
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }

  tags = {
    Name = var.network_firewall_policy_name
  }
}