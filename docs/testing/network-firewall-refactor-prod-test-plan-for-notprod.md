---
layout: sub-navigation
title: "Network Firewall Refactor - Prod Test Plan for NotProd"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/420936008
last_reviewed: 2026-07-28
tags: []
status: draft
---

Subset of the network testing using have been identified for testing Home Office Jira8cc95e75-9c11-3b7e-8cde-fbdeafd296c6CCL-6166

Environments:

- NotProd
Accounts to run test from:

- NetworkTesting - 577638371426
- Notprod
- Prod
Note:

All tests could not be verified as  central live & central notlive VPC's are not present on the Networktesting account in prod. 

Ticket has been raised to add the VPC's

- Home Office Jira8cc95e75-9c11-3b7e-8cde-fbdeafd296c6CCL-6328

Testing by created synthetic canaries and monitoring the result

| Test Case_ID | Expected Behaviour | Source VPC/Network | Destination VPC/Network | Test Carried Out | Test Result |  |
| id.3.> A **NotProd **workload connecting to a platform product in **Central **(**Live**).

 | Allow (default allow all NotProd and Prod to access Live)

 | NetworkTesting

vpc-0c8e77491d061799f

 | 

 | 
 | 

 |  |
| id.5 > A **NotProd **workload accessing a shared endpoint in **Central **(**Infra**).

 |  Allow (default allow all NotProd and Prod to access Infra)

 | NetworkTesting

vpc-0c8e77491d061799f

 | 

 | 
 | 
 |  |
| id.7 > A **NotProd **Workload accessing a workload in **Prod**.

 |  Deny

 | NetworkTesting

vpc-0c8e77491d061799f

 | NetworkTesting

vpc-0cfedc969beac04fa - 10.251.4.30

 | Manual 

[Canary](https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#synthetics:/canary/detail/id_7_notprod_to_prod_deny) - Negative test - failed.

 | **Passed **(Deny)

Canary fails connecting on port 443

 |  |
| id.8> A **NotProd **Workload accessing a different workload in **NotProd**.  

 | Deny by default, explicit allow required

 | NetworkTesting

vpc-0c8e77491d061799f

 | Identity notprod account | 
 | 
 |  |
| d.10> A **Prod **Workload accessing a workload in **NotProd**.

 | Deny

 | NetworkTesting

vpc-0cfedc969beac04fa 

 | NetworkTesting

vpc-0c8e77491d061799f - 10.111.136.89

 | Manual

[Canary ](https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#synthetics:/canary/detail/id_10_prod_to_notprod_deny)

 | **Passed **(Deny)

 |  |
| id.13> A NotProd workload attempting to access an external service via CTN.

 |  Allow

 | NetworkTesting

vpc-0c8e77491d061799f

 | need more info | 
 | 
 |  |
| id.16>A platform product in Central (Live) that needs to connect to workloads in both NotProd and Prod.

 | Allow

 | 
 | NetworkTesting

vpc-0cfedc969beac04fa - 10.251.4.30

vpc-0c8e77491d061799f - 10.111.136.89

 | 
 | 
 |  |
| id.26>A NotProd workload needing to connect to an external service over the Internet via Central Egress.

 | Allow (subject to NFW rules)

 | NetworkTesting

vpc-0c8e77491d061799f

 | need more info | 
 | 
 |  |
| id.27>A request coming in from the Internet via Ingress to a workload in **NotProd**

 | Deny (explicit allow if testing required)

 | need more info | NetworkTesting

vpc-0c8e77491d061799f - 10.111.136.89

 | 
 | 
 |  |