data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  public_network_access_enabled     = true
  infrastructure_encryption_enabled = true
  tags                              = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# Grant the deploying principal Storage Blob Data Owner so the containers below
# can be created via AAD auth. Subscription-level Owner/Contributor is NOT
# enough — data-plane RBAC is separate.
resource "azurerm_role_assignment" "deployer_blob_data_owner" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "data" {
  name                  = var.data_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.deployer_blob_data_owner]
}

# Pre-created so the BlobCheckpointStore (and the KEDA azure-eventhub scaler)
# can use container-scoped RBAC for least privilege, rather than needing
# account-level perms to auto-create the container at runtime.
resource "azurerm_storage_container" "checkpoint" {
  name                  = var.checkpoint_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.deployer_blob_data_owner]
}
