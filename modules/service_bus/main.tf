resource "azurerm_servicebus_namespace" "this" {
  name                          = var.namespace_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : 0
  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_servicebus_queue" "this" {
  name         = var.queue_name
  namespace_id = azurerm_servicebus_namespace.this.id

  batched_operations_enabled              = true
  dead_lettering_on_message_expiration    = true
  default_message_ttl                     = var.default_message_ttl
  duplicate_detection_history_time_window = var.duplicate_detection_history_time_window
  lock_duration                           = var.lock_duration
  max_delivery_count                      = var.max_delivery_count
  partitioning_enabled                    = var.partitioning_enabled
  requires_duplicate_detection            = var.requires_duplicate_detection
  requires_session                        = false
}
