# ==============================================================================
# Build Rule Group Configurations
# ==============================================================================
locals {
  # Default primary version if rule_group_versions is empty
  default_versions = var.rule_group_versions != {} ? {} : {
    primary = {
      name_suffix         = ""
      description_suffix  = ""
      suricata_rules_path = var.suricata_rules
      tags                = {}
    }
  }

  # Merge default with user-provided versions
  all_versions = merge(local.default_versions, var.rule_group_versions)

  # Build final configuration for each rule group version
  rule_group_configs = {
    for version, config in local.all_versions : version => {
      name                = "${var.name}${config.name_suffix}"
      description         = "${var.description}${config.description_suffix}"
      suricata_rules_path = config.suricata_rules_path != "" ? config.suricata_rules_path : var.suricata_rules
      tags = merge(
        var.tags,
        config.tags,
        {
          Version = version
          Status  = var.active_rule_group_version == version ? "active" : "inactive"
        }
      )
    }
  }

  # Validate active version exists
  active_version_exists = contains(keys(local.all_versions), var.active_rule_group_version)
}

# ==============================================================================
# State Migration: Non-versioned → Versioned
# ==============================================================================
# TODO: Remove this block after all environments migrated
moved {
  from = aws_networkfirewall_rule_group.this
  to   = aws_networkfirewall_rule_group.this["primary"]
}

# ==============================================================================
# Create Stateful Rule Groups (Multiple Versions)
# ==============================================================================
resource "aws_networkfirewall_rule_group" "this" {
  for_each = local.rule_group_configs

  name        = each.value.name
  description = each.value.description
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

    dynamic "rule_variables" {
      for_each = length(var.rule_variables) > 0 ? [1] : []

      content {
        dynamic "ip_sets" {
          for_each = try(var.rule_variables.ipSets, {})
          content {
            key = ip_sets.value.key
            ip_set {
              definition = ip_sets.value.values
            }
          }
        }

        dynamic "port_sets" {
          for_each = try(var.rule_variables.portSets, {})
          content {
            key = port_sets.value.key
            port_set {
              definition = port_sets.value.values
            }
          }
        }
      }
    }

    rules_source {
      # Suricata ruleset - try file first, then use as string
      rules_string = try(file(each.value.suricata_rules_path), each.value.suricata_rules_path, null)

      dynamic "rules_source_list" {
        for_each = length(var.domain_targets) > 0 ? [1] : []
        content {
          generated_rules_type = try(var.domain_rule_type, null)
          target_types         = try(var.domain_target_type, [])
          targets              = try(var.domain_targets, [])
        }
      }

      dynamic "stateful_rule" {
        for_each = var.stateful_rules

        content {
          action = upper(stateful_rule.value.action)
          header {
            destination      = stateful_rule.value.destination
            destination_port = stateful_rule.value.destinationPort
            direction        = stateful_rule.value.direction
            protocol         = upper(stateful_rule.value.protocol)
            source           = stateful_rule.value.source
            source_port      = stateful_rule.value.sourcePort
          }
          rule_option {
            keyword  = "sid"
            settings = [try(stateful_rule.value.sid, substr(join("", regexall("[[:digit:]]", sha256(jsonencode(stateful_rule.value)))), 0, 8))]
          }

          dynamic "rule_option" {
            for_each = { for k, v in stateful_rule.value.ruleOptions : k => v if v.keyword != "sid" }
            content {
              keyword  = rule_option.value.keyword
              settings = try(rule_option.value.settings, null)
            }
          }
        }
      }
    }

    dynamic "stateful_rule_options" {
      for_each = length(var.stateful_rule_order) > 0 ? [1] : []
      content {
        rule_order = upper(var.stateful_rule_order)
      }
    }
  }

  tags = each.value.tags

  lifecycle {
    create_before_destroy = true

    # Validate active version exists
    precondition {
      condition     = local.active_version_exists
      error_message = "Active rule group version '${var.active_rule_group_version}' does not exist in rule_group_versions map. Available versions: ${join(", ", keys(local.all_versions))}"
    }

  }
}