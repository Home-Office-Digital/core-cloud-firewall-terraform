output "tls_inspection_configuration_arn" {
  description = "ARN of the TLS inspection configuration, passed to the firewall policy module"
  value       = aws_networkfirewall_tls_inspection_configuration.this.arn
}

output "server_certificate_arns" {
  description = "ARNs of every server certificate used by the configuration"
  value       = local.server_certificate_arns
}

output "certificate_validation_records" {
  description = "DNS validation records for each requested certificate domain. Create these where the zone is hosted when validation_zone_id is not set."
  value = {
    for domain, cert in aws_acm_certificate.this : domain => [
      for dvo in cert.domain_validation_options : {
        name  = dvo.resource_record_name
        type  = dvo.resource_record_type
        value = dvo.resource_record_value
      }
    ]
  }
}
