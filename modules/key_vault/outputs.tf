output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_id" {
  description = "Versioned Resource Manager ID of the JWT signing secret."
  value       = azurerm_key_vault_secret.jwt_signing.id
}

output "secret_versionless_id" {
  description = "Versionless secret URI. Survives secret rotation."
  value       = azurerm_key_vault_secret.jwt_signing.versionless_id
}

output "secret_name" {
  value = azurerm_key_vault_secret.jwt_signing.name
}

output "secret_resource_id" {
  description = "Versionless Resource Manager ID of the secret — use for least-privilege role scope. Versionless so the role assignment survives rotation."
  value       = azurerm_key_vault_secret.jwt_signing.resource_versionless_id
}
