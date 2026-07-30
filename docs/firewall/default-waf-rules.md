---
layout: sub-navigation
title: "Default WAF rules"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/331944293
last_reviewed: 2026-07-28
tags: []
status: draft
---

The implemented WAF rules follow the [AWSManagedRulesCommonRuleSet](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-crs) from AWS. 

The following is a point-in-time () copy and may not reflect any updates from AWS.

| Rule name | Description & Label |  |
| NoUserAgent_HEADER | Inspects for requests that are missing the HTTP User-Agent header.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:NoUserAgent_Header

 |  |
| UserAgent_BadBots_HEADER | Inspects for common User-Agent header values that indicate that the request is a bad bot. Example patterns include nessus, and nmap. For bot management, see also [AWS WAF Bot Control rule group](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-bot.html).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:BadBots_Header

 |  |
| SizeRestrictions_QUERYSTRING | Inspects for URI query strings that are over 2,048 bytes.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:SizeRestrictions_QueryString

 |  |
| SizeRestrictions_Cookie_HEADER | Inspects for cookie headers that are over 10,240 bytes.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:SizeRestrictions_Cookie_Header

 |  |
| SizeRestrictions_BODY | Inspects for request bodies that are over 8 KB (8,192 bytes).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:SizeRestrictions_Body

 |  |
| SizeRestrictions_URIPATH | Inspects for URI paths that are over 1,024 bytes.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:SizeRestrictions_URIPath

 |  |
| EC2MetaDataSSRF_BODY | Inspects for attempts to exfiltrate Amazon EC2 metadata from the request body.

###### Warning

This rule only inspects the request body up to the body size limit for the web ACL and resource type. For Application Load Balancer and AWS AppSync, the limit is fixed at 8 KB. For CloudFront, API Gateway, Amazon Cognito, App Runner, and Verified Access, the default limit is 16 KB and you can increase the limit up to 64 KB in your web ACL configuration. This rule uses the Continue option for oversize content handling. For more information, see [Oversize web request components in AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-oversize-request-components.html).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:EC2MetaDataSSRF_Body

 |  |
| EC2MetaDataSSRF_COOKIE | Inspects for attempts to exfiltrate Amazon EC2 metadata from the request cookie.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:EC2MetaDataSSRF_Cookie

 |  |
| EC2MetaDataSSRF_URIPATH | Inspects for attempts to exfiltrate Amazon EC2 metadata from the request URI path.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:EC2MetaDataSSRF_URIPath

 |  |
| EC2MetaDataSSRF_QUERYARGUMENTS | Inspects for attempts to exfiltrate Amazon EC2 metadata from the request query arguments.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:EC2MetaDataSSRF_QueryArguments

 |  |
| GenericLFI_QUERYARGUMENTS | Inspects for the presence of Local File Inclusion (LFI) exploits in the query arguments. Examples include path traversal attempts using techniques like ../../.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericLFI_QueryArguments

 |  |
| GenericLFI_URIPATH | Inspects for the presence of Local File Inclusion (LFI) exploits in the URI path. Examples include path traversal attempts using techniques like ../../.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericLFI_URIPath

 |  |
| GenericLFI_BODY | Inspects for the presence of Local File Inclusion (LFI) exploits in the request body. Examples include path traversal attempts using techniques like ../../.

###### Warning

This rule only inspects the request body up to the body size limit for the web ACL and resource type. For Application Load Balancer and AWS AppSync, the limit is fixed at 8 KB. For CloudFront, API Gateway, Amazon Cognito, App Runner, and Verified Access, the default limit is 16 KB and you can increase the limit up to 64 KB in your web ACL configuration. This rule uses the Continue option for oversize content handling. For more information, see [Oversize web request components in AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-oversize-request-components.html).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericLFI_Body

 |  |
| RestrictedExtensions_URIPATH | Inspects for requests whose URI paths contain system file extensions that are unsafe to read or run. Example patterns include extensions like .log and .ini.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:RestrictedExtensions_URIPath

 |  |
