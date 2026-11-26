mock_provider "aws" {}

variables {
  firewall_arn = "arn:aws:network-firewall:eu-west-2:111122223333:firewall/example-nfw"
}

run "alert_flow_and_tls" {
  command = plan

  variables {
    log_destinations = {
      ALERT = { destination_type = "S3", destination = { bucketName = "central-logs", prefix = "firewall" } }
      FLOW  = { destination_type = "CloudWatchLogs", destination = { logGroup = "flow-log-group" } }
      TLS   = { destination_type = "S3", destination = { bucketName = "central-logs", prefix = "firewall" } }
    }
  }

  assert {
    condition     = length(aws_networkfirewall_logging_configuration.this.logging_configuration[0].log_destination_config) == 3
    error_message = "Expected one destination per log type"
  }

  assert {
    condition = toset([
      for d in aws_networkfirewall_logging_configuration.this.logging_configuration[0].log_destination_config : d.log_type
    ]) == toset(["ALERT", "FLOW", "TLS"])
    error_message = "Expected ALERT, FLOW and TLS destinations"
  }

  assert {
    condition = alltrue([
      for d in aws_networkfirewall_logging_configuration.this.logging_configuration[0].log_destination_config :
      d.log_type != "TLS" || (d.log_destination_type == "S3" && d.log_destination["bucketName"] == "central-logs")
    ])
    error_message = "TLS should go to the S3 bucket given"
  }

  assert {
    condition     = output.log_types == ["ALERT", "FLOW", "TLS"]
    error_message = "log_types output should list the configured types"
  }
}

run "rejects_unknown_log_type" {
  command = plan

  variables {
    log_destinations = {
      DEBUG = { destination_type = "S3", destination = { bucketName = "central-logs" } }
    }
  }

  expect_failures = [var.log_destinations]
}

run "rejects_unknown_destination_type" {
  command = plan

  variables {
    log_destinations = {
      TLS = { destination_type = "Splunk", destination = { bucketName = "central-logs" } }
    }
  }

  expect_failures = [var.log_destinations]
}

run "rejects_s3_without_bucket" {
  command = plan

  variables {
    log_destinations = {
      TLS = { destination_type = "S3", destination = { prefix = "firewall" } }
    }
  }

  expect_failures = [var.log_destinations]
}

run "rejects_s3_prefix_with_leading_slash" {
  command = plan

  variables {
    log_destinations = {
      TLS = { destination_type = "S3", destination = { bucketName = "central-logs", prefix = "/firewall" } }
    }
  }

  expect_failures = [var.log_destinations]
}

run "rejects_cloudwatch_without_log_group" {
  command = plan

  variables {
    log_destinations = {
      FLOW = { destination_type = "CloudWatchLogs", destination = { bucketName = "central-logs" } }
    }
  }

  expect_failures = [var.log_destinations]
}

run "rejects_empty_destinations" {
  command = plan

  variables {
    log_destinations = {}
  }

  expect_failures = [var.log_destinations]
}

run "rejects_bad_firewall_arn" {
  command = plan

  variables {
    firewall_arn = "cc-inspection-notprod-nfw"
    log_destinations = {
      TLS = { destination_type = "S3", destination = { bucketName = "central-logs" } }
    }
  }

  expect_failures = [var.firewall_arn]
}
