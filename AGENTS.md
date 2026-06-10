# AGENTS.md

## Purpose

Guidance for coding agents working in this repository.

This repository contains Terraform modules for AWS Network Firewall policies and rule groups, including versioned rollout patterns for perimeter and inspection use cases.

## Repository Map

- Root docs: README.md, catalog-info.yaml
- Policy modules:
  - modules/network-firewall-policies/inspection
  - modules/network-firewall-policies/perimeter
- Rule group modules:
  - modules/network-firewall-rulegroups/inspection/stateful
  - modules/network-firewall-rulegroups/inspection/stateless
  - modules/network-firewall-rulegroups/perimeter/stateful
- Opinionated bundles:
  - modules/network-firewall-rules-egress
  - modules/network-firewall-rules-inspection

## Working Rules

1. Keep changes focused and minimal; avoid unrelated refactors.
2. Preserve existing variable names, output names, and module interfaces unless explicitly requested.
3. Treat existing firewall resources as externally provisioned unless the task explicitly says to create new firewalls.
4. Respect versioned patterns (policy_versions, rule_group_versions) and avoid introducing non-versioned regressions.
5. Keep comments concise and only where logic is non-obvious.

## Terraform Standards

1. Prefer explicit typing for variables and outputs.
2. Keep resource tags consistent with existing module behavior.
3. Use moved blocks when replacing non-versioned resources with versioned addresses.
4. Use lifecycle guards only when needed and consistent with existing modules.

## Validation Checklist

Run these from repository root after Terraform edits:

```bash
terraform fmt -recursive
```

For each changed module directory:

```bash
terraform init
terraform validate
```

If examples or README content is changed, verify it matches current variable and output names.

## Documentation Notes

- Some module READMEs include BEGIN_TF_DOCS / END_TF_DOCS blocks.
- Do not leave examples that reference non-existent outputs or variables.
- Keep root README aligned with actual module structure and behavior.

## Safety and Scope

- Make the smallest practical change for the request.
- Do not revert unrelated local changes.
- If you discover unexpected modifications while working, stop and ask the user before proceeding.

## Typical Task Flow

1. Identify impacted modules and docs.
2. Apply minimal code/doc changes.
3. Run terraform fmt -recursive.
4. Run terraform validate in affected module folders.
5. Summarize changed files and any residual risks.
