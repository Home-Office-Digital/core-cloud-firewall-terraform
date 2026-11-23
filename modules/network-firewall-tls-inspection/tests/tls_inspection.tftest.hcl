mock_provider "aws" {
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:eu-west-2:123456789012:certificate/11111111-1111-1111-1111-111111111111"
      domain_validation_options = [
        {
          domain_name           = "*.app.tenant.np.example.gov.uk"
          resource_record_name  = "_abc.app.tenant.np.example.gov.uk."
          resource_record_type  = "CNAME"
          resource_record_value = "_def.acm-validations.aws."
        }
      ]
    }
  }
}

variables {
  name = "test-tls-inspection"
  scopes = [
    {
      name         = "placeholder"
      destinations = ["192.0.2.0/32"]
    }
  ]
}

run "placeholder_scope_with_existing_certificate" {
  command = plan

  variables {
    existing_server_certificate_arns = ["arn:aws:acm:eu-west-2:123456789012:certificate/22222222-2222-2222-2222-222222222222"]
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 0
    error_message = "No certificate should be requested when only existing ARNs are supplied"
  }

  assert {
    condition     = length(local.server_certificate_arns) == 1
    error_message = "The existing certificate should be used as the server certificate"
  }

  assert {
    condition     = aws_networkfirewall_tls_inspection_configuration.this.name == "test-tls-inspection"
    error_message = "Configuration name should match the name variable"
  }
}

run "scope_defaults_to_tcp_443_from_anywhere" {
  command = plan

  variables {
    existing_server_certificate_arns = ["arn:aws:acm:eu-west-2:123456789012:certificate/22222222-2222-2222-2222-222222222222"]
  }

  assert {
    condition     = var.scopes[0].protocols == tolist([6]) && var.scopes[0].destination_ports[0].from_port == 443 && var.scopes[0].destination_ports[0].to_port == 443
    error_message = "Scope should default to TCP port 443"
  }

  assert {
    condition     = var.scopes[0].sources == tolist(["0.0.0.0/0"])
    error_message = "Scope source should default to any address"
  }
}

run "certificate_requested_without_dns_zone" {
  command = plan

  variables {
    certificate_domains = ["*.app.tenant.np.example.gov.uk"]
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "One certificate should be requested per domain"
  }

  assert {
    condition     = length(aws_route53_record.validation) == 0
    error_message = "No Route 53 records should be created when validation_zone_id is null"
  }
}

run "validation_records_created_with_zone" {
  command = plan

  variables {
    certificate_domains = ["*.app.tenant.np.example.gov.uk"]
    validation_zone_id  = "Z0123456789ABCDEFGHIJ"
  }

  assert {
    condition     = length(aws_route53_record.validation) == 1
    error_message = "A validation record should be created when validation_zone_id is set"
  }
}

run "rejects_no_certificate" {
  command = plan

  expect_failures = [
    aws_networkfirewall_tls_inspection_configuration.this,
  ]
}

run "rejects_empty_scope_list" {
  command = plan

  variables {
    existing_server_certificate_arns = ["arn:aws:acm:eu-west-2:123456789012:certificate/22222222-2222-2222-2222-222222222222"]
    scopes                           = []
  }

  expect_failures = [
    var.scopes,
  ]
}

run "rejects_non_tcp_protocol" {
  command = plan

  variables {
    existing_server_certificate_arns = ["arn:aws:acm:eu-west-2:123456789012:certificate/22222222-2222-2222-2222-222222222222"]
    scopes = [
      {
        destinations = ["192.0.2.0/32"]
        protocols    = [17]
      }
    ]
  }

  expect_failures = [
    var.scopes,
  ]
}
