output "tls_inspection_configuration_arn" {
  description = "ARN of the TLS inspection configuration, passed to a firewall policy version"
  value       = aws_networkfirewall_tls_inspection_configuration.this.arn
}

output "server_certificate_arns" {
  description = "ARN of the server certificate for each tenant"
  value       = { for tenant, v in aws_acm_certificate_validation.this : tenant => v.certificate_arn }
}

output "certificate_validation_records" {
  description = "DNS validation records for each tenant's certificate. Create these where the zone is hosted when validation_zone_id is not set."
  value = {
    for tenant, cert in aws_acm_certificate.this : tenant => [
      for dvo in cert.domain_validation_options : {
        domain = dvo.domain_name
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        value  = dvo.resource_record_value
      }
    ]
  }
}
