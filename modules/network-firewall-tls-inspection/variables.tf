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
# Tenants - one public ACM certificate and one certificate/scope group each
# ==============================================================================
variable "tenants" {
  description = <<-EOT
    Tenants whose traffic can be decrypted, keyed by tenant key. Each tenant gets its own
    public ACM certificate (DNS validated) and its own scope. All certificates and scopes
    sit in the one server certificate configuration the AWS provider allows, so AWS picks
    a certificate by the client's SNI and does not tie it to a particular tenant's scope.

    - domains: names for the certificate. The first is the primary name and any others are
      added as alternative names. A wildcard such as "*.acme.core.example.gov.uk" covers
      exactly one extra label ("app1.acme.core.example.gov.uk") but not two.
    - destinations: the tenant's server CIDRs. Only traffic to these is decrypted. Use a
      range that matches nothing (192.0.2.0/32) for a tenant that is set up but not live.
    - sources, source_ports, destination_ports, protocols: narrow the scope. By default any
      source and source port, destination port 443, TCP.

    Network Firewall allows at most 10 server certificates per configuration, so at most
    10 tenants.
  EOT
  type = map(object({
    domains      = list(string)
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
    error_message = "At least one tenant is required, because a TLS inspection configuration needs a server certificate."
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
# DNS validation
# ==============================================================================
variable "validation_zone_id" {
  description = <<-EOT
    Route 53 public hosted zone ID in this account used to create the ACM DNS validation
    records. Leave null when the validation CNAMEs are created elsewhere (for example in a
    central DNS account); Terraform then waits for each certificate to be issued (see
    certificate_validation_timeout) and the records to create are in the
    certificate_validation_records output.
  EOT
  type        = string
  default     = null
}

variable "certificate_validation_timeout" {
  description = "How long to wait for each ACM certificate to be issued"
  type        = string
  default     = "30m"
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
