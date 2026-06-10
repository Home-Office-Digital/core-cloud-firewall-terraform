mock_provider "aws" {}

run "stateless_rulegroup_plan_primary" {
  command = plan

  variables {
    name        = "inspection-stateless-rg"
    description = "Inspection stateless rule group"
    capacity    = 100

    active_rule_group_version = "primary"

    rule_group_versions = {
      primary = {
        name_suffix        = ""
        description_suffix = ""
        stateless_rules = {
          allow_https = {
            priority         = 1
            action           = ["aws:pass"]
            source           = ["10.0.0.0/24"]
            sourcePorts      = []
            destination      = ["0.0.0.0/0"]
            destinationPorts = []
            protocols        = [6]
          }
        }
        custom_actions = {}
        tags           = {}
      }
    }
  }

  assert {
    condition     = output.active_version == "primary"
    error_message = "Active version should be primary"
  }

  assert {
    condition     = output.type == "STATELESS"
    error_message = "Rule group type should be STATELESS"
  }

  assert {
    condition     = contains(output.available_versions, "primary")
    error_message = "Primary version should be available"
  }
}

run "stateless_rulegroup_plan_secondary" {
  command = plan

  variables {
    name        = "inspection-stateless-rg"
    description = "Inspection stateless rule group"
    capacity    = 100

    active_rule_group_version = "secondary"

    rule_group_versions = {
      primary = {
        name_suffix        = ""
        description_suffix = ""
        stateless_rules = {
          allow_https = {
            priority         = 1
            action           = ["aws:pass"]
            source           = ["10.0.0.0/24"]
            sourcePorts      = []
            destination      = ["0.0.0.0/0"]
            destinationPorts = []
            protocols        = [6]
          }
        }
        custom_actions = {}
        tags           = {}
      }
      secondary = {
        name_suffix        = "-v2"
        description_suffix = " v2"
        stateless_rules = {
          allow_dns = {
            priority         = 2
            action           = ["aws:pass"]
            source           = ["10.0.0.0/24"]
            sourcePorts      = []
            destination      = ["0.0.0.0/0"]
            destinationPorts = []
            protocols        = [17]
          }
        }
        custom_actions = {}
        tags           = {}
      }
    }
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

run "stateless_rulegroup_plan_with_tcp_flags" {
  command = plan

  variables {
    name        = "inspection-stateless-rg-tcp"
    description = "Inspection stateless rule group tcp flags"
    capacity    = 100

    rule_group_versions = {
      primary = {
        name_suffix        = ""
        description_suffix = ""
        stateless_rules = {
          tcp_syn_only = {
            priority         = 20
            action           = ["aws:pass"]
            source           = ["10.0.0.0/24"]
            sourcePorts      = []
            destination      = ["0.0.0.0/0"]
            destinationPorts = []
            protocols        = [6]
            tcp = {
              flags = ["SYN"]
              masks = ["SYN", "ACK"]
            }
          }
        }
        custom_actions = {}
        tags           = {}
      }
    }
  }

  assert {
    condition     = output.type == "STATELESS"
    error_message = "Rule group type should remain STATELESS"
  }

  assert {
    condition     = contains(output.available_versions, "primary")
    error_message = "Primary version should be available"
  }
}

run "stateless_rulegroup_plan_invalid_active_version" {
  command = plan

  variables {
    name        = "inspection-stateless-rg"
    description = "Inspection stateless rule group"
    capacity    = 100

    active_rule_group_version = "missing"

    rule_group_versions = {
      primary = {
        name_suffix        = ""
        description_suffix = ""
        stateless_rules = {
          allow_https = {
            priority         = 1
            action           = ["aws:pass"]
            source           = ["10.0.0.0/24"]
            sourcePorts      = []
            destination      = ["0.0.0.0/0"]
            destinationPorts = []
            protocols        = [6]
          }
        }
        custom_actions = {}
        tags           = {}
      }
    }
  }

  expect_failures = [
    aws_networkfirewall_rule_group.this
  ]
}
