---
layout: sub-navigation
title: "NETWORK-0005 Using AWS Athena to Review Network Firewall Alerts"
description: ""
order: 1
source_system: confluence
source_url: https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/409664654
last_reviewed: 2026-07-28
tags: []
status: draft
---

| **Scope & Background Information**

 |  |
| The Network Firewall alerts get logged into an S3 bucket in the LogArchive account.
We previously enabled “alert-only” (dry-run) statements for traffic that *would* be dropped by the firewall once enforcement rules are enabled. The goal is to see what traffic would be blocked so we can identify unexpected workloads or paths that will fail under the new rules.
Known migrations (e.g., GHES / GitHub Actions runners moving from Prod to Live) mean we **expect** to see dropped alerts across e.g. Prod ↔ NotProd. The runbook shows how to use **AWS Athena** to review these alerts and surface insights for next-step actions (migrate workloads, update routes, add exceptions, or refine policies).

 |  |
| **Pre-requisites** |  |
| - An Amazon S3 bucket (same region as the LogArchive account) to hold **Athena query results**, e.g. `s3://aws-athena-query-results-905418430070-eu-west-2`.

- Run Athena in the **same region** as the LogArchive account.

- Read permissions from Prod (or analyst) role to the LogArchive bucket/prefix containing Network Firewall **alert** logs.

- Write permissions for the Athena results bucket (and KMS permissions if using SSE-KMS).

 |  |
| **Triage** |  |
| N/A  |  |
| **Instructions** |  |
| ### 1. Select a location to store Athena Query Results- Workgroup → set *Query result location* to:
`s3://aws-athena-query-results-905418430070-eu-west-2/athena-results/`
### 2. Create a database
```
CREATE DATABASE IF NOT EXISTS network_firewall_database;

```

### 3. Set the current database- In the Athena console, choose **network_firewall_database** as the *Current database*.
### 4. Create tables for Alert logs

Using the Athena DDL statement, Create three tables (same schema, different S3 prefixes):

- `network_firewall_alert_logs_cc_inspection_prod`

- `network_firewall_alert_logs_cc_inspection_notprod`

- `network_firewall_alert_logs_cc_inspection_central`

**Table schema template (use this for each table; change only the `LOCATION`)**

```
CREATE EXTERNAL TABLE IF NOT EXISTS network_firewall_alert_logs_cc_inspection_prod (
  firewall_name      string,
  availability_zone  string,
  event_timestamp    string,
  event struct,
    flow_id    : bigint,
    dest_ip    : string,
    proto      : string,
    verdict    : struct,
    tls        : struct,
      ja3s    : struct
    >,
    dest_port : int,
    pkt_src   : string,
    timestamp : string,
    direction : string
  >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'ignore.malformed.json'='true',
  'case.insensitive' = 'false'
)
LOCATION 's3://aws-accelerator-central-logs-905418430070-eu-west-2/firewall/AWSLogs/396913725756/network-firewall/alert/eu-west-2/cc-inspection-prod-nfw/';
```

`For notprod` and `central, duplicate the statement and update the table name + LOCATION` to point to the correct firewall prefixes.

 |  |
| **Testing/verification**

 |  |
| **Goal:** confirm that tables return meaningful insights and reflect expected “would be dropped” traffic.

**Query 1 — Blocked or Dropped paths (top pairs)**

```
SELECT
  event.src_ip,
  event.dest_ip,
  event.alert.signature,
  COUNT(*) AS hits
FROM network_firewall_alert_logs_cc_inspection_prod
WHERE event.alert.action = 'blocked' OR event.verdict.action = 'drop'
GROUP BY 1,2,3
ORDER BY hits DESC
LIMIT 20;

```

**Query 2 — Top SNI (all outcomes)**

```
SELECT
  COALESCE(event.tls.sni, '(no_sni)') AS sni,
  COUNT(*) AS hits
FROM network_firewall_alert_logs_cc_inspection_prod
GROUP BY 1
ORDER BY hits DESC
LIMIT 100;

```
**Query 3 — Top SNI where the verdict actually dropped**

```
SELECT
  COALESCE(event.tls.sni, '(no_sni)') AS sni,
  COUNT(*) AS hits
FROM network_firewall_alert_logs_cc_inspection_prod
WHERE event.verdict.action = 'drop'
GROUP BY 1
ORDER BY hits DESC
LIMIT 100;

```
**Optional helper (flattened view for quicker exploration)**

```
CREATE OR REPLACE VIEW nfw_alerts_flat AS
SELECT
  firewall_name,
  availability_zone,
  from_iso8601_timestamp(event.timestamp) AS ts,
  event.event_type,
  event.alert.severity,
  event.alert.signature,
  event.alert.action      AS alert_action,
  event.verdict.action    AS verdict_action,
  event.app_proto,
  event.proto,
  event.src_ip,
  event.src_port,
  event.dest_ip,
  event.dest_port,
  event.tls.sni           AS sni,
  event.tls.version       AS tls_version,
  event.tls.ja3.hash      AS ja3,
  event.direction,
  event.pkt_src
FROM network_firewall_alert_logs_cc_inspection_prod;

```

 |  |
| **Rollback strategy** |  |
| This workflow is **read-only** against log data. Rollback focuses on cleaning up Athena configuration and any temporary IAM changes:

- **Athena artifacts**:Drop views/tables if created by mistake:
```
DROP VIEW IF EXISTS nfw_alerts_flat;
DROP TABLE IF EXISTS network_firewall_alert_logs_cc_inspection_prod;
DROP TABLE IF EXISTS network_firewall_alert_logs_cc_inspection_notprod;
DROP TABLE IF EXISTS network_firewall_alert_logs_cc_inspection_central;

```

- Delete saved queries in the Athena console (optional).

- (Optional) Remove or switch the Workgroup back to the previous default.

2. **S3 & KMS:**

- If you created a new results prefix, you may delete it after confirming no one needs the outputs.

- If you added KMS key grants for the Athena workgroup, remove those grants.

3.** IAM / Cross-account access:**

- Revert temporary bucket policies or role trust relationships added for this analysis.
No network policy changes are made by this runbook, so there is **no data-plane rollback** required.

 |  |
| **Automation** |  |
| Nice to have but not yet implemented -

- **IaC (Terraform/Terragrunt):**

Athena Workgroup (results location, SSE-KMS).

- Database creation.

- External tables for each firewall/log prefix.

- Saved queries (as code) for the standard reports above.

- Optionally a partition-projected table if/when logs are organized by `…/YYYY/MM/DD/HH/`.

- **Reporting:**

Glue/Athena + scheduled Amazon QuickSight dashboards or a scheduled Athena query (via EventBridge + Lambda) to export CSVs to S3.

- Alerts to Slack/Teams when “drop or blocked” counts cross thresholds (EventBridge rule triggers a Lambda that runs a parameterized Athena query).

 |  |
| **Last verified** |  |
| The last time this runbook was run and verified (would give us an idea if this runbook is current/up to date). The below macro will enter the current date/time as the file is saved.

31-Oct-2025  09:39:55

 |  |