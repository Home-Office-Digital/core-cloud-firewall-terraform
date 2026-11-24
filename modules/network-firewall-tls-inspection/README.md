# network-firewall-tls-inspection

Creates an AWS Network Firewall TLS inspection configuration for **inbound** inspection, with one public ACM server certificate and one scope per tenant. Attach the result through the `tls_inspection_configuration_arn` attribute of a **new** policy version in the inspection policy module.

Nothing is decrypted until traffic matches a scope. A tenant that is set up but not live uses a destination that matches nothing, for example `192.0.2.0/32`. A configuration needs at least one certificate, so there must always be at least one tenant, for example a platform test tenant.

## Usage

```hcl
module "tls_inspection" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-firewall-terraform.git//modules/network-firewall-tls-inspection?ref=<tag>"

  name = "cc-inspection-notprod-tls-inspection"

  tenants = {
    fw-test = {
      domains      = ["*.fw-test.np.core.homeoffice.gov.uk"]
      destinations = ["192.0.2.0/32"] # matches nothing
    }
    acme = {
      domains      = ["*.acme.np.core.homeoffice.gov.uk"]
      destinations = ["10.111.20.0/24"]
    }
  }

  validation_zone_id = null # DNS validation records are created elsewhere
}

module "policy" {
  # ...
  active_policy_version = "primary" # switch to "tls" once the new policy is ready

  policy_versions = {
    primary = { name_suffix = "", description = "...", custom_stateful_groups = [], custom_stateless_groups = [] }
    tls = {
      name_suffix                      = "-tls"
      description                      = "... with TLS inspection"
      custom_stateful_groups           = []
      custom_stateless_groups          = []
      tls_inspection_configuration_arn = module.tls_inspection.tls_inspection_configuration_arn
    }
  }
}
```

## Tenants, certificates and scopes

- Each tenant in `tenants` gets one ACM certificate. `domains[0]` is the primary name and any further entries become alternative names.
- A wildcard covers exactly one label. `*.acme.np.core.homeoffice.gov.uk` covers `app1.acme.np.core.homeoffice.gov.uk` but not `x.app1.acme.np.core.homeoffice.gov.uk`, and not the apex `acme.np.core.homeoffice.gov.uk`. List the apex as a second domain if it is needed.
- Each tenant's `destinations` become that tenant's scope. By default the scope is TCP, destination port 443, any source and source port.
- Network Firewall allows at most 10 server certificates per configuration, so at most 10 tenants.
- With `validation_zone_id` set, the module creates the validation CNAMEs in that Route 53 zone, which must be in the same account. Without it, create the records from the `certificate_validation_records` output wherever the zone is hosted. Terraform waits up to `certificate_validation_timeout` for each certificate to be issued before it creates the configuration, so the records must exist first.
- To change a tenant's names, change `domains`. ACM cannot change a certificate's names in place, so this replaces the certificate and needs new validation records.

> [!IMPORTANT]
> The AWS provider allows only one server certificate configuration per TLS inspection configuration, so every tenant's certificates and scopes share it. AWS picks a certificate by the client's SNI and does not tie a certificate to a particular tenant's scope. Keeping a tenant's names and CIDRs together in `tenants` is a convention, not something AWS enforces.

> [!NOTE]
> `core-cloud-acm-tf-module` is not used because every released tag requires AWS provider `~> 6.66`, and this stack runs on provider 5.x.

## Attaching to a policy

AWS does not allow adding a TLS inspection configuration to an existing firewall policy, or removing one. It can only be set when a policy is created, or replaced with another configuration. So attach it to a **new** policy version (`tls_inspection_configuration_arn` on the version), then switch `active_policy_version` to it. Tenants can be added or changed afterwards by updating this module's configuration in place.

## Behaviour to know about

- Traffic that matches a scope but is not TLS (for example plain HTTP on a scoped port) is dropped, as is TLS with no SNI or an SNI that does not match any certificate.
- Adding or widening a scope interrupts existing flows that match it.
- TLS 1.0 and SSLv3 are not supported for in-scope traffic.
- The AWS API only supports TCP (protocol 6).

## Inputs

| Name | Description | Default |
|---|---|---|
| `name` | Name of the TLS inspection configuration | required |
| `description` | Description | `"TLS inspection configuration"` |
| `tenants` | Map of tenant key to `domains` and `destinations`, with optional `sources`, `source_ports`, `destination_ports` and `protocols`. 1 to 10 tenants | required |
| `validation_zone_id` | Route 53 zone for the DNS validation records, or null | `null` |
| `certificate_validation_timeout` | Time to wait for each certificate to be issued | `"30m"` |
| `kms_key_arn` | Customer managed KMS key, or null for an AWS owned key | `null` |
| `tags` | Tags for the certificates and configuration | `{}` |

## Outputs

| Name | Description |
|---|---|
| `tls_inspection_configuration_arn` | ARN to set on a policy version |
| `server_certificate_arns` | Certificate ARN for each tenant |
| `certificate_validation_records` | DNS validation records for each tenant's certificate |
