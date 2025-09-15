resource "aws_networkfirewall_rule_group" "this" {
  name        = var.name
  description = var.description
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
          for_each = var.custom_actions

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
          for_each = var.stateless_rules

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
  tags = var.tags
}
