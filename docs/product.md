---
layout: sub-navigation
title: Product Documentation
order: 2
---

Description: Core Cloud Firewall provides platform-managed AWS Network Firewall for East-West inspection and egress filtering, plus AWS WAF for web application protection.
Team: Andromeda
Key Stakeholders:
Senior Responsible Owner:

## Architecture

- [x] The architectural views may contain architecture diagrams, security models, entity-relationship models. The views should allow an engineer to understand how the components interact at a high and low level.

[Link to architecture](./firewall/corecloud-detailed-inspection.md)

## Decision Log

- [x] A decision log should record key design decisions in context. A pattern should be selected to complement the team ways of working, and may include for example Architecture Decision Records.

[Link to decision log](./firewall/kdd-009-firewall-egress-allow-list-management.md)

## Runbooks

- [x] Document any incident support, and maintenance tasks that are the responsibility of the product team.

[Link to runbooks](./firewall/network-0004-make-changes-to-a-firewall-rule.md)

## Backups

- [ ] Document the backup process of key data, config responsibility of the product team.

[Link to backups](./backups.md)

## Disaster Recovery

- [ ] Document any disaster recovery processes for the product.

[Link to disaster recovery](./disaster-recovery.md)

## Observability

- [x] Documentation should include details of logging, alerting and monitoring designs, and links to alerting and monitoring dashboards.

[Link to observability](./firewall/dynatrace-aws-network-firewall-metrics-collection.md)

## Build, Release, Deployment

- [x] Documentation should enable an engineer to create builds, find artifacts, package releases, deploy services, and manage environments.

[Link to build release deployment](./firewall/firewall-release.md)
