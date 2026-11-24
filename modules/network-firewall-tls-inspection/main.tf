# ==============================================================================
# Server certificates: one public ACM certificate per tenant, DNS validated
# ==============================================================================
# Plain ACM resources are used here instead of core-cloud-acm-tf-module because every
# released tag of that module requires AWS provider ~> 6.66, while the firewall
# Terragrunt stack runs on provider 5.x. Switch to it once the stack moves to 6.x.
#
# The module only requests the certificates. Validation is done outside it: create the
# CNAMEs from the certificate_validation_records output, wait for ACM to show ISSUED, then
# set certificate_validated = true for the tenant. Nothing here waits for validation.
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
  # Tenants whose certificate has been validated. Only these go into the configuration.
  validated_tenants = { for k, v in var.tenants : k => v if v.certificate_validated }
}

# ==============================================================================
# TLS inspection configuration (inbound inspection)
# ==============================================================================
# Created once at least one tenant is validated. The AWS provider allows only ONE
# server_certificate_configuration block, so every validated tenant's certificate and
# scope go into that single block. Certificates are chosen by the client's SNI, and a
# certificate is not tied to a tenant's scope by AWS.
resource "aws_networkfirewall_tls_inspection_configuration" "this" {
  count = length(local.validated_tenants) > 0 ? 1 : 0

  name        = var.name
  description = var.description

  encryption_configuration {
    type   = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : "CUSTOMER_KMS"
    key_id = var.kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : var.kms_key_arn
  }

  tls_inspection_configuration {
    server_certificate_configuration {
      dynamic "server_certificate" {
        for_each = local.validated_tenants
        content {
          resource_arn = aws_acm_certificate.this[server_certificate.key].arn
        }
      }

      dynamic "scope" {
        for_each = local.validated_tenants
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
      condition     = alltrue([for k in keys(local.validated_tenants) : aws_acm_certificate.this[k].status == "ISSUED"])
      error_message = "A tenant has certificate_validated = true but its ACM certificate is not ISSUED yet. Create its validation CNAME (see the certificate_validation_records output), wait for ACM to show ISSUED, then apply again. Not yet issued: ${join(", ", [for k in keys(local.validated_tenants) : k if aws_acm_certificate.this[k].status != "ISSUED"])}."
    }
  }
}
