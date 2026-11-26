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

# Default rule_variables (both sets empty) must not emit an empty rule_variables
# block: AWS does not store one, so it would show as a perpetual diff.
run "stateful_rulegroup_plan_no_rule_variables" {
  command = plan

  variables {
    name        = "inspection-stateful-rg-novars"
    description = "Inspection stateful rule group without variables"
    capacity    = 100

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = "alert tcp any any -> any 21 (msg:\"test\"; sid:1; rev:1;)"
        tags                = {}
      }
    }
  }

  assert {
    condition     = length(aws_networkfirewall_rule_group.this["primary"].rule_group[0].rule_variables) == 0
    error_message = "No rule_variables block should be emitted when no IP or port sets are given"
  }
}

# Explicitly empty sets behave the same as the default.
run "stateful_rulegroup_plan_empty_rule_variables" {
  command = plan

  variables {
    name        = "inspection-stateful-rg-emptyvars"
    description = "Inspection stateful rule group with empty variables"
    capacity    = 100

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        suricata_rules_path = "alert tcp any any -> any 21 (msg:\"test\"; sid:1; rev:1;)"
        tags                = {}
      }
    }

    rule_variables = {
      ipSets   = {}
      portSets = {}
    }
  }

  assert {
    condition     = length(aws_networkfirewall_rule_group.this["primary"].rule_group[0].rule_variables) == 0
    error_message = "No rule_variables block should be emitted for empty IP and port sets"
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
    condition     = length(aws_networkfirewall_rule_group.this["primary"].rule_group[0].rule_variables) == 1
    error_message = "A rule_variables block should be emitted when IP or port sets are given"
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
