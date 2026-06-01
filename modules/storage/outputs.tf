output "id" {
  value = azurerm_storage_account.this.id
}

output "name" {
  value = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "data_container_name" {
  value = azurerm_storage_container.data.name
}

output "data_container_resource_manager_id" {
  description = "Resource Manager ID of the data blob container — use for RBAC role scope."
  value       = azurerm_storage_container.data.id
}

output "checkpoint_container_name" {
  value = azurerm_storage_container.checkpoint.name
}

output "checkpoint_container_resource_manager_id" {
  description = "Resource Manager ID of the Event Hubs checkpoint container — use for RBAC role scope."
  value       = azurerm_storage_container.checkpoint.id
}
