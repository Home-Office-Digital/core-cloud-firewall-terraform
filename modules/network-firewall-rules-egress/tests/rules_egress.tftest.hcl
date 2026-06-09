mock_provider "aws" {}

run "rules_egress_plan_default_actions" {
  command = plan

  plan_options {
    refresh = false
  }

  variables {
    enable_import                    = false
    account_id                       = "123456789012"
    network_firewall_name            = "existing-egress-firewall"
    network_firewall_policy_name     = "egress-policy"
    network_firewall_rule_group_name = "egress-allowlist-rg"
    vpc_id                           = "vpc-12345678"

    home_net_cidr_ranges = ["10.0.0.0/8"]

    whitelisted_domains = <<EOT
example.com
example.org
EOT

    aws_managed_rule_groups = <<EOT
AbusedLegitBotNetCommandAndControlDomainsActionOrder
EOT

    enabled_analysis_types                = ["TLS_SNI", "HTTP_HOST"]
    enabled_drop_stateful_default_actions = false
  }

  override_data {
    target = data.aws_networkfirewall_firewall.existing_firewall
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  override_resource {
    target = aws_networkfirewall_firewall.existing_firewall
    values = {
      id   = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      arn  = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      name = "existing-egress-firewall"
    }
  }

  assert {
    condition     = output.firewall_policy.name == "egress-policy"
    error_message = "Firewall policy name should match the provided policy name"
  }

  assert {
    condition     = contains(output.firewall_policy.firewall_policy[0].stateful_default_actions, "aws:alert_established")
    error_message = "Default stateful actions should include aws:alert_established"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateful_default_actions) == 1 && contains(output.firewall_policy.firewall_policy[0].stateful_default_actions, "aws:alert_established")
    error_message = "Default stateful actions should contain only aws:alert_established when drop is disabled"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateless_default_actions) == 1 && contains(output.firewall_policy.firewall_policy[0].stateless_default_actions, "aws:forward_to_sfe")
    error_message = "Stateless default actions should forward to SFE"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateful_rule_group_reference) == 2
    error_message = "Expected one AWS-managed and one custom stateful rule group reference"
  }

}

run "rules_egress_plan_drop_enabled" {
  command = plan

  plan_options {
    refresh = false
  }

  variables {
    enable_import                    = false
    account_id                       = "123456789012"
    network_firewall_name            = "existing-egress-firewall"
    network_firewall_policy_name     = "egress-policy-drop"
    network_firewall_rule_group_name = "egress-allowlist-rg-drop"
    vpc_id                           = "vpc-12345678"

    home_net_cidr_ranges = ["10.0.0.0/8"]

    whitelisted_domains = <<EOT
example.com
EOT

    aws_managed_rule_groups = <<EOT
AbusedLegitBotNetCommandAndControlDomainsActionOrder
EOT

    enabled_analysis_types                = ["TLS_SNI"]
    enabled_drop_stateful_default_actions = true
  }

  override_data {
    target = data.aws_networkfirewall_firewall.existing_firewall
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  override_resource {
    target = aws_networkfirewall_firewall.existing_firewall
    values = {
      id   = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      arn  = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      name = "existing-egress-firewall"
    }
  }

  assert {
    condition     = output.firewall_policy.name == "egress-policy-drop"
    error_message = "Firewall policy name should match for drop-enabled scenario"
  }

  assert {
    condition     = contains(output.firewall_policy.firewall_policy[0].stateful_default_actions, "aws:drop_established")
    error_message = "Stateful default actions should include aws:drop_established when enabled"
  }

  assert {
    condition     = contains(output.firewall_policy.firewall_policy[0].stateful_default_actions, "aws:alert_established")
    error_message = "Stateful default actions should include aws:alert_established when drop is enabled"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateful_rule_group_reference) == 2
    error_message = "Expected one AWS-managed and one custom stateful rule group reference"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateless_fragment_default_actions) == 1 && contains(output.firewall_policy.firewall_policy[0].stateless_fragment_default_actions, "aws:forward_to_sfe")
    error_message = "Stateless fragment default actions should forward to SFE"
  }

}

run "rules_egress_plan_multiple_managed_groups" {
  command = plan

  plan_options {
    refresh = false
  }

  variables {
    enable_import                    = false
    account_id                       = "123456789012"
    network_firewall_name            = "existing-egress-firewall"
    network_firewall_policy_name     = "egress-policy-multi-managed"
    network_firewall_rule_group_name = "egress-allowlist-rg-multi"
    vpc_id                           = "vpc-12345678"

    home_net_cidr_ranges = ["10.0.0.0/8"]

    whitelisted_domains = <<EOT
example.com
example.org
EOT

    aws_managed_rule_groups = <<EOT
AbusedLegitBotNetCommandAndControlDomainsActionOrder
BotNetCommandAndControlDomainsActionOrder
EOT

    enabled_analysis_types                = ["TLS_SNI", "HTTP_HOST"]
    enabled_drop_stateful_default_actions = false
  }

  override_data {
    target = data.aws_networkfirewall_firewall.existing_firewall
    values = {
      subnet_mapping = [
        {
          subnet_id = "subnet-12345678"
        }
      ]
    }
  }

  override_resource {
    target = aws_networkfirewall_firewall.existing_firewall
    values = {
      id   = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      arn  = "arn:aws:network-firewall:eu-west-2:123456789012:firewall/existing-egress-firewall"
      name = "existing-egress-firewall"
    }
  }

  assert {
    condition     = output.firewall_policy.name == "egress-policy-multi-managed"
    error_message = "Firewall policy name should match for multi-managed scenario"
  }

  assert {
    condition     = length(output.firewall_policy.firewall_policy[0].stateful_rule_group_reference) == 3
    error_message = "Expected two AWS-managed and one custom stateful rule group reference"
  }
}
