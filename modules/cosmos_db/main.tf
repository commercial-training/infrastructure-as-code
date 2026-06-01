resource "azurerm_cosmosdb_account" "this" {
  name                = var.account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  free_tier_enabled = var.enable_free_tier

  # Force AAD; disable local primary/secondary key auth entirely.
  local_authentication_disabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  public_network_access_enabled = true

  tags = var.tags
}

# Database-level shared throughput. Free tier covers 1000 RU/s on the first
# database in the account.
resource "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = var.database_throughput
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                  = var.container_name
  resource_group_name   = azurerm_cosmosdb_account.this.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths   = [var.partition_key_path]
  partition_key_version = 2
}
