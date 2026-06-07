# Adopt resources that were created by a previous failed apply but were not
# recorded in this Terraform state.
import {
  to = module.aca_env.azurerm_container_app_environment.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.App/managedEnvironments/${local.names.aca_env}"
}

import {
  to = module.acr.azurerm_container_registry.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${local.names.acr}"
}

import {
  to = module.cosmos.azurerm_cosmosdb_account.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${local.names.cosmos}"
}

import {
  to = module.event_hub.azurerm_eventhub_namespace.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.EventHub/namespaces/${local.names.event_hub_ns}"
}

import {
  to = module.mi_ingest.azurerm_user_assigned_identity.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.names.mi_ingest}"
}

import {
  to = module.mi_auth.azurerm_user_assigned_identity.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.names.mi_auth}"
}

import {
  to = module.mi_report.azurerm_user_assigned_identity.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.names.mi_report}"
}

import {
  to = module.mi_monitoring.azurerm_user_assigned_identity.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.names.mi_monitoring}"
}

import {
  to = module.key_vault.azurerm_key_vault.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.KeyVault/vaults/${local.names.key_vault}"
}

import {
  to = module.storage.azurerm_storage_account.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.names.storage}"
}
