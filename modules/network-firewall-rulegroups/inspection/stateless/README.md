## Example Usage
```
module "stateless_example" {
  source = "git::https://github.com/UKHomeOffice/core-cloud-network-firewall-rulegroup-tf-module.git//statelessref=main"

  name               = "example-stateless-rules"
  description        = "Example stateless rules"
  capacity           = 100
  custom_actions     = {
    action1 = {
      dimensions = [ 1 ] 
    }
    action2 = {
      dimensions = [ 2 ] 
    }
  }
  stateless_rules    = {
    rule1 = {
      priority = 1
      action = [ "aws:pass" ]
      source = [
        "127.0.0.1/32",
        "127.0.0.2/32"
      ]
      sourcePorts = {
        range1 = {
          from = "443"
          to   = "443"
        }
        range2 = {
          from = "8443"
          to   = "8443"
        }
      }
      destination = [
        "127.0.0.3/32"
      ]
      destinationPorts = {
        range1 = {
          from = "443"
          to   = "443"
        }
        range2 = {
          from = "8443"
          to   = "8443"
        }
      }
      protocols: [ 6 ]
      tcp = {
        flags = [
          "SYN"
        ]
        masks = [
          "SYN",
          "ACK
        ]
      }
    }
    rule2 = {
      priority = 2
      action = [ "aws:pass" ]
      source = [
        "127.0.0.1/32"
      ]
      sourcePorts = {
        range1 = {
          from = "8080"
          to   = "8080"
        }
      }
      destination = [
        "127.0.0.2/32"
      ]
      destinationPorts = {
        range1 = {
          from = "8080"
          to   = "8080"
        }
      }
      protocols: [ 17 ]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_networkfirewall_rule_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Capacity of the network firewall group rule | `number` | n/a | yes |
| <a name="input_custom_actions"></a> [custom\_actions](#input\_custom\_actions) | Configuration of Custom Actions - mainly just custom cloudwatch metics (dimensions) at this time | `map(any)` | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of firewall group rule | `string` | n/a | yes |
| <a name="input_encryption_configuration"></a> [encryption\_configuration](#input\_encryption\_configuration) | Encryption configuration of firewall rules | `map(any)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of firewall group rule | `string` | n/a | yes |
| <a name="input_stateless_rules"></a> [stateless\_rules](#input\_stateless\_rules) | Configuration of Stateless firewall rules | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_networkfirewall_rule_group_arn"></a> [aws\_networkfirewall\_rule\_group\_arn](#output\_aws\_networkfirewall\_rule\_group\_arn) | The arn of the network firewall rulegroup that is created |
<!-- END_TF_DOCS -->