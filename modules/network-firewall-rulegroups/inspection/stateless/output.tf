output "aws_networkfirewall_rule_group_arn" {
  description = "The arn of the network firewall rulegroup that is created"
  value       = aws_networkfirewall_rule_group.this.arn
}