# ==============================================================================
# Perimeter Network Firewall Rule Group - Domain Whitelist (Multi-Version)
# ==============================================================================

# ==============================================================================
# State Migration: Non-versioned → Versioned
# ==============================================================================
# Migrate existing single rule group to versioned rule groups
moved {
  from = aws_networkfirewall_rule_group.this
  to   = aws_networkfirewall_rule_group.this["primary"]
}

# ==============================================================================
# Create Rule Groups (Multiple Versions)
# ==============================================================================
resource "aws_networkfirewall_rule_group" "this" {
  for_each = var.rule_group_versions

  name        = "${var.name}${each.value.name_suffix}"
  description = "${var.description}${each.value.description_suffix}"
  type        = "STATEFUL"
  capacity    = var.capacity

  dynamic "encryption_configuration" {
    for_each = var.encryption_configuration != null ? [var.encryption_configuration] : []
    content {
      key_id = encryption_configuration.value["key_id"]
      type   = encryption_configuration.value["type"]
    }
  }

  rule_group {
    # Define HOME_NET variable for source traffic
    dynamic "rule_variables" {
      for_each = length(var.home_net_cidr_ranges) > 0 ? [1] : []
      content {
        ip_sets {
          key = "HOME_NET"
          ip_set {
            definition = var.home_net_cidr_ranges
          }
        }
      }
    }

    rules_source {
      # Domain-based allowlist for egress traffic
      dynamic "rules_source_list" {
        for_each = length(each.value.whitelisted_domains) > 0 ? [1] : []
        content {
          generated_rules_type = "ALLOWLIST"
          target_types         = var.enabled_analysis_types
          targets              = each.value.whitelisted_domains
        }
      }
    }

    # Rule ordering
    dynamic "stateful_rule_options" {
      for_each = length(var.stateful_rule_order) > 0 ? [1] : []
      content {
        rule_order = upper(var.stateful_rule_order)
      }
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Version = each.key
    }
  )
}