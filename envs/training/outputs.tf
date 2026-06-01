output "resource_group_name" {
  value = module.rg.name
}

output "acr_login_server" {
  description = "Use this as the base for docker push, e.g. <login_server>/auth-service:0.1.0."
  value       = module.acr.login_server
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "key_vault_signing_secret_name" {
  description = "Name of the PKCS#8 PEM secret holding the JWT signing private key."
  value       = module.key_vault.secret_name
}

output "storage_account_name" {
  value = module.storage.name
}

output "storage_data_container" {
  value = module.storage.data_container_name
}

output "storage_checkpoint_container" {
  value = module.storage.checkpoint_container_name
}

output "event_hub_namespace_fqdn" {
  value = module.event_hub.namespace_fqdn
}

output "event_hub_name" {
  value = module.event_hub.hub_name
}

output "event_hub_consumer_group" {
  value = module.event_hub.consumer_group_name
}

output "cosmos_endpoint" {
  value = module.cosmos.endpoint
}

output "cosmos_database" {
  value = module.cosmos.database_name
}

output "cosmos_container" {
  value = module.cosmos.container_name
}

output "auth_service_fqdn" {
  value = module.ca_auth.fqdn
}

output "report_service_fqdn" {
  value = module.ca_report.fqdn
}

output "prometheus_fqdn" {
  value = module.ca_prometheus.fqdn
}

output "loki_fqdn" {
  value = module.ca_loki.fqdn
}

output "grafana_fqdn" {
  value = module.ca_grafana.fqdn
}

output "grafana_admin_user" {
  value = var.grafana_admin_user
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin.result
  sensitive = true
}

output "managed_identity_client_ids" {
  description = "Client IDs to set as AZURE_CLIENT_ID in each service for DefaultAzureCredential / WorkloadIdentityCredential."
  value = {
    auth_service        = module.mi_auth.client_id
    report_service      = module.mi_report.client_id
    data_ingest_service = module.mi_ingest.client_id
    monitoring          = module.mi_monitoring.client_id
  }
}
