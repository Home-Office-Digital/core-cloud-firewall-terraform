# ==============================================================================
# Perimeter Network Firewall Rule Group - Domain Whitelist
# ==============================================================================

resource "aws_networkfirewall_rule_group" "this" {
  name        = var.name
  description = var.description
  type        = "STATEFUL"
  capacity    = var.capacity

  dynamic "encryption_configuration" {
    for_each = length(var.encryption_configuration) > 0 ? [var.encryption_configuration] : []
    content {
      key_id = try(encryption_configuration.value.key_id, null)
      type   = encryption_configuration.value.type
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
        for_each = length(var.whitelisted_domains) > 0 ? [1] : []
        content {
          generated_rules_type = "ALLOWLIST"
          target_types         = var.enabled_analysis_types
          targets              = var.whitelisted_domains
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

  tags = var.tags
}