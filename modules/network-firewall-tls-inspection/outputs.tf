output "tls_inspection_configuration_arn" {
  description = "ARN of the TLS inspection configuration, passed to a firewall policy version. Null until at least one tenant's certificate is validated."
  value       = one(aws_networkfirewall_tls_inspection_configuration.this[*].arn)
}

output "certificate_arns" {
  description = "ARN of each certificate, by certificate key"
  value       = { for k, cert in aws_acm_certificate.this : k => cert.arn }
}

output "certificate_status" {
  description = "ACM status of each certificate (PENDING_VALIDATION until its CNAMEs are in place, then ISSUED)"
  value       = { for k, cert in aws_acm_certificate.this : k => cert.status }
}

output "certificate_validation_records" {
  description = "DNS validation CNAMEs for each certificate. Create these in the public zone for each name, then set validated = true once the certificate is ISSUED."
  value = {
    for k, cert in aws_acm_certificate.this : k => [
      for dvo in cert.domain_validation_options : {
        domain = dvo.domain_name
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        value  = dvo.resource_record_value
      }
    ]
  }
}

output "tenants_in_configuration" {
  description = "Tenants whose scope is in the configuration, with the certificate serving them"
  value       = { for k, t in local.included_tenants : k => t.certificate }
}
