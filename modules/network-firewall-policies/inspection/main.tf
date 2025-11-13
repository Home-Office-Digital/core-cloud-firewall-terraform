# ==============================================================================
# Data Sources
# ==============================================================================
data "aws_region" "current" {}

data "aws_networkfirewall_firewall" "imported" {
  name = var.network_firewall_name
}

# ==============================================================================
# Build Policy Configurations
# ==============================================================================
locals {
  # Build configuration for each policy version
  policy_configs = {
    for version, config in var.policy_versions : version => {
      name        = "${var.network_firewall_policy_name}${config.name_suffix}"
      description = config.description
      tags = merge(
        var.tags,
        config.tags,
        {
          Version = version
          Status  = var.active_policy_version == version ? "active" : "inactive"
        }
      )
    }
  }

  # Validate active version exists
  active_version_exists = contains(keys(var.policy_versions), var.active_policy_version)
}

# ==============================================================================
# Import Existing Firewall
# ==============================================================================
import {
  to = aws_networkfirewall_firewall.existing
  id = "arn:aws:network-firewall:${coalesce(var.region, data.aws_region.current.name)}:${var.account_id}:firewall/${var.network_firewall_name}"
}

# ==============================================================================
# State Migration: Non-versioned → Versioned
# ==============================================================================
# TODO: Remove this block after all environments migrated
moved {
  from = aws_networkfirewall_firewall_policy.policy
  to   = aws_networkfirewall_firewall_policy.this["primary"]
}

# ==============================================================================
# Create Firewall Policies (Multiple Versions)
# ==============================================================================
resource "aws_networkfirewall_firewall_policy" "this" {
  for_each = local.policy_configs

  name = each.value.name

  firewall_policy {
    stateful_default_actions = var.stateful_default_actions

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # AWS-managed stateful rule groups
    dynamic "stateful_rule_group_reference" {
      for_each = var.aws_managed_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.name
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Custom stateful rule groups
    dynamic "stateful_rule_group_reference" {
      for_each = var.custom_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }

  tags = each.value.tags

  lifecycle {
    create_before_destroy = true

    # Validate active version exists
    precondition {
      condition     = local.active_version_exists
      error_message = "Active policy version '${var.active_policy_version}' does not exist in policy_versions map. Available versions: ${join(", ", keys(var.policy_versions))}"
    }

    # Prevent removing active version when multiple versions exist
    precondition {
      condition = (
      each.key != var.active_policy_version ||
      length(local.policy_configs) == 1
      )
      error_message = "Cannot remove the active policy version '${each.key}' when multiple versions exist. Switch active_policy_version to another version first, then remove this one."
    }
  }
}

# ==============================================================================
# Manage Existing Firewall
# ==============================================================================
resource "aws_networkfirewall_firewall" "existing" {
  name    = var.network_firewall_name
  vpc_id  = var.vpc_id

  # Point to active policy version
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this[var.active_policy_version].arn

  # Mirror existing subnet mappings
  dynamic "subnet_mapping" {
    for_each = data.aws_networkfirewall_firewall.imported.subnet_mapping
    content {
      subnet_id = subnet_mapping.value.subnet_id
    }
  }

  tags = {
    Accelerator = "AWSAccelerator"
    Name        = var.network_firewall_name
  }

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [
    aws_networkfirewall_firewall_policy.this
  ]
}