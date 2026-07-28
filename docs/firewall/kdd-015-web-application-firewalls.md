---
layout: sub-navigation
title: "KDD-015: Web Application Firewalls"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/435447566
last_reviewed: 2026-07-28
tags: []
status: draft
---

# KDD-015: Web Application Firewalls

trueinstructionsmauveInstructions- Complete the page propertiesCategory: choose one of BUSINESS / SOLUTION / INFRASTRUCTURE
- Type: DESIGN DECISION / SCOPE
- Status: choose one of LOGGED / IN PROGRESS / BLOCKED / APPROVED / REJECTED
- Impact: choose one of LOW / MEDIUM / HIGH
- Architect: "@" the owner, typically yourself
- Complete the detail of the Design DecisionThis should be done as you go - don't wait until you know the recommendation (i.e. You can start with a Problem Statement and a list of provisional Options - that is enough to discuss with your peers)
- Add a label of "kdd"The label/tag icon can be found at the bottom right corner of the page  - click the icon, type kdd, add
- When the KDD has been approved, change the label to "kdd-a".

Design Decision Summary
| ID | KDD-015 |  |
| Title | Web Application Firewalls |  |
| Product | AWS WAF

 |  |
| Category | Bluesolution 

 |  |
| Type | Bluedesign decision 

 |  |
| Status | Greenapproved   

 |  |
| Impact | Yellowmedium 

 |  |
| Architect |   

 |  |
| Jira ref | Home Office Jiraissuekey,summary,issuetype,created,updated,duedate,assignee,reporter,priority,status,resolutionkey,summary,type,created,updated,due,assignee,reporter,priority,status,resolution8cc95e75-9c11-3b7e-8cde-fbdeafd296c6CCL-7246

 |  |

## BackgroundAs part of the wider platform and security programme, the organisation is standardising how internet-facing workloads are protected across AWS accounts operating within an AWS Organization and Landing Zone Accelerator (LZA).

Multiple application teams (tenants) deploy workloads behind Application Load Balancers (ALBs) in Core Cloud (AWS). To meet security, audit, and operational requirements, a consistent application-layer protection model is required that aligns with organisational security strategy while supporting multi-tenant delivery at scale.

This KDD is limited to assessing protection from layer 7 attacks at the perimeter. Internal inspection is performed by AWS Network Firewall once traffic has passed through the WAF on the perimeter, 

While we currently have a WAF deployed, it's not being utilised to provide the required protection of the internet ingress.

## Problem statement (specific to KDD) **Overall problem:**
The platform must ensure that all internet-facing ALBs are protected by a mandatory AWS WAF baseline that cannot be bypassed or degraded, while still allowing tenants to apply application-specific WAF controls where required.

**Specific KDD problem:**
What is the most appropriate approach for managing AWS WAF across multiple AWS accounts and tenants such that:

- Baseline protections are enforced consistently

- Security drift is automatically corrected

- Tenant-specific requirements can be supported safely

- The solution scales operationally and is auditable

## Requirements (specific to KDD) The selected approach must:

- Enforce mandatory baseline AWS WAF protections on all in-scope ALBs

- Prevent tenants from bypassing or weakening baseline controls

- Support tenant-specific WAF customisation within defined guardrails

- Apply to new and existing ALBs automatically

- Correct configuration drift through automated remediation

- Scale across multiple AWS accounts and environments

- Align with cyber security, audit, and governance requirements

- Support controlled rollout and rollback of security controls

## Options trueoptions instructionsmauveOptions Instructions- This section should contain a description of each of the options that you have explored to address the problem statement and meet the requirements documented above, including a list of pros and cons. 
- Diagrams, such as architectural views or sequence diagrams, may be used to help illustrate the options but are not mandated.

1: Tenants Manage Their Own AWS WAFEach tenant independently creates, manages, and attaches AWS WAF Web ACLs to their ALBs within their application accounts.

#### Pros- Minimal platform operational overhead
- Maximum flexibility for tenants
#### Cons- No guarantee of baseline security controls
- Inconsistent protection across applications
- High audit risk
- No drift detection or enforcement
- Requires tenants to have skills in this space

2: Platform Team Deploys and Manages WAF per TenantThe platform or security team centrally creates and manages individual AWS WAF Web ACLs for each tenant and attaches them to tenant ALBs.

#### Pros- Strong central control
- Consistent rule implementation
#### Cons- Does not scale operationally
- High ongoing maintenance effort
- Tight coupling between platform and application teams
- Slow response to tenant-specific needs

3: AWS Firewall Manager with Mandatory Baseline and Controlled Tenant CustomisationUse AWS Firewall Manager (FMS) in a central Network/Security account to enforce mandatory baseline WAF protections across all in-scope ALBs, while allowing tenants to add custom rule groups within a defined section of a platform-managed Web ACL. Optional protection profiles are selected via platform-managed ALB tags.

Tag values are restricted to a predefined set and are managed exclusively by the platform team. Tenants do not have permission to add, modify, or remove tags that influence Firewall Manager policy selection.

Baseline rules will include as per AWS recommendation (Essential + extras).

WAF_IngressWAF_Ingress6

