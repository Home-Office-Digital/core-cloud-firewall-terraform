# ==============================================================================
# Network Firewall logging configuration
# ==============================================================================
# A firewall has exactly ONE logging configuration holding every destination
# (ALERT, FLOW, TLS). This resource owns that whole set: list every log type the
# firewall should keep, not only the one being added.
#
# Importing an existing configuration (for example one created by LZA) and
# adding a log type is a single in-place update. Any destination that does not
# match AWS exactly is removed and re-added, so check the plan shows only the
# intended additions.
resource "aws_networkfirewall_logging_configuration" "this" {
  firewall_arn = var.firewall_arn

  logging_configuration {
    dynamic "log_destination_config" {
      for_each = var.log_destinations
      content {
        log_type             = log_destination_config.key
        log_destination_type = log_destination_config.value.destination_type
        log_destination      = log_destination_config.value.destination
      }
    }
  }

  lifecycle {
    # Destroying this resource removes EVERY destination in it, including ones
    # another tool (LZA) created. Remove it from state instead
    # (terraform state rm) if Terraform should stop managing logging.
    prevent_destroy = true
  }
}
