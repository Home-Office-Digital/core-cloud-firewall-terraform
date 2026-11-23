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
# Server Certificates
# ==============================================================================
variable "certificate_domains" {
  description = <<-EOT
    Domains to request public ACM certificates for (DNS validated). One certificate
    is created per entry. A wildcard such as "*.app.tenant.core.example.gov.uk" covers
    exactly one extra label, so "<tenant>.app.tenant.core.example.gov.uk" but not
    "www.<tenant>.app.tenant.core.example.gov.uk".
  EOT
  type        = list(string)
  default     = []
}

variable "existing_server_certificate_arns" {
  description = "ARNs of issued ACM certificates that already exist and should also be used as server certificates"
  type        = list(string)
  default     = []
}

variable "validation_zone_id" {
  description = <<-EOT
    Route 53 public hosted zone ID in this account used to create the ACM DNS validation
    records. Leave null when the validation CNAMEs are created elsewhere; Terraform then
    waits for the certificate to be issued (see certificate_validation_timeout) and the
    required records are available in the certificate_validation_records output.
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
# Scope - which traffic is decrypted
# ==============================================================================
variable "scopes" {
  description = <<-EOT
    Traffic that the firewall decrypts and inspects. Only traffic matching a scope is
    affected, so use a destination that matches nothing (for example 192.0.2.0/32) until
    a tenant needs inspection. Network Firewall requires at least one scope.
  EOT
  type = list(object({
    name         = optional(string, "")
    sources      = optional(list(string), ["0.0.0.0/0"])
    destinations = list(string)
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
    condition     = length(var.scopes) > 0
    error_message = "At least one scope is required."
  }

  validation {
    condition     = alltrue([for s in var.scopes : length(s.destinations) > 0])
    error_message = "Every scope needs at least one destination CIDR."
  }

  validation {
    condition     = alltrue([for s in var.scopes : alltrue([for p in s.protocols : p == 6])])
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
