---
homepage: true
layout: sub-navigation
title: Core Cloud Firewall
order: 1
---

Description: Platform-managed AWS Network Firewall and WAF — East-West inspection, egress filtering, and web application protection.

| | |
|---|---|
| **Team** | Andromeda |
| **Key Stakeholders** | |
| **Senior Responsible Owner** | |

## Architecture

- [AWS Network Firewall Baseline](./architecture/aws-network-firewall-baseline/)
- [Central Egress Firewall Policy](./architecture/central-egress-firewall-policy/)
- [Central Inspection Firewall Policy](./architecture/central-inspection-firewall-policy/)
- [Core Cloud Detailed Inspection](./architecture/corecloud-detailed-inspection/)
- [Default WAF Rules](./architecture/default-waf-rules/)
- [AWS WAF Classic](./architecture/aws-waf-classic/)
- [Web Application Firewalls](./architecture/web-application-firewalls/)
- [KDD-015: Web Application Firewalls](./architecture/kdd-015-web-application-firewalls/)

## Decision Log

- [KDD-009: Firewall Egress Allow List Management](./decision-log/kdd-009-firewall-egress-allow-list-management/)

## Runbooks

- [Network-0004: Make Changes to a Firewall Rule](./runbooks/network-0004-make-changes-to-a-firewall-rule/)
- [Network-0005: Using AWS Athena to Review Firewall Alerts](./runbooks/network-0005-using-aws-athena-to-review-network-firewall-alerts/)
- [Reviewing Network Firewall Alert Logs Using AWS Athena](./runbooks/reviewing-network-firewall-alert-logs-using-aws-athena/)

## Backups

## Disaster Recovery

## Observability

- [Dynatrace AWS Network Firewall Metrics Collection](./observability/dynatrace-aws-network-firewall-metrics-collection/)

## Testing

- [Network Firewall Testing](./testing/network-firewall-testing/)
- [Network Firewall Refactor Test Plan (NotProd)](./testing/network-firewall-refactor-test-plan-for-notprod/)
- [Network Firewall Refactor Prod Test Plan (NotProd)](./testing/network-firewall-refactor-prod-test-plan-for-notprod/)
- [Automated Network Firewall Testing with Synthetic Canaries](./testing/automated-network-firewall-testing-with-synthetic-cloudwatch-canaries/)

## Build, Release, Deployment

- [Firewall Release](./build-release-deployment/firewall-release/)
