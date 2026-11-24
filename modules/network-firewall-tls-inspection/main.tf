# ==============================================================================
# Server certificates: one public ACM certificate per tenant, DNS validated
# ==============================================================================
# Plain ACM resources are used here instead of core-cloud-acm-tf-module because every
# released tag of that module requires AWS provider ~> 6.66, while the firewall
# Terragrunt stack runs on provider 5.x. Switch to it once the stack moves to 6.x.
resource "aws_acm_certificate" "this" {
  for_each = var.tenants

  domain_name               = each.value.domains[0]
  subject_alternative_names = slice(each.value.domains, 1, length(each.value.domains))
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = each.key, Tenant = each.key })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # One validation record per requested domain, keyed by tenant and domain so the keys are
  # known at plan time. A wildcard and its apex share one CNAME, so both keys resolve to the
  # same record, which allow_overwrite handles.
  validation_records = var.validation_zone_id == null ? {} : merge([
    for tenant, cert in aws_acm_certificate.this : {
      for domain in var.tenants[tenant].domains :
      "${tenant}|${domain}" => one([for o in cert.domain_validation_options : o if o.domain_name == domain])
    }
  ]...)
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_records

  zone_id         = var.validation_zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# Waits until each certificate is ISSUED. Without validation_zone_id the DNS records are
# created outside this module and Terraform polls until they are in place.
resource "aws_acm_certificate_validation" "this" {
  for_each = aws_acm_certificate.this

  certificate_arn = each.value.arn
  validation_record_fqdns = var.validation_zone_id == null ? null : [
    for domain in var.tenants[each.key].domains : aws_route53_record.validation["${each.key}|${domain}"].fqdn
  ]

  timeouts {
    create = var.certificate_validation_timeout
  }
}

# ==============================================================================
# TLS inspection configuration (inbound inspection)
# ==============================================================================
# The AWS provider allows only ONE server_certificate_configuration block, so every
# tenant's certificate and every tenant's scope go into that single block. Certificates
# are chosen by the client's SNI, and a certificate is not tied to a tenant's scope by AWS.
resource "aws_networkfirewall_tls_inspection_configuration" "this" {
  name        = var.name
  description = var.description

  encryption_configuration {
    type   = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : "CUSTOMER_KMS"
    key_id = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : var.kms_key_arn
  }

  tls_inspection_configuration {
    server_certificate_configuration {
      dynamic "server_certificate" {
        for_each = aws_acm_certificate_validation.this
        content {
          resource_arn = server_certificate.value.certificate_arn
        }
      }

      dynamic "scope" {
        for_each = var.tenants
        content {
          protocols = scope.value.protocols

          dynamic "source" {
            for_each = scope.value.sources
            content {
              address_definition = source.value
            }
          }

          dynamic "destination" {
            for_each = scope.value.destinations
            content {
              address_definition = destination.value
            }
          }

          dynamic "source_ports" {
            for_each = scope.value.source_ports
            content {
              from_port = source_ports.value.from_port
              to_port   = source_ports.value.to_port
            }
          }

          dynamic "destination_ports" {
            for_each = scope.value.destination_ports
            content {
              from_port = destination_ports.value.from_port
              to_port   = destination_ports.value.to_port
            }
          }
        }
      }
    }
  }

  tags = var.tags
}
