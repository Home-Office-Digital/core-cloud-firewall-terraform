---
layout: sub-navigation
title: "CoreCloud Detailed Inspection"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/331952997
last_reviewed: 2026-07-28
tags: []
status: draft
---

The purpose of this document is to outline a straw-man/first pass of detailed inspection to support the build-out of the landing zone accelerator configuration files and any Terraform pipelines required to meet the inspection requirements for:

- East-West traffic moving between VPCs in CoreCloud, including environment segregation to stop traffic moving between SDLC stages such as Dev/Test and NotProd/Prod.
- North/South core cloud traffic as it moves to other home-office networks such as the CTN and EBSA.
- Central Egress as part of the CoreCloud will offer centralised egress out to the internet with a dedicated AWS network firewall and curated Suricata rules to detect and block malicious activity.
- Central Ingress CoreCloud will also provide a managed Ingress service, which could be configured to use AWS network edge services such as CloudFront, Web Application Firewall, and DDoS protection in Shield Advance, as well as Suricata-based firewall rules.
- Distributed Firewall CoreCloud will also support a distributed deployment model where workloads can have the same services provided by central Ingress and egress but with a dedicated AWS network firewall hosted locally to application VPCs, such as EKS, for performance or specific security requirements.
The following diagram outlines the inspection models for a single AZ, a multi-AZ deployed will be detailed in another diagram. 

The approach is based on the AWS network firewall combined mode [outlined](https://d1.awsstatic.com/architecture-diagrams/ArchitectureDiagrams/inspection-deployment-models-with-AWS-network-firewall-ra.pdf) in this white-paper