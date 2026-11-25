# ==============================================================================
# TLS Inspection Configuration (inbound / server certificate mode)
# ==============================================================================
variable "name" {
  description = "Name of the TLS inspection configuration"
  type        = string
}

variable "description" {
  description = "Description of the TLS inspection configuration"
  type        = string
  default     = "TLS inspection configuration"
}

# ==============================================================================
# Certificates - one public ACM certificate per entry
# ==============================================================================
variable "certificates" {
  description = <<-EOT
    ACM certificates to request, keyed by certificate key. Each entry is one certificate,
    which uses one of the 10 server certificate slots in the configuration once a tenant
    uses it. The module requests each certificate with DNS validation and does not create
    the records or wait: create the CNAMEs from the certificate_validation_records output,
    then set validated = true once ACM shows the certificate as ISSUED.

    - domains: every name on the certificate. The first is the primary name and the rest
      are alternative names. A wildcard covers exactly one extra label. ACM allows 10 names
      per certificate by default, up to 100 with a raised quota. Changing the names replaces
      the certificate, so to change a certificate in use add a new key with the new names,
      validate it, move the tenants to it, then remove the old key.
    - validated: true once the certificate is ISSUED. Only validated certificates, and the
      tenants that use them, go into the configuration.
  EOT
  type = map(object({
    domains   = list(string)
    validated = optional(bool, false)
  }))

  validation {
    condition     = length(var.certificates) > 0
    error_message = "At least one certificate is required."
  }

  validation {
    condition     = alltrue([for c in values(var.certificates) : length(c.domains) > 0 && length(c.domains) <= 100])
    error_message = "Every certificate needs between 1 and 100 domains (ACM allows 10 by default, up to 100 with a raised quota)."
  }
}

# ==============================================================================
# Tenants - one scope each, served by one of the certificates
# ==============================================================================
variable "tenants" {
  description = <<-EOT
    Tenants whose traffic can be decrypted, keyed by tenant key. Each tenant becomes one
    scope in the configuration once its certificate is validated.

    - certificate: key in `certificates` whose names cover this tenant's hostnames. Several
      tenants can share a certificate.
    - destinations: the tenant's server CIDRs. Only traffic to these is decrypted.
    - sources, source_ports, destination_ports, protocols: narrow the scope. By default any
      source and source port, destination port 443, TCP.

    All included tenants' certificates and scopes sit in the one server certificate
    configuration the AWS provider allows, so AWS picks a certificate by the client's SNI
    and does not tie it to a particular tenant's scope.
  EOT
  type = map(object({
    certificate  = string
    destinations = list(string)
    sources      = optional(list(string), ["0.0.0.0/0"])
    source_ports = optional(list(object({
      from_port = number
      to_port   = number
    })), [{ from_port = 0, to_port = 65535 }])
    destination_ports = optional(list(object({
      from_port = number
      to_port   = number
    })), [{ from_port = 443, to_port = 443 }])
    protocols = optional(list(number), [6])
  }))

  validation {
    condition     = length(var.tenants) > 0
    error_message = "At least one tenant is required."
  }

  validation {
    condition     = alltrue([for t in values(var.tenants) : length(t.destinations) > 0])
    error_message = "Every tenant needs at least one destination CIDR."
  }

  validation {
    condition     = alltrue([for t in values(var.tenants) : alltrue([for p in t.protocols : p == 6])])
    error_message = "Network Firewall only supports TCP (protocol 6) for TLS inspection."
  }
}

# ==============================================================================
# Encryption and tags
# ==============================================================================
variable "kms_key_arn" {
  description = "Customer managed KMS key ARN used to encrypt the configuration. Null uses an AWS owned key."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the certificates and the TLS inspection configuration"
  type        = map(string)
  default     = {}
}
