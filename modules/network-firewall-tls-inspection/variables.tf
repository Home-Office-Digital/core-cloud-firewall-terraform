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
# Tenants - one public ACM certificate and one scope each
# ==============================================================================
variable "tenants" {
  description = <<-EOT
    Tenants whose traffic can be decrypted, keyed by tenant key. Each tenant gets its own
    public ACM certificate, requested with DNS validation. The module does not create the
    validation records or wait for them: create the CNAMEs from the
    certificate_validation_records output, then set certificate_validated = true.

    One certificate per tenant is enough: the firewall terminates the client's TLS with it,
    inspects, then opens its own TLS connection to the server.

    - domains: names for the certificate. The first is the primary name and any others are
      added as alternative names. A wildcard such as "*.acme.core.example.gov.uk" covers
      exactly one extra label ("app1.acme.core.example.gov.uk") but not two.
    - destinations: the tenant's server CIDRs. Only traffic to these is decrypted. Use a
      range that matches nothing (192.0.2.0/32) for a tenant that is set up but not live.
    - certificate_validated: set to true once ACM shows the certificate as ISSUED. Only
      tenants with true are put in the TLS inspection configuration, and the configuration
      is only created once at least one tenant is true. A tenant set to true whose
      certificate is not ISSUED fails the plan or apply.
    - sources, source_ports, destination_ports, protocols: narrow the scope. By default any
      source and source port, destination port 443, TCP.

    All included tenants' certificates and scopes sit in the one server certificate
    configuration the AWS provider allows, so AWS picks a certificate by the client's SNI
    and does not tie it to a particular tenant's scope.

    Network Firewall allows at most 10 server certificates per configuration, so at most
    10 tenants.
  EOT
  type = map(object({
    domains               = list(string)
    destinations          = list(string)
    certificate_validated = optional(bool, false)
    sources               = optional(list(string), ["0.0.0.0/0"])
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
    condition     = length(var.tenants) <= 10
    error_message = "Network Firewall allows at most 10 server certificates per TLS inspection configuration, so at most 10 tenants."
  }

  validation {
    condition     = alltrue([for t in values(var.tenants) : length(t.domains) > 0])
    error_message = "Every tenant needs at least one certificate domain."
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
