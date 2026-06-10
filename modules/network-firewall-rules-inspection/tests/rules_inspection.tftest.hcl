mock_provider "aws" {}

run "rules_inspection_plan_with_managed_and_custom" {
  command = plan

  plan_options {
    refresh = false
  }

  variables {
    enable_import                = false
    account_id                   = "123456789012"
    region                       = "eu-west-2"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy"
    vpc_id                       = "vpc-12345678"

    stateful_default_actions = ["aws:alert_established"]

    aws_managed_stateful_groups = [
      {
        name     = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsActionOrder"
        priority = 100
      }
    ]

    custom_stateful_groups = [
      {
        arn      = "arn:aws:network-firewall:eu-west-2:123456789012:stateful-rulegroup/custom-inspection-rg"
        priority = 250
      }
    ]
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
    condition     = aws_networkfirewall_firewall_policy.policy.name == "inspection-policy"
    error_message = "Firewall policy name should match input"
  }

  assert {
    condition     = contains(aws_networkfirewall_firewall_policy.policy.firewall_policy[0].stateful_default_actions, "aws:alert_established")
    error_message = "Policy should include aws:alert_established"
  }

  assert {
    condition     = contains(aws_networkfirewall_firewall_policy.policy.firewall_policy[0].stateless_default_actions, "aws:forward_to_sfe")
    error_message = "Stateless default actions should forward to SFE"
  }

  assert {
    condition     = aws_networkfirewall_firewall.existing.name == "existing-inspection-firewall"
    error_message = "Existing firewall name should match input"
  }
}

run "rules_inspection_plan_with_drop_and_alert" {
  command = plan

  plan_options {
    refresh = false
  }

  variables {
    enable_import                = false
    account_id                   = "123456789012"
    region                       = "eu-west-2"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy-drop"
    vpc_id                       = "vpc-12345678"

    stateful_default_actions = ["aws:drop_established", "aws:alert_established"]

    aws_managed_stateful_groups = []
    custom_stateful_groups      = []
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
    condition     = contains(aws_networkfirewall_firewall_policy.policy.firewall_policy[0].stateful_default_actions, "aws:drop_established")
    error_message = "Policy should include aws:drop_established"
  }

  assert {
    condition     = contains(aws_networkfirewall_firewall_policy.policy.firewall_policy[0].stateful_default_actions, "aws:alert_established")
    error_message = "Policy should include aws:alert_established"
  }

  assert {
    condition     = contains(aws_networkfirewall_firewall_policy.policy.firewall_policy[0].stateless_fragment_default_actions, "aws:forward_to_sfe")
    error_message = "Stateless fragment default actions should forward to SFE"
  }
}

run "rules_inspection_plan_invalid_stateful_default_actions" {
  command = plan

  variables {
    enable_import                = false
    account_id                   = "123456789012"
    region                       = "eu-west-2"
    network_firewall_name        = "existing-inspection-firewall"
    network_firewall_policy_name = "inspection-policy-invalid"
    vpc_id                       = "vpc-12345678"

    stateful_default_actions = ["aws:allow"]
  }

  expect_failures = [
    var.stateful_default_actions
  ]
}
