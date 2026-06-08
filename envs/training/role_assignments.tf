# -----------------------------------------------------------------------------
# Role assignments — least privilege per managed identity.
#
# Kept in a separate file from main.tf so the wiring is easy to audit. Every
# role here is scoped as tightly as possible (per-container for Storage, per-
# hub for Event Hubs, per-secret for Key Vault) rather than at account/vault
# level.
# -----------------------------------------------------------------------------

# Cosmos DB built-in data-plane role IDs (documented constants):
#   00000000-0000-0000-0000-000000000001 = Cosmos DB Built-in Data Reader
#   00000000-0000-0000-0000-000000000002 = Cosmos DB Built-in Data Contributor
locals {
  cosmos_data_contributor_role_id = "00000000-0000-0000-0000-000000000002"
}

# -----------------------------------------------------------------------------
# ACR pull — all three Container Apps need it to pull images via MI.
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "acr_pull_auth" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.mi_auth.principal_id
}

resource "azurerm_role_assignment" "acr_pull_report" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.mi_report.principal_id
}

resource "azurerm_role_assignment" "acr_pull_ingest" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.mi_ingest.principal_id
}

# -----------------------------------------------------------------------------
# auth-service — read the PKCS#8 PEM private key from Key Vault as a secret
# (the Java app uses SecretClient, not CryptographyClient — signing happens
# in-process). Scope = the single secret, not the whole vault.
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "acr_pull_monitoring" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.mi_monitoring.principal_id
}

resource "azurerm_role_assignment" "azure_monitor_reader_monitoring" {
  scope                = module.event_hub.namespace_id
  role_definition_name = "Reader"
  principal_id         = module.mi_monitoring.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_auth" {
  scope                = module.key_vault.secret_resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.mi_auth.principal_id
}

# -----------------------------------------------------------------------------
# report-service — write blob payloads, publish events.
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "blob_writer_report" {
  scope                = module.storage.data_container_resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.mi_report.principal_id
}

resource "azurerm_role_assignment" "evh_sender_report" {
  scope                = module.event_hub.hub_id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = module.mi_report.principal_id
}

resource "azurerm_role_assignment" "sb_sender_report" {
  scope                = module.service_bus.queue_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.mi_report.principal_id
}

# -----------------------------------------------------------------------------
# data-ingest-service — consume events, persist checkpoints, write Cosmos records.
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "evh_receiver_ingest" {
  scope                = module.event_hub.hub_id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = module.mi_ingest.principal_id
}

resource "azurerm_role_assignment" "sb_receiver_ingest" {
  scope                = module.service_bus.queue_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = module.mi_ingest.principal_id
}

# Needed by BOTH:
#   1. BlobCheckpointStore inside the app (writes consumer offsets).
#   2. The KEDA azure-eventhub scaler attached to the container app (reads the
#      same offsets to compute lag and drive scale-to-zero / scale-up).
# Scoped to the eh-checkpoints container only — not the whole storage account.
resource "azurerm_role_assignment" "blob_checkpoint_ingest" {
  scope                = module.storage.checkpoint_container_resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.mi_ingest.principal_id
}

# Cosmos DB data-plane RBAC is a separate resource type from ARM RBAC — it
# targets the Cosmos account (or a specific database/container path).
resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_writer_ingest" {
  resource_group_name = module.rg.name
  account_name        = module.cosmos.account_name
  role_definition_id  = "${module.cosmos.account_id}/sqlRoleDefinitions/${local.cosmos_data_contributor_role_id}"
  principal_id        = module.mi_ingest.principal_id
  scope               = module.cosmos.account_id
}
