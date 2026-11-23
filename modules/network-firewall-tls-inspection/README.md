# network-firewall-tls-inspection

Creates an AWS Network Firewall TLS inspection configuration for **inbound** inspection, together with the public ACM server certificates it needs. Attach the result to a firewall policy through the policy module's `tls_inspection_configuration_arn` input.

Nothing is decrypted until traffic matches a scope. To keep inspection off for every tenant, give the module a single scope whose destination matches nothing (for example `192.0.2.0/32`) and add tenant CIDRs as tenants ask for inspection.

## Usage

```hcl
module "tls_inspection" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-firewall-terraform.git//modules/network-firewall-tls-inspection?ref=<tag>"

  name                = "cc-inspection-notprod-tls"
  certificate_domains = ["*.app.tenant.np.core.homeoffice.gov.uk"]
  validation_zone_id  = null # DNS validation records are created elsewhere

  scopes = [
    {
      name         = "placeholder-no-tenants"
      destinations = ["192.0.2.0/32"]
    },
  ]
}

module "policy" {
  # ...
  tls_inspection_configuration_arn = module.tls_inspection.tls_inspection_configuration_arn
}
```

## Certificates

- One public ACM certificate is requested per entry in `certificate_domains`, validated by DNS.
- A wildcard such as `*.app.tenant.np.core.homeoffice.gov.uk` covers exactly one extra label, so `<tenant>.app.tenant.np.core.homeoffice.gov.uk` is covered but `www.<tenant>.app.tenant.np.core.homeoffice.gov.uk` is not.
- Network Firewall allows at most 10 server certificates per configuration and one TLS inspection configuration per policy, so prefer wildcards over one certificate per tenant.
- With `validation_zone_id` set, the module creates the validation CNAMEs in that Route 53 zone. Without it, create the records from the `certificate_validation_records` output wherever the zone is hosted. Terraform waits up to `certificate_validation_timeout` for the certificate to be issued before it creates the configuration.
- Existing issued certificates can be passed in `existing_server_certificate_arns`.

> [!NOTE]
> `core-cloud-acm-tf-module` is not used because every released tag requires AWS provider `~> 6.66`, and this stack runs on provider 5.x.

## Behaviour to know about

- Traffic that matches a scope but is not TLS (for example plain HTTP on a scoped port) is dropped, as is TLS with no SNI or an SNI that does not match the certificate.
- Adding or widening a scope interrupts existing flows that match it.
- TLS 1.0 and SSLv3 are not supported for in-scope traffic.
- The AWS API only supports TCP (protocol 6).

## Inputs

| Name | Description | Default |
|---|---|---|
| `name` | Name of the TLS inspection configuration | required |
| `description` | Description | `"TLS inspection configuration"` |
| `scopes` | Traffic to decrypt. Each scope has `destinations` (required), `sources`, `source_ports`, `destination_ports` and `protocols` | required |
| `certificate_domains` | Domains to request public ACM certificates for | `[]` |
| `existing_server_certificate_arns` | Issued ACM certificates to use as well | `[]` |
| `validation_zone_id` | Route 53 zone for the DNS validation records, or null | `null` |
| `certificate_validation_timeout` | Time to wait for each certificate to be issued | `"30m"` |
| `kms_key_arn` | Customer managed KMS key, or null for an AWS owned key | `null` |
| `tags` | Tags for the certificates and configuration | `{}` |

## Outputs

| Name | Description |
|---|---|
| `tls_inspection_configuration_arn` | ARN to pass to the firewall policy module |
| `server_certificate_arns` | ARNs of every server certificate in use |
| `certificate_validation_records` | DNS validation records per requested domain |
