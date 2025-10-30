# ==============================================================================
# Outputs - Perimeter Rule Group
# ==============================================================================

output "rule_group_arn" {
  description = "ARN of the created rule group"
  value       = aws_networkfirewall_rule_group.this.arn
}

output "rule_group_id" {
  description = "ID of the created rule group"
  value       = aws_networkfirewall_rule_group.this.id
}

output "rule_group_name" {
  description = "Name of the created rule group"
  value       = aws_networkfirewall_rule_group.this.name
}

output "rule_group_update_token" {
  description = "Update token for the rule group"
  value       = aws_networkfirewall_rule_group.this.update_token
}