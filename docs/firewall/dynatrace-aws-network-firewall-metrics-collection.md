---
layout: sub-navigation
title: "Dynatrace AWS Network Firewall Metrics Collection"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/387953197
last_reviewed: 2026-07-28
tags: []
status: draft
---

whitepurpleDocument Approval

| Date | Name | Version | Status |  |
| 

 | 

 | 1 | Draft |  |
| 

 | 

 | 
 | 
 |  |
| 

 | 

 | 
 | 
 |  |
| 

 | 

 | 
 | 
 |  |

## Introduction

There is a requirement to ingest AWS Network Firewall metrics into Dynatrace. Their existing tooling doesn't cater for this so this will be achieved by using a Firehose and configuring Cloudwatch Metric Streams to forward Network Firewall metrics to it.

There is a limitation with Metric Streams where they can only stream to a firehose within the same account (Unlike CloudWatch Logs which can target another account), so a new one will need to be created in any account which hosts Network Firewall metrics that need to send to Dynatrace.

## Component Diagram

a050a718-03ac-4046-946c-a30085041126DT CloudwatchDT Cloudwatch3

## Configuration### Firehose
Firehose Configuration

- Source: Direct PUT

- Destination: Dynatrace
- Firehose Stream name: CC-CWMetrics-Firehose-env (where env is the test/preprod/prod env etc)
- Tansform records: Not required
- Ingestion type: Logs
- Authentication: API token generated in Dynatrace
- API URl: URL of relevant dynatrace environment
- Content encoding: GZIP
- Server Side Encryption: Enabled using CMK
- Backup Settings:Failed Data Only
- S3 bucket: bucket created for Firehose backup (CC-CW-Logs-Firehose-Bucket-env)

### Metric Steam- Firehose stream: arn of Firehose in the same account
- Service role: select service role created for this with permissions detailed in below section
- Output format: **OpenTelemetry 0.7**
- Namespace: include only namespace **AWS/NetworkFirewall

**
## IAMThe following IAM roles or policies are required for this solution

### Metric Stream role

Role Name: CC-CW-metric-stream-role-env

Purpose: Allows Metric stream to send metrics to firehose

Applied to: Metric stream

Required Permissions: 

- firehose:PutRecord
- firehose:PutRecordBatch

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "streams.metrics.cloudwatch.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:firehose:region:account-id:deliverystream/*"
        }
    ]
}

```
## Backup

There is no requirement for any specific backup of this solution

## Cross ChargeCosts incurred for this solution will be charged as part of the overall platform costs as part of the Platform cost recharge model detailed here: [Core Cloud Cost Model - DRAFT - Core Cloud - Confluence](https://collaboration.homeoffice.gov.uk/display/CORE/Core+Cloud+Cost+Model+-+DRAFT) 

## Reference[Custom setup with Firehose - Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-metric-streams-setup-datalake.html)