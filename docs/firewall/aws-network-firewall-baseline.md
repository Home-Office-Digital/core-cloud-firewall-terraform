---
layout: sub-navigation
title: "AWS Network Firewall Baseline"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/335823293
last_reviewed: 2026-07-28
tags: []
status: draft
---

# AWS Network Firewall Baseline

##  Key Considerations:- ### AWS Managed Rules will be used to provide a baseline policy for all firewall contexts
Managed rule groups are collections of predefined, ready-to-use rules that AWS writes and maintains for . AWS managed rule groups are free to Network Firewall customers but note should be taken of the [disclaimer](https://docs.aws.amazon.com/network-firewall/latest/developerguide/aws-managed-rule-groups-disclaimer.html). 

- ### Stateful rules will be used over Stateless rules 
Stateless rules should be used very sparingly because they can easily cause asymmetric flow forwarding issues (where only one side of the flow is seen by the stateful inspection engine of the firewall) and they tend to make the overall firewall ruleset more complex to understand and troubleshoot. For the large majority of use cases AWS recommend the stateless engine’s default action be set to “Forward to stateful rule groups” and we recommend not having any stateless rules configured since they take precedence over stateful rules.

- ### Use Custom Suricata rules instead of UI generated rules
Suricata rules defined in code allow CoreCloud platform and security engineers to more easily leverage the full flexibility of Suricata and provide the following pros:

- Maximum flexibility
- Control over the alerting and how it shows up in the logs
- Custom rule signature ID can be used which helps troubleshooting and simplifying log analysis
- Free-form text rules are easier to copy, edit, share, and backup.
- Easy to switch rule(s) from one rule group to another (blue-green testing for example)
- Allow for adding the very important keyword: “flow:to_server” to rules easily
AWS document [example Suricata rules](https://docs.aws.amazon.com/network-firewall/latest/developerguide/suricata-examples.html) to demonstrate the types of rules that can be created. 

- ### Use as few Custom Rule Groups as possible
CoreCloud will start with a single Custom Rule group per firewall policy to keep the deployment as simple as possible. Additional rules could be created in the future if limitations or to simplify the deployment. 

- ### Use Alert rule before Pass rule to log allowed traffic
Where allowed traffic is required to be logged an alert rule should be used before pass

```
#Log allowed traffic to https://*.amazonaws.com
alert tls $HOME_NET any -> any any (tls.sni; content:".amazonaws.com"; nocase; endswith; msg:"*.amazonaws.com allowed by sid:021420242"; flow:to_server; sid:021420241;)
pass tls $HOME_NET any-> any any (tls.sni; content:".amazonaws.com"; nocase; endswith; msg:"Pass rules don't alert, alert is on sid:021420241"; flow.to_server; sid:021420242;)
```
## Managed Rule GroupsAWS managed [Domain and IP rule groups ](https://docs.aws.amazon.com/network-firewall/latest/developerguide/aws-managed-rule-groups-domain-list.html)will not be used for the Inspection Firewall policy but will be implemented for central inspection. 

AWS managed [Threat signature rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/aws-managed-rule-groups-threat-signature.html) 

AWS Network Firewall managed threat signature rule groups support several categories of threat signatures to protect against various types of malware and exploits, denial of service attempts, botnets, web attacks, credential phishing, scanning tools, and mail or messaging attacks and intrusion detection.