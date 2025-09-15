variable "name" {
  description = "Name of firewall group rule"
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

variable "stateless_rules" {
  description = "Configuration of Stateless firewall rules"
  type        = any
}

variable "custom_actions" {
  description = "Configuration of Custom Actions - mainly just custom cloudwatch metrics (dimensions) at this time"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Resource Tags"
  type        = map(string)
  default     = {}
}
