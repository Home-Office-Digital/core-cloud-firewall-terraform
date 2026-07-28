---
layout: sub-navigation
title: "Network Firewall Refactor - Test Plan for NotProd"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/417378155
last_reviewed: 2026-07-28
tags: []
status: draft
---

# Network Firewall Refactor - Test Plan for NotProd

Subset of the network testing using have been identified for testing Home Office Jira8cc95e75-9c11-3b7e-8cde-fbdeafd296c6CCL-6166

Environments:

- NotProd
Accounts to run test from:

- NetworkTesting - Account has vpc's setup for central live, central notlive, prod and notprod

Testing by created synthetic canaries and monitoring the result

| Test Case_ID | Expected Behaviour | Source VPC/Network | Destination VPC/Network | Test Carried Out | Test Result |  |
| id.3.> A **NotProd **workload connecting to a platform product in **Central **(**Live**).

 | Allow (default allow all NotProd and Prod to access Live)

 | vpc-0dd31634ff9f6e915(notprod) | vpc-0e0f07bdfefc0423f (live)

10.252.34.44

 | Canary and manual test | Currently failed

Bug ticketHome Office Jira8cc95e75-9c11-3b7e-8cde-fbdeafd296c6CCL-6308

 |  |
| id.5 > A **NotProd **workload accessing a shared endpoint in **Central **(**Infra**).

 |  Allow (default allow all NotProd and Prod to access Infra)

 | vpc-0dd31634ff9f6e915 (notprod) | Need to identify a infra VPC | 
 | 
 |  |
| id.7 > A **NotProd **Workload accessing a workload in **Prod**.

 |  Deny

 | vpc-0dd31634ff9f6e915(notprod) | vpc-0cbcc720c22f62d88 (prod)

10.251.5.21

 | Canary  | **Passed **(No traffic allowed when when the dest ec2 to allowed to listen on 443) |  |
| id.8> A **NotProd **Workload accessing a different workload in **NotProd**.  

 | Deny by default, explicit allow required

 | vpc-0dd31634ff9f6e915 (notprod) | Will use VPC in other notprod acc | 
 | 
 |  |
| d.10> A **Prod **Workload accessing a workload in **NotProd**.

 | Deny

 | vpc-0cbcc720c22f62d88 (prod) | vpc-0dd31634ff9f6e915 (notprod) 10.111.133.28 | 
 | 
 |  |
| id.13> A NotProd workload attempting to access an external service via CTN.

 |  Allow

 | vpc-0dd31634ff9f6e915 (notprod) | need more info | 
 | 
 |  |
| id.16>A platform product in Central (Live) that needs to connect to workloads in both NotProd and Prod.

 | Allow

 | vpc-0e0f07bdfefc0423f (live) | vpc-0dd31634ff9f6e915 (notprod) - 10.111.133.28

vpc-0cbcc720c22f62d88 (prod) - 10.251.5.21

 | 
 | 
 |  |
| id.26>A NotProd workload needing to connect to an external service over the Internet via Central Egress.

 | Allow (subject to NFW rules)

 | vpc-0dd31634ff9f6e915 (notprod) | need more info | 
 | 
 |  |
| id.27>A request coming in from the Internet via Ingress to a workload in **NotProd**

 | Deny (explicit allow if testing required)

 | need more info | vpc-0dd31634ff9f6e915 (notprod) - 10.111.133.28 | 
 | 
 |  |