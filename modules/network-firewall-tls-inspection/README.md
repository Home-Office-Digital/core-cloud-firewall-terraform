# network-firewall-tls-inspection

Creates an AWS Network Firewall TLS inspection configuration for **inbound** inspection. You choose which names go on which ACM certificate, and which certificate serves each tenant. The module requests the certificates; validating them is done outside the module. Attach the result through the `tls_inspection_configuration_arn` attribute of a **new** policy version in the inspection policy module.

Nothing is decrypted until traffic matches a scope, and the configuration is only created once at least one tenant's certificate is validated.

## Usage

```hcl
module "tls_inspection" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-firewall-terraform.git//modules/network-firewall-tls-inspection?ref=<tag>"

  name = "cc-inspection-notprod-tls-inspection"

  certificates = {
    cert-1 = {
      domains   = ["*.fw-test-1.np.core.homeoffice.gov.uk"]
      validated = true # its CNAME is in place and ACM shows ISSUED
    }
    batch-1 = {
      domains = ["*.acme.np.core.homeoffice.gov.uk", "*.globex.np.core.homeoffice.gov.uk"]
      # validated defaults to false: requested, not used yet
    }
  }

  tenants = {
    fw-test-1 = { certificate = "cert-1", destinations = ["192.0.2.0/32"] }
    acme      = { certificate = "batch-1", destinations = ["10.111.20.0/24"] }
    globex    = { certificate = "batch-1", destinations = ["10.111.30.0/24"] }
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

## Certificates and names

- Each entry in `certificates` is one ACM certificate. `domains[0]` is the primary name and the rest are alternative names.
- **Slots:** a configuration holds at most 10 server certificates. Only validated certificates that at least one tenant uses take a slot.
- **Names:** ACM allows 10 names per certificate by default, up to 100 with a raised quota. Several tenants can share one certificate by listing their names on it and pointing at it.
- A wildcard covers exactly one label. `*.acme.np.core.homeoffice.gov.uk` covers `app1.acme.np.core.homeoffice.gov.uk` but not `x.app1.acme.np.core.homeoffice.gov.uk`, and not the apex `acme.np.core.homeoffice.gov.uk`.
- One certificate per tenant is enough for both directions. The firewall terminates the client's TLS with it, inspects, then opens its own TLS connection to the server.

## Tenants and scopes

- Each tenant points at a certificate key with `certificate`, and becomes one scope (`destinations`, default TCP 443 from anywhere) once that certificate is validated.
- A tenant pointing at a key that does not exist fails the plan.

> [!IMPORTANT]
> The AWS provider allows only one server certificate configuration per TLS inspection configuration, so every included certificate and scope share it. AWS picks a certificate by the client's SNI and does not tie a certificate to a particular tenant's scope. The `certificate` link is a convention, not something AWS enforces.

> [!NOTE]
> `core-cloud-acm-tf-module` is not used because every released tag requires AWS provider `~> 6.66`, and this stack runs on provider 5.x.

## Validating a certificate

The module requests the certificate and does not wait for it.

1. Add the certificate with `validated` left as `false`, and apply. It is created as `PENDING_VALIDATION`.
2. Create the CNAMEs from the `certificate_validation_records` output in the public zone for each name, wherever it is hosted.
3. When ACM shows `ISSUED` (see `certificate_status`), set `validated = true` and apply. Tenants using it are added to the configuration, which is created on the first such apply.

A certificate set to `true` but not `ISSUED` fails the apply with a message naming it, and the configuration is not changed.

## Changing the names on a certificate

ACM cannot change a certificate's names, so changing `domains` replaces the certificate. For a certificate in use:

1. Add a **new key** (for example `batch-1-v2`) with the new list of names and `validated = false`. Apply. The firewall keeps using the old certificate.
2. Validate it. ACM reuses the validation CNAME for a name it has already validated in the same account, so usually only new names need new CNAMEs.
3. Set `validated = true` on the new key and point the tenants at it. Apply. The configuration is updated in place.
4. Remove the old key. Apply.

If you edit `domains` on a certificate in use instead, the replacement is created but not issued, so the apply stops before the configuration changes and traffic keeps using the old certificate. Validate the replacement and apply again.

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
| `certificates` | Map of certificate key to `domains` (1 to 100) and optional `validated` (default `false`) | required |
| `tenants` | Map of tenant key to `certificate` (a certificate key) and `destinations`, with optional `sources`, `source_ports`, `destination_ports` and `protocols` | required |
| `kms_key_arn` | Customer managed KMS key, or null for an AWS owned key | `null` |
| `tags` | Tags for the certificates and configuration | `{}` |

## Outputs

| Name | Description |
|---|---|
| `tls_inspection_configuration_arn` | ARN to set on a policy version. Null until a tenant's certificate is validated |
| `certificate_arns` | ARN of each certificate |
| `certificate_status` | ACM status of each certificate |
| `certificate_validation_records` | DNS validation CNAMEs for each certificate |
| `tenants_in_configuration` | Tenants whose scope is in the configuration, with their certificate |
