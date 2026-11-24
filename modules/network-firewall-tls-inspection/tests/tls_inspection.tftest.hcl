mock_provider "aws" {
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn    = "arn:aws:acm:eu-west-2:123456789012:certificate/11111111-1111-1111-1111-111111111111"
      status = "ISSUED"
    }
  }
}

variables {
  name = "test-tls-inspection"
  certificates = {
    cert-1 = {
      domains = ["*.fw-test-1.np.example.gov.uk"]
    }
  }
  tenants = {
    fw-test-1 = {
      certificate  = "cert-1"
      destinations = ["192.0.2.0/32"]
    }
  }
}

run "unvalidated_certificate_creates_no_configuration" {
  command = plan

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "One certificate should be requested per certificate key"
  }

  assert {
    condition     = aws_acm_certificate.this["cert-1"].domain_name == "*.fw-test-1.np.example.gov.uk"
    error_message = "The first domain should be the certificate's primary name"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this) == 0
    error_message = "No configuration should be created until a certificate is validated"
  }
}

run "tenants_can_share_one_certificate" {
  command = plan

  variables {
    certificates = {
      batch-1 = {
        domains   = ["*.acme.np.example.gov.uk", "*.globex.np.example.gov.uk"]
        validated = true
      }
    }
    tenants = {
      acme = {
        certificate  = "batch-1"
        destinations = ["10.1.0.0/24"]
      }
      globex = {
        certificate  = "batch-1"
        destinations = ["10.2.0.0/24"]
      }
    }
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "Two tenants on one certificate should request one certificate"
  }

  assert {
    condition     = aws_acm_certificate.this["batch-1"].subject_alternative_names == toset(["*.globex.np.example.gov.uk"])
    error_message = "Further domains should become alternative names"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this[0].tls_inspection_configuration[0].server_certificate_configuration[0].server_certificate) == 1
    error_message = "A shared certificate should use one slot"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this[0].tls_inspection_configuration[0].server_certificate_configuration[0].scope) == 2
    error_message = "Each tenant should still get its own scope"
  }
}

run "only_tenants_on_validated_certificates_are_included" {
  command = plan

  variables {
    certificates = {
      cert-1 = {
        domains   = ["*.fw-test-1.np.example.gov.uk"]
        validated = true
      }
      cert-2 = {
        domains = ["*.fw-test-2.np.example.gov.uk"]
      }
    }
    tenants = {
      fw-test-1 = {
        certificate  = "cert-1"
        destinations = ["192.0.2.0/32"]
      }
      fw-test-2 = {
        certificate  = "cert-2"
        destinations = ["198.51.100.0/32"]
      }
    }
  }

  assert {
    condition     = output.tenants_in_configuration == { fw-test-1 = "cert-1" }
    error_message = "Only the tenant on the validated certificate should be included"
  }
}

run "staged_replacement_takes_no_slot" {
  command = plan

  variables {
    certificates = {
      cert-1 = {
        domains   = ["*.fw-test-1.np.example.gov.uk"]
        validated = true
      }
      cert-1-v2 = {
        domains   = ["*.fw-test-1.np.example.gov.uk", "*.new.np.example.gov.uk"]
        validated = true
      }
    }
    tenants = {
      fw-test-1 = {
        certificate  = "cert-1"
        destinations = ["192.0.2.0/32"]
      }
    }
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 2
    error_message = "The staged replacement should be requested"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this[0].tls_inspection_configuration[0].server_certificate_configuration[0].server_certificate) == 1
    error_message = "A validated certificate no tenant uses should not be in the configuration"
  }
}

run "scope_defaults_to_tcp_443_from_anywhere" {
  command = plan

  assert {
    condition     = var.tenants["fw-test-1"].protocols == tolist([6]) && var.tenants["fw-test-1"].destination_ports[0].from_port == 443 && var.tenants["fw-test-1"].destination_ports[0].to_port == 443
    error_message = "Scope should default to TCP port 443"
  }

  assert {
    condition     = var.tenants["fw-test-1"].sources == tolist(["0.0.0.0/0"])
    error_message = "Scope source should default to any address"
  }

  assert {
    condition     = var.certificates["cert-1"].validated == false
    error_message = "validated should default to false"
  }
}

run "rejects_unknown_certificate_key" {
  command = plan

  variables {
    tenants = {
      fw-test-1 = {
        certificate  = "no-such-cert"
        destinations = ["192.0.2.0/32"]
      }
    }
  }

  expect_failures = [
    aws_acm_certificate.this,
  ]
}

run "rejects_more_than_ten_certificates_in_use" {
  command = plan

  variables {
    certificates = { for i in range(11) : "c${i}" => {
      domains   = ["*.t${i}.np.example.gov.uk"]
      validated = true
    } }
    tenants = { for i in range(11) : "t${i}" => {
      certificate  = "c${i}"
      destinations = ["192.0.2.0/32"]
    } }
  }

  expect_failures = [
    aws_networkfirewall_tls_inspection_configuration.this,
  ]
}

run "issued_certificate_is_accepted" {
  command = apply

  variables {
    certificates = {
      cert-1 = {
        domains   = ["*.fw-test-1.np.example.gov.uk"]
        validated = true
      }
    }
  }

  assert {
    condition     = output.certificate_status["cert-1"] == "ISSUED"
    error_message = "The certificate status should be reported"
  }

  assert {
    condition     = output.tls_inspection_configuration_arn != null
    error_message = "The configuration ARN should be output once the configuration exists"
  }
}

run "validated_but_not_issued_is_rejected" {
  command = apply

  # A new certificate key, so a fresh certificate is created with the overridden status.
  variables {
    certificates = {
      cert-pending = {
        domains   = ["*.fw-test-pending.np.example.gov.uk"]
        validated = true
      }
    }
    tenants = {
      fw-test-pending = {
        certificate  = "cert-pending"
        destinations = ["192.0.2.0/32"]
      }
    }
  }

  # Keyless target: OpenTofu does not accept instance keys here. It applies to every instance.
  override_resource {
    target = aws_acm_certificate.this
    values = {
      arn    = "arn:aws:acm:eu-west-2:123456789012:certificate/22222222-2222-2222-2222-222222222222"
      status = "PENDING_VALIDATION"
    }
  }

  expect_failures = [
    aws_networkfirewall_tls_inspection_configuration.this,
  ]
}

run "rejects_no_certificates" {
  command = plan

  variables {
    certificates = {}
  }

  expect_failures = [
    var.certificates,
  ]
}

run "rejects_certificate_without_domains" {
  command = plan

  variables {
    certificates = {
      cert-1 = {
        domains = []
      }
    }
  }

  expect_failures = [
    var.certificates,
  ]
}

run "rejects_tenant_without_destinations" {
  command = plan

  variables {
    tenants = {
      fw-test-1 = {
        certificate  = "cert-1"
        destinations = []
      }
    }
  }

  expect_failures = [
    var.tenants,
  ]
}

run "rejects_non_tcp_protocol" {
  command = plan

  variables {
    tenants = {
      fw-test-1 = {
        certificate  = "cert-1"
        destinations = ["192.0.2.0/32"]
        protocols    = [17]
      }
    }
  }

  expect_failures = [
    var.tenants,
  ]
}
