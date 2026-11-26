variable "firewall_arn" {
  description = "ARN of the existing Network Firewall firewall."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:network-firewall:[a-z0-9-]+:[0-9]{12}:firewall/.+$", var.firewall_arn))
    error_message = "firewall_arn must be a Network Firewall firewall ARN."
  }
}

variable "log_destinations" {
  description = <<-EOT
    Every log destination the firewall should have, keyed by log type (ALERT,
    FLOW or TLS). destination_type is S3, CloudWatchLogs or KinesisDataFirehose.
    destination is the provider's log_destination map: bucketName (+ optional
    prefix, no leading /), logGroup, or deliveryStream.
  EOT
  type = map(object({
    destination_type = string
    destination      = map(string)
  }))

  validation {
    condition     = length(var.log_destinations) > 0
    error_message = "log_destinations must contain at least one log type."
  }

  validation {
    condition     = alltrue([for k in keys(var.log_destinations) : contains(["ALERT", "FLOW", "TLS"], k)])
    error_message = "log_destinations keys must be ALERT, FLOW or TLS."
  }

  validation {
    condition     = alltrue([for v in values(var.log_destinations) : contains(["S3", "CloudWatchLogs", "KinesisDataFirehose"], v.destination_type)])
    error_message = "destination_type must be S3, CloudWatchLogs or KinesisDataFirehose."
  }

  validation {
    condition = alltrue([
      for v in values(var.log_destinations) :
      v.destination_type == "S3" ? contains(keys(v.destination), "bucketName") && !startswith(try(v.destination.prefix, ""), "/") :
      v.destination_type == "CloudWatchLogs" ? contains(keys(v.destination), "logGroup") :
      contains(keys(v.destination), "deliveryStream")
    ])
    error_message = "destination must hold bucketName (and an optional prefix without a leading /) for S3, logGroup for CloudWatchLogs, or deliveryStream for KinesisDataFirehose."
  }
}
