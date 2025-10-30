# ==============================================================================
# Outputs - Perimeter Policy
# ==============================================================================

output "firewall_policy_arn" {
  description = "ARN of the firewall policy"
  value       = aws_networkfirewall_firewall_policy.policy.arn
}

output "firewall_policy_id" {
  description = "ID of the firewall policy"
  value       = aws_networkfirewall_firewall_policy.policy.id
}

output "firewall_policy_name" {
  description = "Name of the firewall policy"
  value       = aws_networkfirewall_firewall_policy.policy.name
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