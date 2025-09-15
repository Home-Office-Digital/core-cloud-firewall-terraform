## Example Usage

### Domain Allow/Block List
```
module "domain_allow" {
  source = "git::https://github.com/UKHomeOffice/core-cloud-network-firewall-rulegroup-tf-module.git//stateful?ref=main"

  name               = "example-domain-allowlist"
  description        = "List of domains that are allowed"
  capacity           = 100
  domain_rule_type   = "ALLOWLIST"
  domain_target_type = ["HTTP_HOST", "TLS_SNI"]
  domain_targets     = [
    "example.com",
    "contoso.org"
  ]
}
```

### Standard Stateful Rule
```
module "stateful_rule" {
  source = "git::https://github.com/UKHomeOffice/core-cloud-network-firewall-rulegroup-tf-module.git//stateful?ref=main"

  name               = "example-stateful-rules"
  description        = "Example Stateful Rules"
  capacity           = 100
  stateful_rules     = {
    rule1 = {
      sid             = 12345
      action          = "PASS"
      source          = "127.0.0.1/32"
      sourcePort      = 443
      destination     = "127.0.0.2/32"
      destinationPort = 443
      protocol        = "TCP"
      direction       = "ANY"
    }
    rule2 = {
      sid             = 12346
      action          = "PASS"
      source          = "127.0.0.1/32"
      sourcePort      = 8443
      destination     = "127.0.0.2/32"
      destinationPort = 8443
      protocol        = "TCP"
      direction       = "ANY"
      ruleOptions     = {
        option1 = {
          keyword  = "msg"
          settings = [ "\"this is a stateful drop rule\"" ]
        }
        option2 = {
          keyword  = "noalert"
        }
      }
    }
  }
}
```
#### Note about SIDs
SIDs should be defined for each rule. However, if none is defined than once is calculated based on the hash of the rule

#### Rule Options
Rules may have one or many options and these generally are the same ones used in a suricata rule. Settings is always expressed as a list. Strings must also be double quoted when used in settings

### Suricata Styled Rules
```
module "suricata_rule" {
  source = "git::https://github.com/UKHomeOffice/core-cloud-network-firewall-rulegroup-tf-module.git//stateful?ref=main"

  name                     = "example-suricata-rules"
  description              = "Example Suricata Rules"
  capacity                 = 100
  rule_variables           = {
    ipSets = {
      variable1 = {
        key    = "EXAMPLE_HOST"
        values = [ "127.0.0.1/32" ]
      }
      variable2 = {
        key    = "EXAMPLE_DESTINATION"
        values = [ "127.0.0.2/32" ]
      }
    }
    portSets = {
      variable1 = {
        key   = "EXAMPLE_PORTS"
        value = "8443"
      }
    }
  }
  suricata_rules = <<EOT
    alert ip $EXAMPLE_HOST any -> $EXAMPLE_DESTINATION $EXAMPLE_PORTS (flow:to_server; msg:"Allow HTTP"; sid:123456; rev:1;)
    pass ip $EXAMPLE_HOST any -> $EXAMPLE_DESTINATION $EXAMPLE_PORTS (flow:to_server; msg:"pass rule no logging"; sid:123457; rev:1;)
  EOT

}
```

#### Suricata Variables
You can defined variables that help for re-use in the case where you're loading in suricata rules from a file or s3 bucket. You may only define IP Sets and Port Sets as outlined (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group#rule-variables)

#### Suricata Rules
You may defined these inline using EOT/Heredocs notation or express a string that points to a file containing a list of rules. Alternatively that String also be a fully qualified name of a file in an S3 bucket

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
| <a name="input_description"></a> [description](#input\_description) | Description of firewall group rule | `string` | n/a | yes |
| <a name="input_domain_rule_type"></a> [domain\_rule\_type](#input\_domain\_rule\_type) | Configuration of domain based firewall rule | `string` | `""` | no |
| <a name="input_domain_target_type"></a> [domain\_target\_type](#input\_domain\_target\_type) | The type of domains used in the firewall rule | `list(string)` | `[]` | no |
| <a name="input_domain_targets"></a> [domain\_targets](#input\_domain\_targets) | The actual list of domains to allow or block | `list(string)` | `[]` | no |
| <a name="input_encryption_configuration"></a> [encryption\_configuration](#input\_encryption\_configuration) | Encryption configuration of firewall rules | `map(any)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the firewall group rule | `string` | n/a | yes |
| <a name="input_rule_variables"></a> [rule\_variables](#input\_rule\_variables) | Configuration of firewall rule variables | `map(any)` | `{}` | no |
| <a name="input_stateful_rule_order"></a> [stateful\_rule\_order](#input\_stateful\_rule\_order) | Specify the process order of rules in the rule group | `string` | `""` | no |
| <a name="input_stateful_rules"></a> [stateful\_rules](#input\_stateful\_rules) | Configuration of standard stateful firewall rules | `any` | `{}` | no |
| <a name="input_suricata_rules"></a> [suricata\_rules](#input\_suricata\_rules) | Configuration of suricata firewall rules | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_networkfirewall_rule_group_arn"></a> [aws\_networkfirewall\_rule\_group\_arn](#output\_aws\_networkfirewall\_rule\_group\_arn) | The arn of the network firewall rulegroup that is created |
<!-- END_TF_DOCS -->