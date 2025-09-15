variable "name" {
  description = "Name of the firewall group rule"
  type        = string
}

variable "description" {
  description = "Description of firewall group rule"
  type        = string
}

variable "capacity" {
  description = "Capacity of the network firewall group rule"
  type        = number
}

variable "encryption_configuration" {
  description = "Encryption configuration of firewall rules"
  type        = map(any)
  default     = {}
}

variable "stateful_rules" {
  description = "Configuration of standard stateful firewall rules"
  type        = any
  default     = {}
}

variable "rule_variables" {
  description = "Configuration of firewall rule variables"
  type        = map(any)
  default     = {}
}

variable "suricata_rules" {
  description = "Configuration of suricata firewall rules"
  type        = string
  default     = ""
}

variable "domain_rule_type" {
  description = "Configuration of domain based firewall rule"
  type        = string
  default     = ""
}

variable "domain_target_type" {
  description = "The type of domains used in the firewall rule"
  type        = list(string)
  default     = []
}

variable "domain_targets" {
  description = "The actual list of domains to allow or block"
  type        = list(string)
  default     = []
}

variable "stateful_rule_order" {
  description = "Specify the process order of rules in the rule group"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource Tags"
  type        = map(string)
  default     = {}
}
