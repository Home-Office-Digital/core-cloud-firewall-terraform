# ==============================================================================
# Server certificates (public ACM, DNS validated)
# ==============================================================================
# Plain ACM resources are used here instead of core-cloud-acm-tf-module because every
# released tag of that module requires AWS provider ~> 6.66, while the firewall
# Terragrunt stack runs on provider 5.x. Switch to it once the stack moves to 6.x.
resource "aws_acm_certificate" "this" {
  for_each = toset(var.certificate_domains)

  domain_name       = each.value
  validation_method = "DNS"

  tags = merge(var.tags, { Name = each.value })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # One validation record per certificate, keyed by the requested domain so the
  # keys are known at plan time. Each certificate covers a single domain, so it
  # has exactly one validation option.
  validation_records = var.validation_zone_id == null ? {} : {
    for domain, cert in aws_acm_certificate.this : domain => tolist(cert.domain_validation_options)[0]
  }
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

# Waits until the certificate is ISSUED. Without validation_zone_id the DNS records
# are created outside this module and Terraform polls until they are in place.
resource "aws_acm_certificate_validation" "this" {
  for_each = aws_acm_certificate.this

  certificate_arn         = each.value.arn
  validation_record_fqdns = var.validation_zone_id == null ? null : [aws_route53_record.validation[each.key].fqdn]

  timeouts {
    create = var.certificate_validation_timeout
  }
}

locals {
  server_certificate_arns = distinct(concat(
    [for v in aws_acm_certificate_validation.this : v.certificate_arn],
    var.existing_server_certificate_arns
  ))
}

# ==============================================================================
# TLS inspection configuration (inbound inspection)
# ==============================================================================
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
        for_each = local.server_certificate_arns
        content {
          resource_arn = server_certificate.value
        }
      }

      dynamic "scope" {
        for_each = var.scopes
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

  lifecycle {
    precondition {
      condition     = length(local.server_certificate_arns) > 0
      error_message = "Provide at least one certificate through certificate_domains or existing_server_certificate_arns."
    }
    precondition {
      condition     = length(local.server_certificate_arns) <= 10
      error_message = "Network Firewall allows at most 10 server certificates per TLS inspection configuration."
    }
  }
}
