# ==============================================================================
# Firewall Outputs
# ==============================================================================
output "firewall_arn" {
  description = "ARN of the Network Firewall"
  value       = aws_networkfirewall_firewall.existing.arn
}

output "firewall_id" {
  description = "ID of the Network Firewall"
  value       = aws_networkfirewall_firewall.existing.id
}

output "firewall_name" {
  description = "Name of the Network Firewall"
  value       = aws_networkfirewall_firewall.existing.name
}

# ==============================================================================
# Active Policy Outputs
# ==============================================================================
output "active_policy_arn" {
  description = "ARN of the currently active policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].arn
}

output "active_policy_id" {
  description = "ID of the currently active policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].id
}

output "active_policy_name" {
  description = "Name of the currently active policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].name
}

output "active_policy_version" {
  description = "Which policy version is currently active"
  value       = var.active_policy_version
}

output "active_policy_update_token" {
  description = "Update token of the currently active policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].update_token
}

# ==============================================================================
# All Policies Outputs
# ==============================================================================
output "all_policies" {
  description = "Map of all created policy versions"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this : version => {
      arn          = policy.arn
      id           = policy.id
      name         = policy.name
      update_token = policy.update_token
      tags         = policy.tags
    }
  }
}

output "policy_arns_by_version" {
  description = "Map of policy ARNs by version"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this : version => policy.arn
  }
}

output "policy_names_by_version" {
  description = "Map of policy names by version"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this : version => policy.name
  }
}

output "available_versions" {
  description = "List of all available policy versions"
  value       = keys(aws_networkfirewall_firewall_policy.this)
}