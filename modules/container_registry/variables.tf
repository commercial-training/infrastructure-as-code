variable "name" {
  type        = string
  description = "ACR name (5-50 alphanumeric, globally unique)."
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
  description = "Basic is the cheapest SKU."
}

variable "tags" {
  type    = map(string)
  default = {}
}
