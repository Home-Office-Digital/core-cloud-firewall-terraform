# ==============================================================================
# Build Rule Group Configurations
# ==============================================================================
locals {
  # Default primary version if rule_group_versions is empty
  default_versions = var.rule_group_versions != {} ? {} : {
    primary = {
      name_suffix        = ""
      description_suffix = ""
      stateless_rules    = var.stateless_rules
      custom_actions     = var.custom_actions
      tags               = {}
    }
  }

  # Merge default with user-provided versions
  all_versions = merge(local.default_versions, var.rule_group_versions)

  # Build final configuration for each rule group version
  rule_group_configs = {
    for version, config in local.all_versions : version => {
      name            = "${var.name}${config.name_suffix}"
      description     = "${var.description}${config.description_suffix}"
      stateless_rules = config.stateless_rules != null ? config.stateless_rules : var.stateless_rules
      custom_actions  = try(config.custom_actions, var.custom_actions, {})
      tags = merge(
        var.tags,
        try(config.tags, {}),
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
# Create Stateless Rule Groups (Multiple Versions)
# ==============================================================================
resource "aws_networkfirewall_rule_group" "this" {
  for_each = local.rule_group_configs

  name        = each.value.name
  description = each.value.description
  type        = "STATELESS"
  capacity    = var.capacity

  dynamic "encryption_configuration" {
    for_each = length(var.encryption_configuration) > 0 ? [var.encryption_configuration] : []

    content {
      key_id = try(encryption_configuration.value.key_id, null)
      type   = encryption_configuration.value.type
    }
  }

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        dynamic "custom_action" {
          for_each = each.value.custom_actions

          content {
            action_name = custom_action.key

            action_definition {
              publish_metric_action {
                dynamic "dimension" {
                  for_each = toset(custom_action.value.dimensions)
                  content {
                    value = dimension.key
                  }
                }
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = each.value.stateless_rules

          content {
            priority = stateless_rule.value.priority
            rule_definition {
              actions = stateless_rule.value.action
              match_attributes {
                dynamic "source" {
                  for_each = length(try(toset(stateless_rule.value.source), {})) > 0 ? toset(stateless_rule.value.source) : []
                  content {
                    address_definition = try(source.key, null)
                  }
                }

                dynamic "source_port" {
                  for_each = length(try(stateless_rule.value.sourcePorts, {})) > 0 ? stateless_rule.value.sourcePorts : []
                  content {
                    from_port = try(source_port.value.from, null)
                    to_port   = try(source_port.value.to, null)
                  }
                }

                dynamic "destination" {
                  for_each = length(try(toset(stateless_rule.value.destination), {})) > 0 ? toset(stateless_rule.value.destination) : []
                  content {
                    address_definition = try(destination.key, null)
                  }
                }

                dynamic "destination_port" {
                  for_each = length(try(stateless_rule.value.destinationPorts, {})) > 0 ? stateless_rule.value.destinationPorts : []
                  content {
                    from_port = try(destination_port.value.from, null)
                    to_port   = try(destination_port.value.to, null)
                  }
                }

                protocols = try(stateless_rule.value.protocols, null)

                dynamic "tcp_flag" {
                  for_each = length(try(stateless_rule.value.tcp, {})) > 0 ? [1] : []
                  content {
                    flags = try(stateless_rule.value.tcp.flags, [])
                    masks = try(stateless_rule.value.tcp.masks, [])
                  }
                }
              }
            }
          }
        }
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

    # Prevent removing active version when multiple versions exist
    precondition {
      condition = (
      each.key != var.active_rule_group_version ||
      length(local.rule_group_configs) == 1
      )
      error_message = "Cannot remove the active rule group version '${each.key}' when multiple versions exist. Switch active_rule_group_version to another version first, then remove this one."
    }
  }
}