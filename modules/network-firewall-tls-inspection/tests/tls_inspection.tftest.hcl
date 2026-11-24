mock_provider "aws" {
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:eu-west-2:123456789012:certificate/11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  name = "test-tls-inspection"
  tenants = {
    fw-test = {
      domains      = ["*.fw-test.np.example.gov.uk"]
      destinations = ["192.0.2.0/32"]
    }
  }
}

run "placeholder_tenant_one_certificate_and_group" {
  command = plan

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "One certificate should be requested per tenant"
  }

  assert {
    condition     = aws_acm_certificate.this["fw-test"].domain_name == "*.fw-test.np.example.gov.uk"
    error_message = "The first domain should be the certificate's primary name"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this.tls_inspection_configuration[0].server_certificate_configuration) == 1
    error_message = "The provider allows exactly one server certificate configuration"
  }

  assert {
    condition     = aws_networkfirewall_tls_inspection_configuration.this.name == "test-tls-inspection"
    error_message = "Configuration name should match the name variable"
  }
}

run "two_tenants_get_separate_certificates_and_scopes" {
  command = plan

  variables {
    tenants = {
      fw-test = {
        domains      = ["*.fw-test.np.example.gov.uk"]
        destinations = ["192.0.2.0/32"]
      }
      acme = {
        domains      = ["*.acme.np.example.gov.uk", "acme.np.example.gov.uk"]
        destinations = ["10.1.0.0/24", "10.1.1.5/32"]
      }
    }
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 2
    error_message = "Each tenant should get its own certificate"
  }

  assert {
    condition     = aws_acm_certificate.this["acme"].subject_alternative_names == toset(["acme.np.example.gov.uk"])
    error_message = "Extra domains should become alternative names"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this.tls_inspection_configuration[0].server_certificate_configuration[0].server_certificate) == 2
    error_message = "Both tenants' certificates should be in the configuration"
  }

  assert {
    condition     = length(aws_networkfirewall_tls_inspection_configuration.this.tls_inspection_configuration[0].server_certificate_configuration[0].scope) == 2
    error_message = "Each tenant should have its own scope"
  }
}

run "scope_defaults_to_tcp_443_from_anywhere" {
  command = plan

  assert {
    condition     = var.tenants["fw-test"].protocols == tolist([6]) && var.tenants["fw-test"].destination_ports[0].from_port == 443 && var.tenants["fw-test"].destination_ports[0].to_port == 443
    error_message = "Scope should default to TCP port 443"
  }

  assert {
    condition     = var.tenants["fw-test"].sources == tolist(["0.0.0.0/0"])
    error_message = "Scope source should default to any address"
  }
}

run "no_dns_records_without_zone" {
  command = plan

  assert {
    condition     = length(aws_route53_record.validation) == 0
    error_message = "No Route 53 records should be created when validation_zone_id is null"
  }
}

run "dns_records_created_with_zone" {
  command = plan

  variables {
    validation_zone_id = "Z0123456789ABCDEFGHIJ"
  }

  assert {
    condition     = length(aws_route53_record.validation) == 1
    error_message = "A validation record should be created per tenant domain when validation_zone_id is set"
  }
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
