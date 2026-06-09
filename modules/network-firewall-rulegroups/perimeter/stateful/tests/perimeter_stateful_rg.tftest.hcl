mock_provider "aws" {}

run "perimeter_stateful_rulegroup_plan_primary" {
  command = plan

  variables {
    name                 = "perimeter-stateful-rg"
    description          = "Perimeter stateful rule group"
    capacity             = 100
    home_net_cidr_ranges = ["10.0.0.0/8"]

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        whitelisted_domains = ["example.com"]
        tags                = {}
      }
    }
  }

  assert {
    condition     = contains(keys(output.rule_group_names), "primary")
    error_message = "Primary version should be present in rule_group_names"
  }

  assert {
    condition     = output.rule_group_names["primary"] == "perimeter-stateful-rg"
    error_message = "Primary rule group name should match base name"
  }

  assert {
    condition     = output.domain_counts["primary"] == 1
    error_message = "Primary version should have one whitelisted domain"
  }
}

run "perimeter_stateful_rulegroup_plan_secondary" {
  command = plan

  variables {
    name                 = "perimeter-stateful-rg"
    description          = "Perimeter stateful rule group"
    capacity             = 100
    home_net_cidr_ranges = ["10.0.0.0/8"]

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        whitelisted_domains = ["example.com"]
        tags                = {}
      }
      secondary = {
        name_suffix         = "-v2"
        description_suffix  = " v2"
        whitelisted_domains = ["example.com", "example.org"]
        tags                = {}
      }
    }
  }

  assert {
    condition     = contains(keys(output.rule_group_names), "secondary")
    error_message = "Secondary version should be present in rule_group_names"
  }

  assert {
    condition     = output.rule_group_names["secondary"] == "perimeter-stateful-rg-v2"
    error_message = "Secondary rule group name should include version suffix"
  }

  assert {
    condition     = output.domain_counts["secondary"] == 2
    error_message = "Secondary version should have two whitelisted domains"
  }
}

run "perimeter_stateful_rulegroup_plan_with_encryption" {
  command = plan

  variables {
    name                 = "perimeter-stateful-rg-kms"
    description          = "Perimeter stateful rule group with encryption"
    capacity             = 100
    home_net_cidr_ranges = ["10.0.0.0/8"]

    encryption_configuration = {
      key_id = "alias/aws/network-firewall"
      type   = "AWS_OWNED_KMS_KEY"
    }

    rule_group_versions = {
      primary = {
        name_suffix         = ""
        description_suffix  = ""
        whitelisted_domains = []
        tags                = {}
      }
    }
  }

  assert {
    condition     = contains(keys(output.rule_group_arns), "primary")
    error_message = "Primary version ARN should be present when encryption is set"
  }

  assert {
    condition     = output.domain_counts["primary"] == 0
    error_message = "Primary version should have zero domains in this scenario"
  }
}
