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
  tenants = {
    fw-test-1 = {
      domains      = ["*.fw-test.np.example.gov.uk"]
      destinations = ["192.0.2.0/32"]
    }
  }
}

run "new_tenant_gets_certificate_but_no_configuration" {
  command = plan

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "One certificate should be requested per tenant"
  }

  assert {
    condition     = aws_acm_certificate.this["fw-test-1"].domain_name == "*.fw-test.np.example.gov.uk"
    error_message = "The first domain should be the certificate's primary name"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this) == 0
    error_message = "No configuration should be created until a tenant's certificate is validated"
  }
}

run "configuration_holds_only_validated_tenants" {
  command = plan

  variables {
    tenants = {
      fw-test-1 = {
        domains               = ["*.fw-test.np.example.gov.uk"]
        destinations          = ["192.0.2.0/32"]
        certificate_validated = true
      }
      fw-test-2 = {
        domains      = ["*.fw-test-2.np.example.gov.uk", "fw-test-2.np.example.gov.uk"]
        destinations = ["198.51.100.0/32"]
      }
    }
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 2
    error_message = "Every tenant should get a certificate, validated or not"
  }

  assert {
    condition     = aws_acm_certificate.this["fw-test-2"].subject_alternative_names == toset(["fw-test-2.np.example.gov.uk"])
    error_message = "Extra domains should become alternative names"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this) == 1
    error_message = "The configuration should be created once a tenant is validated"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this[0].tls_inspection_configuration[0].server_certificate_configuration[0].scope) == 1
    error_message = "Only the validated tenant's scope should be in the configuration"
  }

  assert {
    condition     = aws_networkfirewall_tls_inspection_configuration.this[0].name == "test-tls-inspection"
    error_message = "Configuration name should match the name variable"
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
    condition     = var.tenants["fw-test-1"].certificate_validated == false
    error_message = "certificate_validated should default to false"
  }
}

run "issued_certificate_is_accepted" {
  command = apply

  variables {
    tenants = {
      fw-test-1 = {
        domains               = ["*.fw-test.np.example.gov.uk"]
        destinations          = ["192.0.2.0/32"]
        certificate_validated = true
      }
    }
  }

  assert {
    condition     = output.certificate_status["fw-test-1"] == "ISSUED"
    error_message = "The certificate status should be reported"
  }

  assert {
    condition     = output.tls_inspection_configuration_arn != null
    error_message = "The configuration ARN should be output once the configuration exists"
  }
}

run "validated_but_not_issued_is_rejected" {
  command = apply

  # A new tenant key, so a fresh certificate is created with the overridden status.
  variables {
    tenants = {
      fw-test-pending = {
        domains               = ["*.fw-test-pending.np.example.gov.uk"]
        destinations          = ["192.0.2.0/32"]
        certificate_validated = true
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

run "rejects_no_tenants" {
  command = plan

  variables {
    tenants = {}
  }

  expect_failures = [
    var.tenants,
  ]
}

run "rejects_more_than_ten_tenants" {
  command = plan

  variables {
    tenants = { for i in range(11) : "t${i}" => {
      domains      = ["*.t${i}.np.example.gov.uk"]
      destinations = ["192.0.2.0/32"]
    } }
  }

  expect_failures = [
    var.tenants,
  ]
}

run "rejects_tenant_without_destinations" {
  command = plan

  variables {
    tenants = {
      acme = {
        domains      = ["*.acme.np.example.gov.uk"]
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
      acme = {
        domains      = ["*.acme.np.example.gov.uk"]
        destinations = ["192.0.2.0/32"]
        protocols    = [17]
      }
    }
  }

  expect_failures = [
    var.tenants,
  ]
}
