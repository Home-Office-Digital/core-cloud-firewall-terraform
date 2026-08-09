# ==============================================================================
# Perimeter Network Firewall Policy (with Versioning)
# ==============================================================================

# Read the existing firewall (created by LZA)
data "aws_networkfirewall_firewall" "imported" {
  name = var.network_firewall_name
}

# ==============================================================================
# State Migration: Non-versioned → Versioned
# ==============================================================================
# Migrate existing single policy to versioned policies
moved {
  from = aws_networkfirewall_firewall_policy.policy
  to   = aws_networkfirewall_firewall_policy.this["primary"]
}

# ==============================================================================
# Create Firewall Policies (Multiple Versions)
# ==============================================================================
resource "aws_networkfirewall_firewall_policy" "this" {
  for_each = var.policy_versions

  name        = "${var.network_firewall_policy_name}${each.value.name_suffix}"
  description = each.value.description

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

    # Custom stateful rule groups (with version-specific ARNs)
    dynamic "stateful_rule_group_reference" {
      for_each = each.value.custom_stateful_groups
      content {
        resource_arn = stateful_rule_group_reference.value.resource_arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Stateless configuration
    stateless_default_actions          = var.stateless_default_actions
    stateless_fragment_default_actions = var.stateless_fragment_default_actions
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Version = each.key
    }
  )
}

# ==============================================================================
# Manage Firewall Association
# ==============================================================================
resource "aws_networkfirewall_firewall" "existing" {
  name                = var.network_firewall_name
  vpc_id              = var.vpc_id
  delete_protection   = true
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this[var.active_policy_version].arn

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