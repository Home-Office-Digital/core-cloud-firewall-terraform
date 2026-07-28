---
layout: sub-navigation
title: "Reviewing Network Firewall Alert Logs using AWS Athena"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/414034270
last_reviewed: 2026-07-28
tags: []
status: draft
---

# Reviewing Network Firewall Alert Logs using AWS Athena

## Scope & Background InformationThe Network Firewall alerts get logged into an S3 bucket in the LogArchive account.

We previously enabled “alert-only” (dry-run) statements for traffic that **would** be dropped once enforcement rules are enabled. The goal is to see what traffic would be blocked so we can identify unexpected workloads or paths that will fail under the new rules.

We know, for example, that GHES and GitHub Actions runners are currently in Prod but will be moved to Live. So we expect to see **dropped** traffic alerts between Prod and NotProd. There may be other *unexpected* workloads being dropped.

This document shows how we used **AWS Athena** to review alerts and extract insights for next steps—e.g., migrating workloads, adjusting routes, adding exceptions, or refining policies.

There is a separate [runbook](https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/409664654/NETWORK-0005+Using+AWS+Athena+to+Review+Network+Firewall+Alerts) describing how to setup AWS Athena for the purpose of reviewing the firewall alert logs. In this document provide a high level how we reviewed the Firewall alert logs by running some Athena queries.

## What is Amazon Athena? (quick primer)Amazon Athena is an interactive query service that makes it easy to analyze data directly in Amazon Simple Storage Service (Amazon S3) using standard [SQL](https://docs.aws.amazon.com/athena/latest/ug/ddl-sql-reference.html). 

you can point Athena at your data stored in Amazon S3 and begin using standard SQL to run ad-hoc queries and get results in seconds.

on a high level Athena is ...

- **Interactive, serverless SQL over S3.** Athena lets you query data **directly in Amazon S3** using standard SQL—no infrastructure to manage, and you pay only for the queries you run. It scales automatically and can deliver results in seconds.

- **Metadata-driven.** Athena uses metadata (schemas) to understand your S3 data. The metadata lives in the **AWS Glue Data Catalog**. Databases and tables in Athena are containers of schema definitions that point to S3 locations; they don’t store data themselves.

- **Catalog → Database → Table.** A *catalog* (often `AwsDataCatalog`) contains *databases*; a database contains *tables*. Each table registers an S3 dataset and defines columns, data types, and the S3 path (LOCATION). You can create tables manually (DDL) or via Glue crawlers; either way, the table is registered in the Glue Catalog for Athena to query.

- **Query results to S3.** Athena writes query outputs to an S3 **results location** you configure per workgroup.

Athena Metadata Container

## ## Getting startedIn Athena, catalogs, databases, and tables are containers for the metadata definitions that define a schema for underlying source data.

Athena uses the following terms to refer to hierarchies of data objects:

- Data source – a group of databases → sometimes referred to as a catalog

- Database – a group of tables. → sometimes referred to as a schema.

- Table – data organized as a group of rows or columns

## Prerequisites - **Athena Workgroup** configured with query result location, e.g. `s3://aws-athena-query-results-905418430070-eu-west-2/athena-results/`.

- **Region alignment:** Use Athena in the same region as LogArchive. **eu-west-2**

- **Access:** Read permissions from our analyst role to the LogArchive bucket/prefix for **alert** logs; write permissions to the results bucket (and KMS access if using SSE-KMS).

## Initial Setup (one-time)- **Choose Results Location**

Set the workgroup’s *Query result location* to the S3 results bucket/prefix.

- **Create Database**

```
CREATE DATABASE IF NOT EXISTS network_firewall_database;

```
Set **network_firewall_database** as the current database.
- **Create Alert Tables (per firewall/prefix)**
We analyze a sample Network Firewall alert logs and create a table for alert logs using the AWS Athena 'CREATE TABLE' command:

