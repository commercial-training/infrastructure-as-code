resource "azurerm_eventhub_namespace" "this" {
  name                          = var.namespace_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  capacity                      = 1
  auto_inflate_enabled          = false
  public_network_access_enabled = true
  minimum_tls_version           = "1.2"
  local_authentication_enabled  = false # force AAD/MI;
  tags                          = var.tags
}

resource "azurerm_eventhub" "this" {
  name              = var.hub_name
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = var.partition_count
  message_retention = var.message_retention_days
}

# Create custom consumer group
# resource "azurerm_eventhub_consumer_group" "ingest" {
#   name                = var.consumer_group_name
#   namespace_name      = azurerm_eventhub_namespace.this.name
#   eventhub_name       = azurerm_eventhub.this.name
#   resource_group_name = var.resource_group_name
# }
