variable "account_name" {
  type        = string
  description = "Cosmos DB account name (3-44 lowercase alphanumeric/hyphen, globally unique)."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "database_name" {
  type    = string
  default = "reporting"
}

variable "container_name" {
  type    = string
  default = "records"
}

variable "partition_key_path" {
  type    = string
  default = "/key"
}

variable "enable_free_tier" {
  type        = bool
  default     = true
  description = "Set to false if the subscription has already used its free-tier quota on another account."
}

variable "database_throughput" {
  type        = number
  default     = 1000
  description = "Provisioned RU/s at the database level. Free tier covers up to 1000 RU/s."
}

variable "tags" {
  type    = map(string)
  default = {}
}
