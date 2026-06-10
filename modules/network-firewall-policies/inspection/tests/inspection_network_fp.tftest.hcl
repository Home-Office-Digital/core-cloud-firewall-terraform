mock_provider "aws" {}

run "inspection_policy_plan_primary" {
  command = plan

  variables {
    account_id                   = "123456789012"
    vpc_id                       = "vpc-12345678"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy"

    active_policy_version = "primary"

    policy_versions = {
      primary = {
        name_suffix             = ""
        description             = "Primary inspection firewall policy"
        tags                    = {}
        custom_stateful_groups  = []
        custom_stateless_groups = []
      }
    }
  }

  override_data {
    target = data.aws_networkfirewall_firewall.imported
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  assert {
    condition     = output.active_policy_version == "primary"
    error_message = "Active policy version should be primary"
  }

  assert {
    condition     = contains(output.available_versions, "primary")
    error_message = "Primary version should be present in available_versions"
  }

  assert {
    condition     = contains(keys(output.policy_names_by_version), "primary")
    error_message = "Primary key should be present in policy_names_by_version"
  }

  assert {
    condition     = output.active_policy_name == "inspection-policy"
    error_message = "Active policy name should match base policy name"
  }
}

run "inspection_policy_plan_secondary_with_groups" {
  command = plan

  variables {
    account_id                   = "123456789012"
    vpc_id                       = "vpc-12345678"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy"

    active_policy_version = "secondary"

    aws_managed_stateful_groups = [
      {
        name     = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsActionOrder"
        priority = 100
      }
    ]

    policy_versions = {
      primary = {
        name_suffix             = ""
        description             = "Primary inspection firewall policy"
        tags                    = {}
        custom_stateful_groups  = []
        custom_stateless_groups = []
      }
      secondary = {
        name_suffix = "-v2"
        description = "Secondary inspection firewall policy"
        tags        = {}
        custom_stateful_groups = [
          {
            arn      = "arn:aws:network-firewall:eu-west-2:123456789012:stateful-rulegroup/custom-inspection-rg"
            priority = 250
          }
        ]
        custom_stateless_groups = [
          {
            resource_arn = "arn:aws:network-firewall:eu-west-2:123456789012:stateless-rulegroup/custom-inspection-sl-rg"
            priority     = 10
          }
        ]
      }
    }
  }

  override_data {
    target = data.aws_networkfirewall_firewall.imported
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  assert {
    condition     = output.active_policy_version == "secondary"
    error_message = "Active policy version should be secondary"
  }

  assert {
    condition     = length(output.available_versions) == 2
    error_message = "Expected exactly two policy versions"
  }

  assert {
    condition     = contains(keys(output.policy_names_by_version), "secondary")
    error_message = "Secondary key should be present in policy_names_by_version"
  }
}

run "inspection_policy_plan_invalid_active_version" {
  command = plan

  variables {
    account_id                   = "123456789012"
    vpc_id                       = "vpc-12345678"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy"

    active_policy_version = "secondary"

    policy_versions = {
      primary = {
        name_suffix             = ""
        description             = "Primary inspection firewall policy"
        tags                    = {}
        custom_stateful_groups  = []
        custom_stateless_groups = []
      }
    }
  }

  override_data {
    target = data.aws_networkfirewall_firewall.imported
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  expect_failures = [
    aws_networkfirewall_firewall_policy.this
  ]
}
