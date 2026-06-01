variable "location" {
  type        = string
  description = "Azure region for the state backend resources."
  default     = "southeastasia"
}

variable "state_resource_group_name" {
  type        = string
  description = "Resource group for the Terraform state backend."
  default     = "rg-commercial-trainning-tfstate"
}

variable "state_container_name" {
  type        = string
  description = "Blob container name that holds the state files."
  default     = "tfstate"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Training"
    ManagedBy   = "Terraform"
    Purpose     = "TerraformStateBackend"
  }
}
