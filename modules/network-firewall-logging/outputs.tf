output "firewall_arn" {
  description = "ARN of the firewall whose logging is managed."
  value       = aws_networkfirewall_logging_configuration.this.firewall_arn
}

output "log_types" {
  description = "Log types configured on the firewall."
  value       = sort(keys(var.log_destinations))
}
