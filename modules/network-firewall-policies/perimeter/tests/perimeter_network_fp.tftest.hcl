mock_provider "aws" {}

run "perimeter_policy_plan_primary" {
  command = plan

  variables {
    network_firewall_name        = "existing-perimeter-firewall"
    network_firewall_policy_name = "perimeter-policy"
    vpc_id                       = "vpc-12345678"
    account_id                   = "123456789012"

    active_policy_version = "primary"

    policy_versions = {
      primary = {
        name_suffix            = ""
        description            = "Primary perimeter firewall policy"
        custom_stateful_groups = []
        tags                   = {}
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
    condition     = contains(keys(output.firewall_policy_names), "primary")
    error_message = "Primary key should be present in firewall_policy_names"
  }

  assert {
    condition     = output.active_firewall_policy_name == "perimeter-policy"
    error_message = "Active policy name should match base policy name"
  }
}

run "perimeter_policy_plan_secondary" {
  command = plan

  variables {
    network_firewall_name        = "existing-perimeter-firewall"
    network_firewall_policy_name = "perimeter-policy"
    vpc_id                       = "vpc-12345678"
    account_id                   = "123456789012"

    active_policy_version = "secondary"

    policy_versions = {
      primary = {
        name_suffix            = ""
        description            = "Primary perimeter firewall policy"
        custom_stateful_groups = []
        tags                   = {}
      }
      secondary = {
        name_suffix            = "-v2"
        description            = "Secondary perimeter firewall policy"
        custom_stateful_groups = []
        tags                   = {}
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
    condition     = contains(keys(output.firewall_policy_names), "secondary")
    error_message = "Secondary key should be present in firewall_policy_names"
  }

  assert {
    condition     = output.active_firewall_policy_name == "perimeter-policy-v2"
    error_message = "Secondary policy name should include the version suffix"
  }
}

run "perimeter_policy_plan_with_managed_and_custom_groups" {
  command = plan

  variables {
    network_firewall_name        = "existing-perimeter-firewall"
    network_firewall_policy_name = "perimeter-policy"
    vpc_id                       = "vpc-12345678"
    account_id                   = "123456789012"

    active_policy_version = "primary"

    aws_managed_stateful_groups = [
      {
        resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsActionOrder"
        priority     = 100
      }
    ]

    policy_versions = {
      primary = {
        name_suffix = ""
        description = "Primary perimeter firewall policy"
        custom_stateful_groups = [
          {
            resource_arn = "arn:aws:network-firewall:eu-west-2:123456789012:stateful-rulegroup/custom-perimeter-rg"
            priority     = 250
          }
        ]
        tags = {}
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
    error_message = "Active policy version should remain primary"
  }

  assert {
    condition     = contains(keys(output.firewall_policy_arns), "primary")
    error_message = "Primary key should be present in firewall_policy_arns"
  }
}
