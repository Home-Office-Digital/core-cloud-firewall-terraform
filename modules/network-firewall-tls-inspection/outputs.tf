output "tls_inspection_configuration_arn" {
  description = "ARN of the TLS inspection configuration, passed to a firewall policy version. Null until at least one tenant has certificate_validated = true."
  value       = one(aws_networkfirewall_tls_inspection_configuration.this[*].arn)
}

output "server_certificate_arns" {
  description = "ARN of each tenant's ACM certificate"
  value       = { for tenant, cert in aws_acm_certificate.this : tenant => cert.arn }
}

output "certificate_status" {
  description = "ACM status of each tenant's certificate (PENDING_VALIDATION until its CNAME is in place, then ISSUED)"
  value       = { for tenant, cert in aws_acm_certificate.this : tenant => cert.status }
}

output "certificate_validation_records" {
  description = "DNS validation CNAMEs for each tenant's certificate. Create these in the tenant's public zone, then set certificate_validated = true once the certificate is ISSUED."
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
