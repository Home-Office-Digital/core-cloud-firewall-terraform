# core-cloud-firewall-terraform

Terraform modules for managing AWS Network Firewall policies and rule groups for both inspection and perimeter use cases.

This repository is designed around managing an existing firewall (for example, one initially provisioned by LZA) and attaching versioned policies/rule groups so changes can be rolled out safely.

## Repository structure

### Policies

- `modules/network-firewall-policies/inspection`: Versioned inspection firewall policies with support for AWS-managed and custom rule groups.
- `modules/network-firewall-policies/perimeter`: Versioned perimeter firewall policies with active-version switching.

### Rule groups

- `modules/network-firewall-rulegroups/inspection/stateful`: Generic stateful rule group module (domain lists, standard stateful rules, Suricata rules).
- `modules/network-firewall-rulegroups/inspection/stateless`: Generic stateless rule group module.
- `modules/network-firewall-rulegroups/perimeter/stateful`: Versioned perimeter stateful rule group module for domain allowlists.

### Opinionated bundles

- `modules/network-firewall-rules-egress`: Egress-focused opinionated module that manages an existing firewall, policy, and allowlist rule group together.
- `modules/network-firewall-rules-inspection`: Inspection-focused opinionated module for attaching AWS-managed and custom stateful groups to an existing firewall.

## Key capabilities

- Versioned policy support using maps (for example, `primary`, `secondary`) and active-version selection.
- Versioned rule groups with per-version domain lists and tagging.
- Support for AWS-managed and custom stateful rule groups.
- Strict stateful rule ordering where configured.
- Support for taking ownership of existing firewalls using Terraform import blocks.
- Backward-compatible state migration using `moved` blocks in versioned modules.

## Compatibility

- Terraform: 1.5+ recommended (import blocks are used in modules).
- AWS provider: 5.x (see module-level version constraints where present).

## Example composition (perimeter)

The example below creates a versioned perimeter rule group and then references it from a versioned perimeter policy.

```hcl
module "perimeter_stateful_rulegroup" {
	source = "./modules/network-firewall-rulegroups/perimeter/stateful"

	name                 = "cc-perimeter-domain-allow"
	description          = "Perimeter domain allowlist"
	capacity             = 2000
	home_net_cidr_ranges = ["10.0.0.0/8"]

	rule_group_versions = {
		primary = {
			name_suffix         = ""
			description_suffix  = ""
			whitelisted_domains = ["example.com", "service.example.org"]
			tags                = {}
		}
		secondary = {
			name_suffix         = "-v2"
			description_suffix  = " (v2)"
			whitelisted_domains = ["example.com"]
			tags                = { rollout = "canary" }
		}
	}

	tags = {
		service = "network-firewall"
	}
}

module "perimeter_policy" {
	source = "./modules/network-firewall-policies/perimeter"

	network_firewall_name        = "existing-perimeter-firewall"
	network_firewall_policy_name = "perimeter-policy"
	vpc_id                       = "vpc-xxxxxxxx"
	account_id                   = "123456789012"

	active_policy_version = "primary"

	policy_versions = {
		primary = {
			name_suffix = ""
			description = "Primary perimeter firewall policy"
			custom_stateful_groups = [
				{
					resource_arn = module.perimeter_stateful_rulegroup.rule_group_arns["primary"]
					priority     = 250
				}
			]
			tags = {}
		}
	}

	tags = {
		service = "network-firewall"
	}
}
```

## Module documentation

- Stateful inspection rule group docs: `modules/network-firewall-rulegroups/inspection/stateful/README.md`
- Stateless inspection rule group docs: `modules/network-firewall-rulegroups/inspection/stateless/README.md`
- Inspection rule group package docs: `modules/network-firewall-rulegroups/inspection/README.md`
- Egress opinionated module docs: `modules/network-firewall-rules-egress/README.md`

## Development

Run formatting and validation before creating a pull request:

```bash
terraform fmt -recursive
```

Then validate each module from its directory, for example:

```bash
cd modules/network-firewall-policies/perimeter
terraform init
terraform validate
```
