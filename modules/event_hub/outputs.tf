output "namespace_id" {
  value = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  value = azurerm_eventhub_namespace.this.name
}

output "namespace_fqdn" {
  description = "Fully-qualified host used by AMQP/Kafka clients."
  value       = "${azurerm_eventhub_namespace.this.name}.servicebus.windows.net"
}

output "hub_id" {
  value = azurerm_eventhub.this.id
}

output "hub_name" {
  value = azurerm_eventhub.this.name
}

# output "consumer_group_name" {
#   value = azurerm_eventhub_consumer_group.ingest.name
# }

output "partition_count" {
  description = "Number of partitions on the hub. Caps the parallelism of any consumer group — useful as the data-ingest-service KEDA max_replicas."
  value       = azurerm_eventhub.this.partition_count
}
