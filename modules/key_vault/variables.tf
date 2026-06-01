variable "name" {
  type        = string
  description = "Key Vault name (3-24 chars, globally unique)."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "standard or premium. Standard is the cheapest; Premium adds HSM."
}

variable "secret_name" {
  type        = string
  default     = "auth-jwt-signing-key"
  description = "Name of the PKCS#8 PEM-encoded RSA private key secret stored in the vault. The auth-service reads this via SecretClient and derives the matching public key for JWKS."
}

variable "tags" {
  type    = map(string)
  default = {}
}