| RestrictedExtensions_QUERYARGUMENTS | Inspects for requests whose query arguments contain system file extensions that are unsafe to read or run. Example patterns include extensions like .log and .ini.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:RestrictedExtensions_QueryArguments

 |  |
| GenericRFI_QUERYARGUMENTS | Inspects the values of all query parameters for attempts to exploit RFI (Remote File Inclusion) in web applications by embedding URLs that contain IPv4 addresses. Examples include patterns like http://, https://, ftp://, ftps://, and file://, with an IPv4 host header in the exploit attempt.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericRFI_QueryArguments

 |  |
| GenericRFI_BODY | Inspects the request body for attempts to exploit RFI (Remote File Inclusion) in web applications by embedding URLs that contain IPv4 addresses. Examples include patterns like http://, https://, ftp://, ftps://, and file://, with an IPv4 host header in the exploit attempt.

###### Warning

This rule only inspects the request body up to the body size limit for the web ACL and resource type. For Application Load Balancer and AWS AppSync, the limit is fixed at 8 KB. For CloudFront, API Gateway, Amazon Cognito, App Runner, and Verified Access, the default limit is 16 KB and you can increase the limit up to 64 KB in your web ACL configuration. This rule uses the Continue option for oversize content handling. For more information, see [Oversize web request components in AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-oversize-request-components.html).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericRFI_Body

 |  |
| GenericRFI_URIPATH | Inspects the URI path for attempts to exploit RFI (Remote File Inclusion) in web applications by embedding URLs that contain IPv4 addresses. Examples include patterns like http://, https://, ftp://, ftps://, and file://, with an IPv4 host header in the exploit attempt.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:GenericRFI_URIPath

 |  |
| CrossSiteScripting_COOKIE | Inspects the values of cookie headers for common cross-site scripting (XSS) patterns using the built-in AWS WAF [Cross-site scripting attack rule statement](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss-match.html). Example patterns include scripts like <script>alert("hello")</script>.

###### Note

The rule match details in the AWS WAF logs is not populated for version 2.0 of this rule group.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:CrossSiteScripting_Cookie

 |  |
| CrossSiteScripting_QUERYARGUMENTS | Inspects the values of query arguments for common cross-site scripting (XSS) patterns using the built-in AWS WAF [Cross-site scripting attack rule statement](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss-match.html). Example patterns include scripts like <script>alert("hello")</script>.

###### Note

The rule match details in the AWS WAF logs is not populated for version 2.0 of this rule group.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:CrossSiteScripting_QueryArguments

 |  |
| CrossSiteScripting_BODY | Inspects the request body for common cross-site scripting (XSS) patterns using the built-in AWS WAF [Cross-site scripting attack rule statement](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss-match.html). Example patterns include scripts like <script>alert("hello")</script>.

###### Note

The rule match details in the AWS WAF logs is not populated for version 2.0 of this rule group.

###### Warning

This rule only inspects the request body up to the body size limit for the web ACL and resource type. For Application Load Balancer and AWS AppSync, the limit is fixed at 8 KB. For CloudFront, API Gateway, Amazon Cognito, App Runner, and Verified Access, the default limit is 16 KB and you can increase the limit up to 64 KB in your web ACL configuration. This rule uses the Continue option for oversize content handling. For more information, see [Oversize web request components in AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/waf-oversize-request-components.html).

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:CrossSiteScripting_Body

 |  |
| CrossSiteScripting_URIPATH | Inspects the value of the URI path for common cross-site scripting (XSS) patterns using the built-in AWS WAF [Cross-site scripting attack rule statement](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss-match.html). Example patterns include scripts like <script>alert("hello")</script>.

###### Note

The rule match details in the AWS WAF logs is not populated for version 2.0 of this rule group.

Rule action: Block

Label: awswaf:managed:aws:core-rule-set:CrossSiteScripting_URIPath

 |  |