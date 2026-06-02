output "id" {
  value = azurerm_container_app.this.id
}

output "name" {
  value = azurerm_container_app.this.name
}

output "fqdn" {
  description = "Public/internal FQDN assigned by the ACA environment"
  value       = try(replace(azurerm_container_app.this.latest_revision_fqdn, "/--[^.]+\\./", "."), null)
}

output "latest_revision_name" {
  value = azurerm_container_app.this.latest_revision_name
}