#### Pros- Enforced baseline security
- Consistent protection across accounts
- Automatic drift detection and remediation
- Scales across environments and tenants
- Controlled tenant flexibility
- Strong auditability and governance
#### Cons- Additional service cost
- Reduced flexibility compared to fully tenant-managed WAF
- Requires careful policy and tagging governance
## Discounted options trueDiscounted OptionsEnter brief details of any technically feasible options - if any - that have been discounted from full analysis, including the rationale for discounting them

| Option Ref and Name | Brief Description | Rationale for discounting |  |
| ### 1 – Tenants Manage Their Own AWS WAF

 | Each tenant independently creates, manages, and attaches AWS WAF Web ACLs to their ALBs within their application accounts. | - No guarantee that baseline security controls are applied

- Inconsistent rule sets across tenants

- High audit and compliance risk

- No automatic drift detection or remediation

- Security posture depends on individual tenant maturity

 |  |
| ### 2 – Platform Team Manages WAF per Tenant | The platform or security team centrally creates and manages individual AWS WAF Web ACLs for each tenant and attaches them to tenant ALBs. | - High operational overhead for the platform team

- Does not scale as tenant count increases

- Slower response to tenant-specific requirements

- Tight coupling between platform and application delivery

- Increased risk of configuration error at scale

 |  |

## Evaluation Alignment with **[Architecture Principles](https://confluence.bics-collaboration.homeoffice.gov.uk/display/AD/1.3+-+Home+Office+Principles)** and ****

true- Alignment with **[Architecture Principles](https://confluence.bics-collaboration.homeoffice.gov.uk/display/AD/1.3+-+Home+Office+Principles)**, Standards and Patterns:Add or remove a column as required to match the number of options
- Rate each option against the relevant architecture principles in the table (leave blank if not applicable) - GreenYes Neutral RedNo
- Summarise your evaluation in a paragraph after the table. At this point, you should also consider non-functional and commercial aspects of the options as well as functional and architectural fit.

| Principle | Option 3 - Mandatory Baseline with Customisation |  |
| E1 - One Home Office

 | GreenYes

 |  |
| E2 - Maximum benefit at lowest cost and risk

 | GreenYes

 |  |
| E3 - Continuity of critical Home Office functions

 | GreenYes

 |  |
| E4 - Compliance with policies and standards

 | GreenYes

 |  |
| E5 - Just Enough Architecture

 | GreenYes

 |  |
| E6 - We own the design

 | GreenYes

 |  |
| E7 - Convergence with the future state architecture

 | GreenYes

 |  |
| E8 - Commodity cloud first

 | GreenYes

 |  |
| E9 - Service qualities are as important as user needs

 | GreenYes

 |  |
| S1 - Adaptability and flexibility

 | GreenYes

 |  |
| S2 - Cloud native applications

 | GreenYes

 |  |
| S3 - Think big, deliver small

 | GreenYes

 |  |
| S4 - Services are loosely coupled

 | GreenYes

 |  |
| U1 - Services are designed around the needs of the user

 | GreenYes

 |  |
| U2 - Services are device agnostic

 | Neutral

 |  |
| D1 - Information is treated as an asset

 | GreenYes

 |  |
| D2 - Information is appropriately protected, secured and accessed

 | GreenYes

 |  |
| D3 - Consistent terminology and definitions

 | GreenYes

 |  |
| P1 - Common platforms and reusable components

 | GreenYes

 |  |
| P2 - Control of technical diversity

 | GreenYes

 |  |
| P3 - Open standards, open data, open source

 | GreenYes

 |  |
| Sc1 - Create responsibility for cyber security risk

 | GreenYes

 |  |
| Sc2 - Source secure technology products

 | GreenYes

 |  |
| Sc3 - Adopt a risk-driven approach

 | GreenYes

 |  |
| Sc4 - Design usable security controls

 | GreenYes

 |  |
| Sc5 - Build in detect and respond security

 | GreenYes

 |  |
| Sc6 - Design flexible architectures

 | GreenYes

 |  |
| Sc7 - Minimise the attack surface

 | GreenYes

 |  |
| Sc8 - Defend in depth

 | GreenYes

 |  |
| Sc9 - Embed continuous assurance

 | GreenYes

 |  |
| Sc10 - Make changes securely

 | GreenYes

 |  |

| Option 

 | YES | NEUTRAL | NO |  |
| 3. Mandatory Baseline with Customisation

 | 30 | 1 | 0 |  |

## Recommendation and rationale It is highly recommended that Option 3 - Mandatory Baseline with Customisation is selected as our approach for managing AWS WAF across the platform. This approach enables a strong baseline protection with tenants able to customise for specific needs. This approach scales well and enables a high level of auditability and governance. 

As this is our first usage of AWS Firewall Manager on Core Cloud, it's also recommended that we investigate how we can benefit from this capability across the platform. AWS Firewall Manager can be used to manage Network Firewall, Shield Advanced, VPC Security groups and more.

**NOTE: HMPO have a requirement for segregated and HMPO managed Firewalls and WAFs with layered protection using FortiWeb VM for WAF. As such, ingress for HMPO workloads shouldn't go through the centralised WAF and Inspection. Design work needs to be undertaken to assess how this can be delivered and any subsequent engineering performed.**

## Reviewers / Approval date 
| Name | Role | Review Date | Approval Date |  |
|   | Principal Architect |  

 |  

 |  |
|   | 
 | 
 | 
 |  |
|   | Security Architect |  

 |  

 |  |

## Consequences and next steps 

79
incomplete
x

80
incomplete
x