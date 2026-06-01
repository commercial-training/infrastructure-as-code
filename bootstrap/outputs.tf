output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Resource group holding the state backend."
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Storage account name. Use it in the backend block of every environment."
}

output "container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "Container name for state blobs."
}

output "backend_config_hint" {
  value = <<-EOT
    Paste these into envs/<env>/backend.tf:

    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.tfstate.name}"
      storage_account_name = "${azurerm_storage_account.tfstate.name}"
      container_name       = "${azurerm_storage_container.tfstate.name}"
      key                  = "<env>.tfstate"
      use_azuread_auth     = true
    }
  EOT
}
