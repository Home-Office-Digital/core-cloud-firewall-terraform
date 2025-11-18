# ==============================================================================
# Outputs - Perimeter Policy (with Versioning)
# ==============================================================================

output "firewall_policy_arns" {
  description = "ARNs of all firewall policy versions"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this :
    version => policy.arn
  }
}

output "active_firewall_policy_arn" {
  description = "ARN of the currently active firewall policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].arn
}

output "active_firewall_policy_name" {
  description = "Name of the currently active firewall policy"
  value       = aws_networkfirewall_firewall_policy.this[var.active_policy_version].name
}

output "active_policy_version" {
  description = "Currently active policy version"
  value       = var.active_policy_version
}

output "firewall_policy_ids" {
  description = "IDs of all firewall policy versions"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this :
    version => policy.id
  }
}

output "firewall_policy_names" {
  description = "Names of all firewall policy versions"
  value = {
    for version, policy in aws_networkfirewall_firewall_policy.this :
    version => policy.name
  }
}

output "firewall_arn" {
  description = "ARN of the firewall"
  value       = aws_networkfirewall_firewall.existing.arn
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = aws_networkfirewall_firewall.existing.id
}

output "firewall_status" {
  description = "Status of the firewall"
  value       = aws_networkfirewall_firewall.existing.firewall_status
}