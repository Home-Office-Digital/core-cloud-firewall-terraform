---
homepage: true
layout: sub-navigation
title: Core Cloud Firewall
order: 1
---

Description: Platform-managed AWS Network Firewall and WAF — East-West inspection, egress filtering, and web application protection.

## Documentation

[Product documentation](./product.md)

## Network Firewall

- [AWS Network Firewall Baseline](./firewall/aws-network-firewall-baseline.md)
- [Central Egress Firewall Policy](./firewall/central-egress-firewall-policy.md)
- [Central Inspection Firewall Policy](./firewall/central-inspection-firewall-policy.md)
- [Core Cloud Detailed Inspection](./firewall/corecloud-detailed-inspection.md)

## WAF

- [Default WAF Rules](./firewall/default-waf-rules.md)
- [AWS WAF Classic](./firewall/aws-waf-classic.md)
- [KDD-015: Web Application Firewalls](./firewall/kdd-015-web-application-firewalls.md)

## Design Decisions

- [KDD-009: Firewall Egress Allow List Management](./firewall/kdd-009-firewall-egress-allow-list-management.md)

## Runbooks

- [Network-0004: Make Changes to a Firewall Rule](./firewall/network-0004-make-changes-to-a-firewall-rule.md)
- [Network-0005: Using AWS Athena to Review Firewall Alerts](./firewall/network-0005-using-aws-athena-to-review-network-firewall-alerts.md)
- [Reviewing Network Firewall Alert Logs Using AWS Athena](./firewall/reviewing-network-firewall-alert-logs-using-aws-athena.md)

## Observability

- [Dynatrace AWS Network Firewall Metrics Collection](./firewall/dynatrace-aws-network-firewall-metrics-collection.md)

## Testing

- [Network Firewall Testing](./firewall/network-firewall-testing.md)
- [Network Firewall Refactor Test Plan (NotProd)](./firewall/network-firewall-refactor-test-plan-for-notprod.md)
- [Network Firewall Refactor Prod Test Plan (NotProd)](./firewall/network-firewall-refactor-prod-test-plan-for-notprod.md)
- [Automated Network Firewall Testing with Synthetic Canaries](./firewall/automated-network-firewall-testing-with-synthetic-cloudwatch-canaries.md)
