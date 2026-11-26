# network-firewall-logging

Manages the logging configuration of an existing AWS Network Firewall firewall: which log types (`ALERT`, `FLOW`, `TLS`) are sent where.

A firewall has exactly **one** logging configuration that holds every destination, so this module owns the whole set. List every log type the firewall should keep, not only the one you are adding.

## When to use it

Use it when a log type cannot be configured by the tool that created the firewall. For example, LZA's `network-config.yaml` only supports `ALERT` and `FLOW`, so `TLS` logs need this module. Import the existing configuration, keep its `ALERT` and `FLOW` destinations exactly as they are, and add `TLS`.

TLS logs only record TLS inspection errors (connection resets from SNI mismatches and naming errors, and failed certificate revocation checks). A successful decryption writes nothing to the TLS log. Use alert logs and rules to prove that decryption works.

## Usage

```hcl
import {
  to = module.logging.aws_networkfirewall_logging_configuration.this
  id = "arn:aws:network-firewall:eu-west-2:111122223333:firewall/example-nfw"
}

module "logging" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-firewall-terraform.git//modules/network-firewall-logging?ref=<tag>"

  firewall_arn = "arn:aws:network-firewall:eu-west-2:111122223333:firewall/example-nfw"

  log_destinations = {
    # Existing destinations: must match AWS exactly
    ALERT = { destination_type = "S3", destination = { bucketName = "central-logs", prefix = "firewall" } }
    FLOW  = { destination_type = "CloudWatchLogs", destination = { logGroup = "flow-log-group" } }
    # New
    TLS = { destination_type = "S3", destination = { bucketName = "central-logs", prefix = "firewall" } }
  }
}
```

Under Terragrunt the module is the root module, so put the `import` block in the unit (for example with a `generate` block) and use `to = aws_networkfirewall_logging_configuration.this`.

## Behaviour

- **Adding a log type** is one in-place update and leaves the other destinations alone.
- **A destination that doesn't match AWS** is removed, then re-added, so that log type stops for a moment. After importing, the plan must show only the intended additions.
- **Destroy is blocked** (`prevent_destroy`), because destroying removes **every** destination, including ones created by other tools. To stop managing logging with Terraform, use `terraform state rm` instead.
- **Another tool rewriting the configuration** (for example an LZA redeploy) removes destinations it doesn't know about, such as `TLS`. The next plan shows the drift, and an apply puts it back.
- **The monitoring dashboard setting** isn't managed by this module (AWS provider 5.x has no argument for it).

## Inputs

| Name | Description | Type | Required |
|---|---|---|---|
| `firewall_arn` | ARN of the existing firewall | `string` | yes |
| `log_destinations` | Map keyed by log type (`ALERT`, `FLOW`, `TLS`) of `{ destination_type, destination }`. `destination_type` is `S3`, `CloudWatchLogs` or `KinesisDataFirehose`. `destination` holds `bucketName` (and an optional `prefix` without a leading `/`), `logGroup`, or `deliveryStream`. | `map(object)` | yes |

## Outputs

| Name | Description |
|---|---|
| `firewall_arn` | ARN of the firewall whose logging is managed |
| `log_types` | Log types configured on the firewall |
