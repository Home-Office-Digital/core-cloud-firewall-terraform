# ==============================================================================
# Active Rule Group Outputs
# ==============================================================================
output "arn" {
  description = "ARN of the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].arn
}

output "id" {
  description = "ID of the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].id
}

output "update_token" {
  description = "Update token for the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].update_token
}

output "name" {
  description = "Name of the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].name
}

output "active_version" {
  description = "Which rule group version is currently active"
  value       = var.active_rule_group_version
}

output "capacity" {
  description = "Capacity of the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].capacity
}

output "rule_group_status" {
  description = "Status of the active rule group"
  value       = aws_networkfirewall_rule_group.this[var.active_rule_group_version].rule_group_status
}

# ==============================================================================
# All Rule Groups Outputs
# ==============================================================================
output "all_rule_groups" {
  description = "Map of all created rule group versions"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this : version => {
      arn          = rg.arn
      id           = rg.id
      name         = rg.name
      update_token = rg.update_token
      capacity     = rg.capacity
      tags         = rg.tags
    }
  }
}

output "rule_group_arns_by_version" {
  description = "Map of rule group ARNs by version"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this : version => rg.arn
  }
}

output "rule_group_names_by_version" {
  description = "Map of rule group names by version"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this : version => rg.name
  }
}

output "available_versions" {
  description = "List of all available rule group versions"
  value       = keys(aws_networkfirewall_rule_group.this)
}