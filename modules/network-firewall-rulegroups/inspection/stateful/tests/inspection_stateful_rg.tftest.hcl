mock_provider "aws" {}

run "stateful_rulegroup_plan_primary" {
  command = plan

  variables {
    name        = "inspection-stateful-rg"
    description = "Inspection stateful rule group"
    capacity    = 100

    active_rule_group_version = "primary"

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = ""
        tags                = {}
      }
    }

    domain_targets = ["example.com"]
  }

  assert {
    condition     = output.active_version == "primary"
    error_message = "Active version should be primary"
  }

  assert {
    condition     = output.type == "STATEFUL"
    error_message = "Rule group type should be STATEFUL"
  }

  assert {
    condition     = contains(output.available_versions, "primary")
    error_message = "Primary version should be available"
  }
}

run "stateful_rulegroup_plan_secondary" {
  command = plan

  variables {
    name        = "inspection-stateful-rg"
    description = "Inspection stateful rule group"
    capacity    = 100

    active_rule_group_version = "secondary"

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = ""
        tags                = {}
      }
      secondary = {
        name_suffix         = "-v2"
        description_suffix  = " v2"
        suricata_rules_path = ""
        tags                = {}
      }
    }

    domain_targets = ["example.com"]
  }

  assert {
    condition     = output.active_version == "secondary"
    error_message = "Active version should be secondary"
  }

  assert {
    condition     = contains(output.available_versions, "secondary")
    error_message = "Secondary version should be available"
  }

  assert {
    condition     = length(output.available_versions) == 2
    error_message = "Expected exactly two rule group versions"
  }
}

run "stateful_rulegroup_plan_with_rule_variables" {
  command = plan

  variables {
    name        = "inspection-stateful-rg-vars"
    description = "Inspection stateful rule group with variables"
    capacity    = 100

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = ""
        tags                = {}
      }
    }

    rule_variables = {
      ipSets = {
        HOME = {
          key    = "HOME_NET"
          values = ["10.0.0.0/8"]
        }
      }
      portSets = {
        WEB = {
          key    = "WEB_PORTS"
          values = ["443"]
        }
      }
    }

    stateful_rules = {
      rule1 = {
        sid             = 123456
        action          = "PASS"
        source          = "10.0.0.0/8"
        sourcePort      = "ANY"
        destination     = "0.0.0.0/0"
        destinationPort = "ANY"
        protocol        = "TCP"
        direction       = "ANY"
        ruleOptions     = {}
      }
    }
  }

  assert {
    condition     = output.type == "STATEFUL"
    error_message = "Rule group type should remain STATEFUL"
  }

  assert {
    condition     = contains(output.available_versions, "primary")
    error_message = "Primary version should be available"
  }
}

run "stateful_rulegroup_plan_invalid_active_version" {
  command = plan

  variables {
    name        = "inspection-stateful-rg"
    description = "Inspection stateful rule group"
    capacity    = 100

    active_rule_group_version = "missing"

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = ""
        tags                = {}
      }
    }

    domain_targets = ["example.com"]
  }

  expect_failures = [
    aws_networkfirewall_rule_group.this
  ]
}
