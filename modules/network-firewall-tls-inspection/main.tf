# ==============================================================================
# Server certificates: one public ACM certificate per entry in var.certificates
# ==============================================================================
# Plain ACM resources are used here instead of core-cloud-acm-tf-module because every
# released tag of that module requires AWS provider ~> 6.66, while the firewall
# Terragrunt stack runs on provider 5.x. Switch to it once the stack moves to 6.x.
#
# The module only requests the certificates. Validation is done outside it: create the
# CNAMEs from the certificate_validation_records output, wait for ACM to show ISSUED, then
# set validated = true for the certificate. Nothing here waits for validation.
resource "aws_acm_certificate" "this" {
  for_each = var.certificates

  domain_name               = each.value.domains[0]
  subject_alternative_names = slice(each.value.domains, 1, length(each.value.domains))
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = each.key, Certificate = each.key })

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = length(local.unknown_certificate_refs) == 0
      error_message = "These tenants point at a certificate key that is not in certificates: ${join(", ", local.unknown_certificate_refs)}."
    }
  }
}

locals {
  # Tenants whose certificate key does not exist, reported by the precondition above.
  unknown_certificate_refs = [
    for k, t in var.tenants : "${k} -> ${t.certificate}" if !contains(keys(var.certificates), t.certificate)
  ]

  # Tenants whose certificate is validated. Only these become scopes.
  included_tenants = {
    for k, t in var.tenants : k => t
    if contains(keys(var.certificates), t.certificate) && try(var.certificates[t.certificate].validated, false)
  }

  # Certificates used by at least one included tenant. Only these go into the
  # configuration, so a validated certificate nobody uses yet (for example a replacement
  # being staged) does not take a slot.
  included_certificates = toset(distinct([for t in values(local.included_tenants) : t.certificate]))
}

# ==============================================================================
# TLS inspection configuration (inbound inspection)
# ==============================================================================
# Created once at least one tenant's certificate is validated. The AWS provider allows
# only ONE server_certificate_configuration block, so every included certificate and
# scope go into that single block. Certificates are chosen by the client's SNI.
resource "aws_networkfirewall_tls_inspection_configuration" "this" {
  count = length(local.included_tenants) > 0 ? 1 : 0

  name        = var.name
  description = var.description

  encryption_configuration {
    type   = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : "CUSTOMER_KMS"
    key_id = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : var.kms_key_arn
  }

  tls_inspection_configuration {
    server_certificate_configuration {
      dynamic "server_certificate" {
        for_each = local.included_certificates
        content {
          resource_arn = aws_acm_certificate.this[server_certificate.value].arn
        }
      }

      dynamic "scope" {
        for_each = local.included_tenants
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
      condition     = length(local.included_certificates) <= 10
      error_message = "Network Firewall allows at most 10 server certificates per TLS inspection configuration. ${length(local.included_certificates)} validated certificates are used by tenants. Put more tenants' names on fewer certificates."
    }

    # Also catches a certificate whose domains were edited while in use: the replacement is
    # created but not yet ISSUED, so the apply stops here and the configuration keeps the
    # old certificate. Validate the replacement, then apply again.
    precondition {
      condition     = alltrue([for c in local.included_certificates : aws_acm_certificate.this[c].status == "ISSUED"])
      error_message = "A certificate marked validated = true is not ISSUED yet: ${join(", ", [for c in local.included_certificates : c if aws_acm_certificate.this[c].status != "ISSUED"])}. Create its validation CNAMEs (see the certificate_validation_records output), wait for ACM to show ISSUED, then apply again. To change the names on a certificate in use, add a new certificate key instead, validate it, then move the tenants to it."
    }
  }
}