```
{"firewall_name":"cc-inspection-prod-nfw","availability_zone":"eu-west-2a","event_timestamp":"1759317294","event":{"tx_guessed":true,"tx_id":0,"app_proto":"tls","src_ip":"10.252.0.151","src_port":40655,"event_type":"alert","alert":{"severity":3,"signature_id":4,"rev":0,"signature":"aws:alert_established action","action":"blocked","category":""},"flow_id":2091564880938435,"dest_ip":"10.251.5.182","proto":"TCP","verdict":{"action":"drop"},"tls":{"sni":"github.ci.core.homeoffice.gov.uk","version":"UNDETERMINED","ja3":{"hash":"1be8360b66649edee1de25f81d98ec27","string":"771,49195-49199-49196-49200-52393-52392-49161-49171-49162-49172-156-157-47-53-49170-10-4865-4866-4867,0-5-10-11-13-65281-23-18-43-51,29-23-24-25,0"}},"dest_port":443,"pkt_src":"geneve encapsulation","timestamp":"2025-10-01T11:14:54.833146+0000","direction":"to_server"}}

{"firewall_name":"cc-inspection-prod-nfw","availability_zone":"eu-west-2c","event_timestamp":"1759317261","event":{"tx_guessed":true,"tx_id":0,"app_proto":"tls","src_ip":"10.251.8.156","src_port":25631,"event_type":"alert","alert":{"severity":3,"signature_id":2025092501,"rev":0,"signature":"ALERT: TLS traffic to APA-HOB (PROD)","action":"allowed","category":""},"flow_id":1418294666628877,"dest_ip":"10.23.85.200","proto":"TCP","verdict":{"action":"pass"},"tls":{"sni":"contactless-pilot.pp2.bmps.homeoffice.gov.uk","version":"UNDETERMINED","ja3":{"hash":"0a0d72200639a7a39887b9d81a247310","string":"771,4866-4865-4867-49196-49195-52393-49200-52392-49199-159-52394-163-158-162-49188-49192-49187-49191-107-106-103-64-49162-49172-49161-49171-57-56-51-50-157-156-61-60-53-47-255,0-5-10-11-17-23-35-13-43-45-50-51,29-23-24-25-30-256-257-258-259-260,0"}},"dest_port":3001,"pkt_src":"geneve encapsulation","timestamp":"2025-10-01T11:14:21.871270+0000","direction":"to_server"}}

```
Use the sample alert logs above JSON schema (Suricata EVE alert structure) and point each table to its S3 prefix. Example (Prod firewall):

**        **

```
CREATE EXTERNAL TABLE IF NOT EXISTS network_firewall_alert_logs_cc_inspection_prod (
  firewall_name       string,
  availability_zone   string,
  event_timestamp     string,
  event struct,
    flow_id     : bigint,
    dest_ip     : string,
    proto       : string,
    verdict     : struct,
    tls         : struct
    >,
    dest_port  : int,
    pkt_src    : string,
    timestamp  : string,
    direction  : string
  >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('ignore.malformed.json'='true')
LOCATION 's3://aws-accelerator-central-logs-968840656855-eu-west-2/firewall/AWSLogs/124355655239/network-firewall/alert/eu-west-2/cc-inspection-prod-nfw/';

```
W created 3 tables (for now):

Tables created :
1.network_firewall_alert_logs_cc_inspection_prod -→ InspectionProd
2.network_firewall_alert_logs_cc_inspection_notprod. -→ InspectionNotProd
3. network_firewall_alert_logs_cc_inspection_central --> for Inspection Central

## Key Queries to Review AlertsWe run the following queries in Athena to review the firewall alert logs:

1 Review Latest Events

we run the following query 

```
SELECT
  from_iso8601_timestamp(event.timestamp) AT TIME ZONE 'Europe/London' AS ts_london,
  firewall_name, availability_zone,
  event.event_type, event.alert.signature,
  event.alert.action AS alert_action,
  event.verdict.action AS verdict_action,
  event.src_ip, event.dest_ip, event.dest_port, event.app_proto, event.tls.sni
FROM network_firewall_alert_logs_cc_inspection_prod
ORDER BY ts_london DESC
LIMIT 50;

```
results of Review of Latest Events 

2. Latest Event where verdicts is a drop

```
SELECT
  from_iso8601_timestamp(event.timestamp) AT TIME ZONE 'Europe/London' AS ts_london,
  firewall_name, availability_zone,
  event.event_type, event.alert.signature,
  event.alert.action AS alert_action,
  event.verdict.action AS verdict_action,
  event.src_ip, event.dest_ip, event.dest_port, event.app_proto, event.tls.sni
FROM network_firewall_alert_logs_cc_inspection_prod
WHERE event.verdict.action = 'drop'
ORDER BY ts_london DESC
LIMIT 50;

```
Results of Latest events where verdict is a drop

3. 

Reference

Runbook : 

[https://docs.aws.amazon.com/athena/latest/ug/what-is.html](https://docs.aws.amazon.com/athena/latest/ug/what-is.html)

[https://docs.aws.amazon.com/athena/latest/ug/understanding-tables-databases-and-the-data-catalog.html](https://docs.aws.amazon.com/athena/latest/ug/understanding-tables-databases-and-the-data-catalog.html)