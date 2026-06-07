variable "namespace_name" {
  type        = string
  description = "Event Hubs namespace (6-50 chars, globally unique)."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type        = string
  default     = "Basic"
  description = "Basic is cheaper but disallows custom consumer groups; Standard is required for the ingest CG."
}

variable "hub_name" {
  type    = string
  default = "data-events"
}

variable "partition_count" {
  type    = number
  default = 2
}

variable "message_retention_days" {
  type    = number
  default = 1
}

# variable "consumer_group_name" {
#   type    = string
#   default = "data-ingest-cg"
# }

variable "tags" {
  type    = map(string)
  default = {}
}
