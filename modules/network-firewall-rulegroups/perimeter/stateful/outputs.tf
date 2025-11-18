# ==============================================================================
# Outputs - Perimeter Rule Group (with Versioning)
# ==============================================================================

output "rule_group_arns" {
  description = "ARNs of all rule group versions"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this :
    version => rg.arn
  }
}

output "rule_group_ids" {
  description = "IDs of all rule group versions"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this :
    version => rg.id
  }
}

output "rule_group_names" {
  description = "Names of all rule group versions"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this :
    version => rg.name
  }
}

output "rule_group_update_tokens" {
  description = "Update tokens for all rule group versions"
  value = {
    for version, rg in aws_networkfirewall_rule_group.this :
    version => rg.update_token
  }
}

output "domain_counts" {
  description = "Number of domains in each rule group version"
  value = {
    for version, config in var.rule_group_versions :
    version => length(config.whitelisted_domains)
  }
}