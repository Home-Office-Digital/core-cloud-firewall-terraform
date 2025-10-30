# ==============================================================================
# Perimeter Network Firewall Policy
# ==============================================================================

# Read the existing firewall (created by LZA)
data "aws_networkfirewall_firewall" "imported" {
  name = var.network_firewall_name
}

# Import block for existing firewall
import {
  to = aws_networkfirewall_firewall.existing
  id = "arn:aws:network-firewall:${var.aws_region}:${var.account_id}:firewall/${var.network_firewall_name}"
}

resource "aws_networkfirewall_firewall" "existing" {
  name                = var.network_firewall_name
  vpc_id              = var.vpc_id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn

  dynamic "subnet_mapping" {
    for_each = data.aws_networkfirewall_firewall.imported.subnet_mapping
    content {
      subnet_id = subnet_mapping.value.subnet_id
    }
  }

  # Preserve original LZA tags
  tags = {
    Accelerator = "AWSAccelerator"
    Name        = var.network_firewall_name
  }

  # Ignore tag drift from LZA
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create the firewall policy
resource "aws_networkfirewall_firewall_policy" "policy" {
  name        = var.network_firewall_policy_name
  description = var.description

  firewall_policy {
    # Stateful configuration
    stateful_default_actions = var.stateful_default_actions

    stateful_engine_options {
      rule_order = var.stateful_rule_order
    }

    # AWS managed stateful rule groups
    dynamic "stateful_rule_group_reference" {
      for_each = var.aws_managed_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.resource_arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Custom stateful rule groups
    dynamic "stateful_rule_group_reference" {
      for_each = var.custom_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.resource_arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Stateless configuration
    stateless_default_actions          = var.stateless_default_actions
    stateless_fragment_default_actions = var.stateless_fragment_default_actions
  }

  tags = var.tags
}