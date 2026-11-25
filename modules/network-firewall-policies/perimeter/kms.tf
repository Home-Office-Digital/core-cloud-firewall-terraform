# ==============================================================================
# Customer managed KMS key for the firewall and its policies
# ==============================================================================
# One symmetric key per firewall. Network Firewall uses it through a grant it creates
# itself (kms:CreateGrant via the account root statement below). If this key is disabled
# or deleted, the firewall endpoints drop all packets, so it is protected from destroy and
# has the maximum deletion window.
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_kms_key" "this" {
  description             = "Network Firewall encryption key for ${var.network_firewall_name}"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountIamPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
  })

  tags = merge(var.tags, { Name = "${var.network_firewall_name}-nfw" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.network_firewall_name}-nfw"
  target_key_id = aws_kms_key.this.key_id
}
