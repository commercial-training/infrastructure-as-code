output "namespace_fqdn" {
  description = "Fully qualified Service Bus namespace host used by AMQP clients."
  value       = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net"
}

output "namespace_id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.name
}

output "queue_id" {
  description = "Resource ID of the Service Bus queue."
  value       = azurerm_servicebus_queue.this.id
}

output "queue_name" {
  description = "Name of the Service Bus queue."
  value       = azurerm_servicebus_queue.this.name
}
