---
layout: sub-navigation
title: "NETWORK-0004 Make changes to a firewall rule"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/383441564
last_reviewed: 2026-07-28
tags: []
status: draft
---

# NETWORK-0004 Make changes to a firewall rule

falseWarningChanging firewall rules can have wide impact on teants and workloads if done incorrectly. Any changes should be made with caution and be reviewed carefully for misconfiguration.

| **Scope & Background Information**

 |  |
| Changing firewall rules can have wide impact on teants and workloads if done incorrectly. Any changes should be made with caution and be reviewed carefully for misconfiguration.

 |  |
| **Pre-requisites** |  |
| Before making a change to the network firewall rules we should raise a change (in future a standard change). The change reference should be included in the PR as part of criteria to merge it. 

Firewall changes will also likely be requested by a tenant or platform team and this should be documented in a CC Jira ticket, or in a JSD ticket using this form: [Request a firewall change - Core Cloud - Service project](https://support.acp.homeoffice.gov.uk/servicedesk/customer/portal/6/create/169) 

 |  |
| **Triage** |  |
| N/A |  |
| **Instructions** |  |
| ### 1. Clone the repoClone the networking terragrunt repo.

[https://github.com/UKHomeOffice/core-cloud-networking-terragrunt](https://github.com/UKHomeOffice/core-cloud-networking-terragrunt)

### 2. Locate the Inspection configurationNavigate to the `platform/prod/InspectionNotProd` folder for **NotProd** network inspection firewall rules.

Navigate to the `platform/prod/InspectionProd` folder, for **Prod** network inspection firewall rules.

Within this folder, there will be a folder called **NetworkFirewallRules**.

Within this folder there will be a file called **rules.txt**.

### 3. Edit the rules fileThe **rules.txt** file contains AWS Network Firewall [Suricata](https://docs.aws.amazon.com/network-firewall/latest/developerguide/suricata-examples.html) rules.

Locate the rule you wish to modify. Comments have been left in the file as a description of the rule's intent. Whilst the description can help to locate the relevant rules, they should not be relied upon and the rules should be read carefully.

If a new rule is required to be added, the value of the `sid` field needs to be unique.

Append the new rule to the end of the file and be sure to increment the value of the `sid`.

### 4. Create a pull requestRaise a new pull request for the change.

The request will need to be reviewed by another member of team Andromeda.

The intended change should be clearly documented on the PR description so that the reviewer can check to see if the rule change will have the desired effect.

Once the PR has been merged, a GitHub actions workflow will run and automatically apply the Terraform changes.

Changes to the firewall rules have almost immediate effect.

 |  |
| **Testing/verification**

 |  |
| Contact the requestor to ask them to test that they are able to carry out the activity that required a firewall rule change.

 |  |
| **Rollback strategy** |  |
| You can revert your changes by again amending the rules.txt file in the repository above. 

 |  |
| **Automation** |  |
| No - this should be done manually to ensure approvals are in place. 

 |  |
| **Last verified** |  |
| The last time this runbook was run and verified (would give us an idea if this runbook is current/up to date). The below macro will enter the current date/time as the file is saved.

16-Jul-2025 16:08:02

 |  |