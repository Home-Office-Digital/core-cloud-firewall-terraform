# network-firewall-tls-inspection

Creates an AWS Network Firewall TLS inspection configuration for **inbound** inspection, with one public ACM server certificate and one scope per tenant. The module requests the certificates; validating them is done outside the module. Attach the result through the `tls_inspection_configuration_arn` attribute of a **new** policy version in the inspection policy module.

Nothing is decrypted until traffic matches a scope. A tenant that is set up but not live uses a destination that matches nothing, for example `192.0.2.0/32`. The configuration is only created once at least one tenant's certificate is validated (`certificate_validated = true`).

## Usage

```hcl
module "tls_inspection" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-firewall-terraform.git//modules/network-firewall-tls-inspection?ref=<tag>"

  name = "cc-inspection-notprod-tls-inspection"

  tenants = {
    fw-test-1 = {
      domains               = ["*.fw-test.np.core.homeoffice.gov.uk"]
      destinations          = ["192.0.2.0/32"] # matches nothing
      certificate_validated = true            # its CNAME is in place and ACM shows ISSUED
    }
    acme = {
      domains      = ["*.acme.np.core.homeoffice.gov.uk"]
      destinations = ["10.111.20.0/24"]
      # certificate_validated defaults to false: certificate requested, not in the configuration yet
    }
  }
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
- One certificate per tenant is enough. The firewall terminates the client's TLS with it, inspects, then opens its own TLS connection to the server.
- Each tenant's `destinations` become that tenant's scope. By default the scope is TCP, destination port 443, any source and source port.
- Network Firewall allows at most 10 server certificates per configuration, so at most 10 tenants.

## Validating a certificate

The module requests the certificate and does not wait for it. For each tenant:

1. Apply with the tenant added (`certificate_validated` left as `false`). The certificate is created as `PENDING_VALIDATION`.
2. Create the CNAME from the `certificate_validation_records` output in the tenant's public zone, wherever it is hosted.
3. When ACM shows the certificate as `ISSUED` (see the `certificate_status` output), set `certificate_validated = true` and apply. The tenant's certificate and scope are added to the configuration, which is created on the first such apply.

A tenant set to `true` whose certificate is not `ISSUED` fails the plan or apply with a message naming it, so a pending certificate is never handed to the firewall.

Changing a tenant's `domains` replaces its certificate, and the new one starts as `PENDING_VALIDATION`. Set the tenant back to `false` first, validate the new certificate, then set it to `true` again.

> [!IMPORTANT]
> The AWS provider allows only one server certificate configuration per TLS inspection configuration, so every tenant's certificates and scopes share it. AWS picks a certificate by the client's SNI and does not tie a certificate to a particular tenant's scope. Keeping a tenant's names and CIDRs together in `tenants` is a convention, not something AWS enforces.

> [!NOTE]
> `core-cloud-acm-tf-module` is not used because every released tag requires AWS provider `~> 6.66`, and this stack runs on provider 5.x.

## Attaching to a policy

AWS does not allow adding a TLS inspection configuration to an existing firewall policy, or removing one. It can only be set when a policy is created, or replaced with another configuration. So attach it to a **new** policy version (`tls_inspection_configuration_arn` on the version), then switch `active_policy_version` to it. Tenants can be added or changed afterwards by updating this module's configuration in place. Because the configuration only exists once a tenant is validated, create the new policy version only after that.

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
| `tenants` | Map of tenant key to `domains` and `destinations`, with optional `certificate_validated` (default `false`), `sources`, `source_ports`, `destination_ports` and `protocols`. 1 to 10 tenants | required |
| `kms_key_arn` | Customer managed KMS key, or null for an AWS owned key | `null` |
| `tags` | Tags for the certificates and configuration | `{}` |

## Outputs

| Name | Description |
|---|---|
| `tls_inspection_configuration_arn` | ARN to set on a policy version. Null until a tenant is validated |
| `server_certificate_arns` | Certificate ARN for each tenant |
| `certificate_status` | ACM status of each tenant's certificate |
| `certificate_validation_records` | DNS validation CNAMEs for each tenant's certificate |
