---
layout: sub-navigation
title: "Automated Network Firewall Testing with Synthetic Cloudwatch Canaries"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/404142730
last_reviewed: 2026-07-28
tags: []
status: draft
---

# Automated Network Firewall Testing with Synthetic Cloudwatch Canaries

## 1. OverviewAmazon CloudWatch Synthetics Canaries are lightweight scripts that simulate user behavior to monitor application endpoints and network connectivity. They run on a schedule and help detect issues such as latency, failures, or blocked traffic. In infrastructure testing, canaries can be deployed within VPCs to validate firewall rules, port accessibility, and service availability using real-time synthetic traffic.

## 2. ObjectiveAutomate the testing of network connectivity between VPCs connected via AWS Network Firewall, ensuring that firewall rules allow or block traffic as intended across various ports and protocols.

## 3. Scope- Canary deployed in VPC A
- Target EC2 in VPC B using private IP
- Scan multiple ports (e.g., 22, 80, 443, 8080)
- TCP socket connection attempts
- Logs open, closed, and timeout states
- Scheduled every x minutes( agreed time)
- Packaged as ZIP with index.js
- AM role with required permissions
- VPC config: subnet and security group allowing outbound traffic
## 4. Test Scenarios-  Verify connectivity to allowed ports (e.g., 443, 80)
- Verify blocked ports (e.g., 22, 3306) result in failed connections
- Validate timeout behavior for unreachable ports
- Confirm Canary logs match expected firewall behavior
- Test across multiple protocols if applicable
- More information 
## 5. Validation & Logging      Tools:

- CloudWatch Logs (Synthetics)
- Network Firewall Logs
- VPC Flow Logs
     Validation Steps:

- Confirm Canary logs show expected connectivity results
- Correlate with Network Firewall logs (ALLOW/DROP)
- Use CloudWatch Logs Insights to filter by port and IP
- Verify VPC Flow Logs for traffic patterns and status codes
## 6. Terraform Module for Canary Deployment      Creates:

- IAM role and policy for the Canary
- Synthetics Canary resource
      Accepts:

- ZIP file path for your Lambda code
- Canary name
- Runtime version
- Schedule expression
- Environment variables like DEST_IP, ALLOW_PORTS, DENY_PORTS, CONNECT_TIMEOUT_MS
- VPC configuration: subnet ID and security group ID